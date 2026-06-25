# ---- Name cleaning pipeline ----
#
# Runs on the user's input vector (small), not the backbone (large).
# The backbone is already clean \u2014 this prepares user names for matching.

# Qualifier patterns: cf., aff., s.l., s.str., sp., spp., subsp., var., f.,
# auct., sensu, non, nec, vel, agg.
# Match qualifier + optional trailing period, followed by space or end.
.qualifier_pattern <- paste0(
  "\\b(",
  paste(
    c("cf", "aff", "s\\.l", "s\\.str", "sp", "spp", "species",
      "subsp", "var", "f",
      "auct", "sensu", "non", "nec", "vel", "agg", "aggr", "sect"),
    collapse = "|"
  ),
  ")\\.?(?=\\s|$)"
)

# Parenthesized authorship: (L.), (Aiton) etc.
.author_parens_pattern <- "\\([A-Z][a-z\u00e9.&\\s]*\\)"

# Trailing authorship: "L.", "Sm.", "ex DC.", "(Aiton) Sm." etc.
# Capital letter followed by optional lowercase + period, possibly chained
# with ex/in/&.
.author_trailing_pattern <- paste0(
  "\\s+[A-Z][a-z\u00e9.]*\\.?",
  "(?:\\s+(?:ex|in|&)\\s+[A-Z][a-z\u00e9.]*\\.?)*",
  "$"
)

# ---- Qualifier canonicalization (single source of truth) ----
#
# Every spelling of a qualifier maps to one canonical display token, used in
# the `qualifier` output column. The same table drives `qualifier_position`
# (genus vs species) and the internal aggregate concept flag that steers
# preserve-mode matching and the enrichment join. Keep all qualifier knowledge
# here so callers never re-derive the marker zoo.

# Compressed key (tolower, dots/spaces removed) -> canonical token.
.qualifier_canon_map <- c(
  cf      = "cf.",   aff   = "aff.",
  agg     = "agg.",  aggr  = "agg.",
  sl      = "s.l.",  sstr  = "s.str.",
  sp      = "sp.",   spp   = "sp.",   species = "sp.",
  sect    = "sect.", subsp = "subsp.", var = "var.", f = "f.",
  auct    = "auct.", sensu = "sensu", non = "non", nec = "nec", vel = "vel"
)

# Canonical tokens denoting an aggregate / sensu-lato concept.
.aggregate_tokens <- c("agg.", "s.l.")

# Multi-word and spaced concept markers, stripped before single-token parsing
# (the single-token pass would otherwise mangle "sensu lato" into "sensu").
# Order: s.str. before s.l. so "s. str." is never partly eaten by the s.l. rule.
.concept_multiword <- list(
  list(pat = "\\s*\\b(sensu\\s+stricto|s\\.\\s*str\\.?)(?=\\s|$)", canon = "s.str."),
  list(pat = "\\s*\\b(sensu\\s+lato|s\\.\\s*l\\.?|coll\\.\\s*sp\\.?)(?=\\s|$)",
       canon = "s.l.")
)

#' Canonicalize a raw qualifier token to its display form
#'
#' @param raw Character. A matched qualifier token (e.g. `"aggr."`, `"Cf"`).
#' @return The canonical token (e.g. `"agg."`, `"cf."`), or `raw` unchanged
#'   when it is not in the map.
#' @noRd
canon_qualifier <- function(raw) {
  if (is.na(raw)) return(NA_character_)
  key <- gsub("[. ]", "", tolower(raw))
  out <- unname(.qualifier_canon_map[key])
  if (is.na(out)) raw else out
}

# Trailing aggregate / sensu-lato marker on a *canonical name* (e.g. an
# accepted_name or an enrichment key). Used to line up aggregate join keys
# regardless of how each source spells the marker.
.agg_name_suffix <-
  "[ -](aggr?\\.?|s\\.\\s*l\\.?|sensu\\s+lato|coll\\.?(\\s*sp(ecies)?\\.?)?)$"

#' Strip a trailing aggregate marker from a canonical name
#'
#' @param x Character vector of canonical names.
#' @return `x` with any trailing aggregate marker removed (bare binomial).
#'   `NA` in, `NA` out.
#' @noRd
strip_agg_marker <- function(x) {
  sub(.agg_name_suffix, "", x, perl = TRUE, ignore.case = TRUE)
}

#' Canonicalize a trailing aggregate marker to `" aggr."`
#'
#' Folds the spelling variants (`agg`, `agg.`, `-agg`, `s.l.`, `sensu lato`,
#' `coll. sp.`) a name may carry to one form, so aggregate join keys line up
#' across backbones and enrichment sources. Names without a marker pass through.
#'
#' @param x Character vector of canonical names.
#' @return `x` with any aggregate marker normalized to `" aggr."`.
#' @noRd
canon_agg_marker <- function(x) {
  hit <- grepl(.agg_name_suffix, x, perl = TRUE, ignore.case = TRUE)
  hit[is.na(hit)] <- FALSE
  x[hit] <- paste0(strip_agg_marker(x[hit]), " aggr.")
  x
}

# Taxon ranks (uppercased) that denote a species aggregate but may carry the
# binomial without any marker in the name (e.g. COL's "SPECIES AGGREGATE").
.aggregate_rank_pattern <-
  "^(SPECIES AGGREGATE|AGGR\\.?|COLL\\.?\\s*SP(ECIES)?\\.?)$"

#' Test whether a canonical name carries an aggregate marker
#'
#' `TRUE` for names ending in any aggregate marker spelling (`agg.`, `aggr.`,
#' `-agg`, `s.l.`, `sensu lato`, `coll. sp.`). Exported for the taxifydb build
#' pipeline so it can keep aggregate source rows out of cross-backbone name
#' expansion (which would otherwise leak an aggregate trait onto the binomial
#' species key).
#'
#' @param x Character vector of canonical names.
#' @return Logical vector; `FALSE` for `NA`.
#' @keywords internal
#' @export
is_aggregate_name <- function(x) {
  !is.na(x) & strip_agg_marker(x) != x
}


#' Normalize aggregate markers on canonical names (build-time)
#'
#' Folds every aggregate marker a backbone or enrichment source may use to one
#' canonical form, `"<binomial> aggr."`, so taxify's matching engine and
#' enrichment join recognize aggregates uniformly regardless of source spelling.
#' Two cases are handled:
#' \itemize{
#'   \item a name already carrying a marker (`agg.`, `aggr.`, `-agg`, `s.l.`,
#'     `sensu lato`, `coll. sp.`) is rewritten to `"<binomial> aggr."`;
#'   \item a name at an aggregate \emph{rank} (`taxon_rank` such as
#'     `"SPECIES AGGREGATE"`, `"AGGR."`, `"COLL. SP."`) that carries no marker
#'     gets `" aggr."` appended.
#' }
#' Exported for the taxifydb build pipeline so the build and runtime sides share
#' one definition.
#'
#' @param name Character vector of canonical names.
#' @param rank Optional character vector of taxon ranks, the same length as
#'   `name`. When supplied, aggregate-rank rows without a marker are suffixed.
#' @return `name` with aggregate markers normalized to `" aggr."`.
#' @keywords internal
#' @export
normalize_aggregate_name <- function(name, rank = NULL) {
  out <- canon_agg_marker(name)
  if (!is.null(rank)) {
    rk <- toupper(trimws(rank))
    is_agg_rank <- !is.na(rk) & grepl(.aggregate_rank_pattern, rk)
    has_marker  <- grepl(.agg_name_suffix, out, perl = TRUE, ignore.case = TRUE)
    has_marker[is.na(has_marker)] <- FALSE
    need <- is_agg_rank & !has_marker & !is.na(out) & nzchar(out)
    out[need] <- paste0(out[need], " aggr.")
  }
  out
}

#' Clean a single taxonomic name for matching
#'
#' Strips qualifiers, authorship, brackets, numbers, and normalizes whitespace.
#' Records hybrid status and qualifier information for downstream use.
#'
#' @param name Character string. A single taxonomic name.
#' @return A list with elements:
#'   - `cleaned`: the cleaned name ready for matching
#'   - `is_hybrid`: logical, whether a hybrid marker was detected
#'   - `qualifier`: character or NA, the qualifier found (e.g., "cf.")
#'   - `genus_only`: logical, whether the name reduces to a bare genus
#'     after stripping a sp/spp/species qualifier
#' @noRd
clean_one <- function(name) {
  if (is.na(name) || !nzchar(trimws(name))) {
    return(list(cleaned = NA_character_, is_hybrid = FALSE,
                qualifier = NA_character_, qualifier_position = NA_character_,
                is_aggregate = FALSE, genus_only = FALSE,
                hybrid_name = NA_character_, genus_abbrev = FALSE))
  }

  s <- trimws(name)

  # Normalize common mojibake: UTF-8 \u00d7 (U+00D7) misread as Latin-1/CP1252
  s <- gsub("\u00c3\u0097", "\u00d7", s, fixed = TRUE)
  s <- gsub("\u00c3\u2014", "\u00d7", s, fixed = TRUE)

  qualifier <- NA_character_
  qpos      <- NA_character_

  # Leading determination prefix (cf./aff.) -> genus-level qualifier.
  # \\b after the token guards real genera like "Affinis".
  lead_m <- regexpr("^(cf|aff)\\b\\.?\\s+", s, perl = TRUE, ignore.case = TRUE)
  if (lead_m != -1L) {
    lead_tok  <- sub("\\s+$", "", regmatches(s, lead_m))
    qualifier <- canon_qualifier(lead_tok)
    qpos      <- "genus"
    s <- sub("^(cf|aff)\\b\\.?\\s+", "", s, perl = TRUE, ignore.case = TRUE)
  }

  # Detect hybrid markers (before stripping anything else)
  hybrid <- detect_hybrid(s)
  is_hybrid <- hybrid$is_hybrid
  s <- hybrid$stripped

  # Multi-word / spaced concept markers (s.l., s.str., sensu lato/stricto)
  if (is.na(qualifier)) {
    for (mw in .concept_multiword) {
      if (regexpr(mw$pat, s, perl = TRUE, ignore.case = TRUE) != -1L) {
        qualifier <- mw$canon
        qpos      <- "species"
        s <- sub(mw$pat, "", s, perl = TRUE, ignore.case = TRUE)
        break
      }
    }
  }

  # Single-token qualifiers (cf., aff., var., agg., sp., ...)
  raw_q <- extract_qualifier(s)
  if (is.na(qualifier) && !is.na(raw_q)) {
    qualifier <- canon_qualifier(raw_q)
    qpos      <- "species"
  }
  s <- strip_qualifier(s)

  is_aggregate <- !is.na(qualifier) && qualifier %in% .aggregate_tokens

  # Strip parenthesized authorship
  s <- gsub(.author_parens_pattern, " ", s, perl = TRUE)

  # Strip trailing authorship
  s <- gsub(.author_trailing_pattern, "", s, perl = TRUE)

  # Strip remaining brackets and numbers
  s <- gsub("\\([^)]*\\)", " ", s)
  s <- gsub("[0-9]+", " ", s)

  # Collapse whitespace
  s <- gsub("\\s+", " ", trimws(s))

  # Lowercase everything except genus (first token)
  parts <- strsplit(s, " ", fixed = TRUE)[[1L]]
  if (length(parts) >= 2L) {
    s <- paste(c(parts[1L], tolower(parts[-1L])), collapse = " ")
  }

  # If qualifier reduced the name to a bare genus, flag it
  genus_only <- FALSE
  if (!is.na(qualifier) &&
      qualifier %in% c("sp.", "sect.", "agg.") &&
      length(strsplit(s, " ", fixed = TRUE)[[1L]]) == 1L) {
    genus_only <- TRUE
  }

  # For nothospecies hybrids, build "Genus \u00d7 epithet" form for backbone matching
  hybrid_name <- NA_character_
  if (is_hybrid && !is.na(hybrid$hybrid_type) &&
      hybrid$hybrid_type == "nothospecies") {
    parts_h <- strsplit(s, " ", fixed = TRUE)[[1L]]
    if (length(parts_h) >= 2L) {
      hybrid_name <- paste(parts_h[1L], "\u00d7", paste(parts_h[-1L], collapse = " "))
    }
  }

  # Flag an abbreviated genus (e.g. "Q. robur"): first token is a single letter
  # (optionally with a trailing period) and an epithet follows. Hybrids excluded.
  first_tok <- sub(" .*", "", s)
  genus_abbrev <- !is_hybrid && grepl(" ", s, fixed = TRUE) &&
    grepl("^[A-Za-z]\\.?$", first_tok)

  list(cleaned = s, is_hybrid = is_hybrid, qualifier = qualifier,
       qualifier_position = qpos, is_aggregate = is_aggregate,
       genus_only = genus_only, hybrid_name = hybrid_name,
       genus_abbrev = genus_abbrev)
}


#' Clean a vector of taxonomic names (vectorized)
#'
#' All regex operations run on the full vector at once. Falls back to
#' per-element `detect_hybrid()` only for the small subset of names
#' that contain hybrid markers.
#'
#' @param x Character vector of taxonomic names.
#' @return A data.frame with columns: `original`, `cleaned`, `is_hybrid`,
#'   `qualifier` (canonical token), `qualifier_position` (`"genus"`/`"species"`),
#'   `is_aggregate` (internal concept flag), `genus_only`, `hybrid_name`,
#'   `genus_abbrev`.
#' @noRd
clean_names <- function(x) {
  n <- length(x)
  s <- trimws(x)
  na_mask <- is.na(s) | !nzchar(s)

  # Normalize common mojibake
  s <- gsub("\u00c3\u0097", "\u00d7", s, fixed = TRUE)
  s <- gsub("\u00c3\u2014", "\u00d7", s, fixed = TRUE)

  # Strip a leading determination prefix (cf./aff.) -> genus-level qualifier,
  # recording the canonical token so it survives the strip. \\b guards real
  # genera like "Affinis".
  qualifier <- rep(NA_character_, n)
  qpos      <- rep(NA_character_, n)
  lead_pat  <- "^(cf|aff)\\b\\.?\\s+"
  lead_hit  <- grepl(lead_pat, s, perl = TRUE, ignore.case = TRUE)
  if (any(lead_hit)) {
    lm <- regexpr(lead_pat, s[lead_hit], perl = TRUE, ignore.case = TRUE)
    lead_tok <- sub("\\s+$", "", regmatches(s[lead_hit], lm))
    qualifier[lead_hit] <- vapply(lead_tok, canon_qualifier, character(1L),
                                  USE.NAMES = FALSE)
    qpos[lead_hit] <- "genus"
    s <- sub(lead_pat, "", s, perl = TRUE, ignore.case = TRUE)
  }

  # Detect hybrids \u2014 must be per-element due to tokenization logic
  is_hybrid <- logical(n)
  hybrid_type <- rep(NA_character_, n)
  has_marker <- grepl(.hybrid_sign, s, fixed = TRUE) |
    grepl("(^|\\s)[xX](\\s|$)", s)
  if (any(has_marker & !na_mask)) {
    marker_idx <- which(has_marker & !na_mask)
    for (j in marker_idx) {
      h <- detect_hybrid(s[j])
      is_hybrid[j] <- h$is_hybrid
      hybrid_type[j] <- h$hybrid_type
      s[j] <- h$stripped
    }
  }

  # Multi-word / spaced concept markers (s.l., s.str., sensu lato/stricto),
  # stripped first so the single-token pass never sees "sensu"/"lato" alone.
  for (mw in .concept_multiword) {
    mw_hit <- is.na(qualifier) & grepl(mw$pat, s, perl = TRUE, ignore.case = TRUE)
    if (any(mw_hit)) {
      qualifier[mw_hit] <- mw$canon
      qpos[mw_hit]      <- "species"
      s[mw_hit] <- sub(mw$pat, "", s[mw_hit], perl = TRUE, ignore.case = TRUE)
    }
  }

  # Single-token qualifiers: grepl locates matches, regexpr only on those strings.
  # Canonicalized to one display token per marker.
  has_qual <- is.na(qualifier) & grepl(.qualifier_pattern, s, perl = TRUE)
  if (any(has_qual)) {
    m_sub   <- regexpr(.qualifier_pattern, s[has_qual], perl = TRUE)
    raw_tok <- regmatches(s[has_qual], m_sub)
    qualifier[has_qual] <- vapply(raw_tok, canon_qualifier, character(1L),
                                  USE.NAMES = FALSE)
    qpos[has_qual] <- "species"
  }

  is_aggregate <- !is.na(qualifier) & qualifier %in% .aggregate_tokens

  # Strip qualifiers
  s <- gsub(.qualifier_pattern, " ", s, perl = TRUE)

  # Strip parenthesized authorship
  s <- gsub(.author_parens_pattern, " ", s, perl = TRUE)

  # Strip trailing authorship
  s <- gsub(.author_trailing_pattern, "", s, perl = TRUE)

  # Strip remaining brackets and numbers
  s <- gsub("\\([^)]*\\)", " ", s)
  s <- gsub("[0-9]+", " ", s)

  # Collapse whitespace
  s <- gsub("\\s+", " ", trimws(s))

  # Lowercase everything except genus (first token)
  genus_part <- sub(" .*", "", s)
  rest_part <- sub("^\\S+\\s*", "", s)
  has_rest <- nzchar(rest_part)
  s <- ifelse(has_rest, paste(genus_part, tolower(rest_part)), s)

  # Flag genus_only (count spaces instead of strsplit)
  word_count <- nchar(gsub("[^ ]", "", s)) + 1L
  word_count[na_mask] <- 0L
  genus_only <- !is.na(qualifier) &
    qualifier %in% c("sp.", "sect.", "agg.") &
    word_count == 1L

  # Flag abbreviated genus (e.g. "Q. robur"): single-letter first token (with an
  # optional trailing period) and an epithet following. Hybrids excluded.
  abbrev_first <- sub(" .*", "", s)
  genus_abbrev <- !is_hybrid & word_count >= 2L &
    grepl("^[A-Za-z]\\.?$", abbrev_first)

  # Build hybrid_name for nothospecies
  hybrid_name <- rep(NA_character_, n)
  notho_mask <- is_hybrid & !is.na(hybrid_type) &
    hybrid_type == "nothospecies" & word_count >= 2L
  if (any(notho_mask)) {
    parts_list <- strsplit(s[notho_mask], " ", fixed = TRUE)
    hybrid_name[notho_mask] <- vapply(parts_list, function(p) {
      paste(p[1L], "\u00d7", paste(p[-1L], collapse = " "))
    }, character(1L))
  }

  # NA out the ones that were originally NA/empty
  s[na_mask] <- NA_character_
  is_hybrid[na_mask] <- FALSE
  qualifier[na_mask] <- NA_character_
  qpos[na_mask] <- NA_character_
  is_aggregate[na_mask] <- FALSE
  genus_only[na_mask] <- FALSE
  hybrid_name[na_mask] <- NA_character_
  genus_abbrev[na_mask] <- FALSE

  data.frame(
    original           = x,
    cleaned            = s,
    is_hybrid          = is_hybrid,
    qualifier          = qualifier,
    qualifier_position = qpos,
    is_aggregate       = is_aggregate,
    genus_only         = genus_only,
    hybrid_name        = hybrid_name,
    genus_abbrev       = genus_abbrev,
    stringsAsFactors   = FALSE
  )
}


#' Find the first qualifier in a name and its character position
#'
#' Handles two forms: an inline qualifier ("Pinus cf. sylvestris", caught by
#' `.qualifier_pattern`) and a leading genus-level "Cf." prefix
#' ("Cf. Pinus sylvestris"). The leading prefix is matched case-insensitively
#' and normalized to "cf.", mirroring the prefix strip in `clean_one()` /
#' `clean_names()` so the qualifier is recorded wherever the prefix is removed.
#'
#' @param name Character string (length 1).
#' @return A list with `qualifier` (character or NA) and `position` (integer
#'   character index, or NA).
#' @noRd
qualifier_match <- function(name) {
  if (length(name) != 1L || is.na(name)) {
    return(list(qualifier = NA_character_, position = NA_integer_))
  }
  # Leading genus-level "Cf." prefix, normalized to "cf."
  if (grepl("^[Cc][Ff]\\.?(?=\\s)", name, perl = TRUE)) {
    return(list(qualifier = "cf.", position = 1L))
  }
  m <- regexpr(.qualifier_pattern, name, perl = TRUE)
  if (m == -1L) return(list(qualifier = NA_character_, position = NA_integer_))
  list(qualifier = regmatches(name, m), position = as.integer(m))
}


#' Extract the first qualifier from a name
#'
#' @param name Character string.
#' @return The qualifier string (e.g., "cf.") or NA_character_.
#' @noRd
extract_qualifier <- function(name) {
  qualifier_match(name)$qualifier
}


#' Strip qualifiers from a name
#'
#' @param name Character string.
#' @return The name with qualifiers removed.
#' @noRd
strip_qualifier <- function(name) {
  gsub(.qualifier_pattern, " ", name, perl = TRUE)
}


# Accent / ligature character classes. Lowercase only \u2014 callers lowercase
# upstream. German umlauts (\u00e4/\u00f6/\u00fc) are handled separately via
# digraph transliteration (ae/oe/ue), so they're omitted from the bare-letter
# classes. Sources stored as \uXXXX escapes to keep the source ASCII.
# a-class (excl. \u00e4): a-grave, a-acute, a-circumflex, a-tilde, a-ring, a-macron
.accent_a <- "[\u00e0\u00e1\u00e2\u00e3\u00e5\u0101]"
# e-class: e-grave, e-acute, e-circumflex, e-diaeresis, e-macron
.accent_e <- "[\u00e8\u00e9\u00ea\u00eb\u0113]"
# i-class: i-grave, i-acute, i-circumflex, i-diaeresis, i-macron
.accent_i <- "[\u00ec\u00ed\u00ee\u00ef\u012b]"
# o-class (excl. \u00f6): o-grave/acute/circ/tilde, o-slash, o-macron
.accent_o <- "[\u00f2\u00f3\u00f4\u00f5\u00f8\u014d]"
# u-class (excl. \u00fc): u-grave, u-acute, u-circumflex, u-macron
.accent_u <- "[\u00f9\u00fa\u00fb\u016b]"
# y-class: y-acute, y-diaeresis
.accent_y <- "[\u00fd\u00ff]"
# d-class: eth (\u00f0), d-stroke (\u0111)
.accent_d <- "[\u00f0\u0111]"

#' Strip Latin-1 diacritics and common ligatures
#'
#' Maps accented letters to a canonical form for normalization keys. Most
#' diacritics collapse to the bare letter (e-acute -> e, n-tilde -> n).
#' German umlauts transliterate to digraphs (a-diaeresis -> ae, o-diaeresis
#' -> oe, u-diaeresis -> ue) so the umlauted and the digraph-spelled
#' variants of German-author species names (e.g. `boehmi`) fold to the same
#' key. Ligatures and special letters that don't decompose to a single base
#' letter expand similarly (ae-ligature -> ae, oe-ligature -> oe, sharp-s ->
#' ss, thorn -> th, l-stroke -> l).
#'
#' Operates on lowercased input; callers are responsible for lowercasing
#' upstream.
#'
#' @param x Character vector.
#' @return Character vector with accents/ligatures stripped.
#' @noRd
.strip_accents <- function(x) {
  # German umlauts first; digraph transliteration matches both the
  # umlauted and the de-umlauted spellings of German-author species names.
  x <- gsub("\u00e4", "ae", x, fixed = TRUE)  # a-diaeresis
  x <- gsub("\u00f6", "oe", x, fixed = TRUE)  # o-diaeresis
  x <- gsub("\u00fc", "ue", x, fixed = TRUE)  # u-diaeresis

  # Ligatures and special letters expanding to digraphs
  x <- gsub("\u00e6", "ae", x, fixed = TRUE)  # ae-ligature
  x <- gsub("\u0153", "oe", x, fixed = TRUE)  # oe-ligature
  x <- gsub("\u00df", "ss", x, fixed = TRUE)  # sharp-s
  x <- gsub("\u00fe", "th", x, fixed = TRUE)  # thorn

  # Bare-letter diacritics
  x <- gsub(.accent_a, "a", x, perl = TRUE)
  x <- gsub("\u00e7", "c", x, fixed = TRUE)   # c-cedilla
  x <- gsub(.accent_e, "e", x, perl = TRUE)
  x <- gsub(.accent_i, "i", x, perl = TRUE)
  x <- gsub("\u00f1", "n", x, fixed = TRUE)   # n-tilde
  x <- gsub(.accent_o, "o", x, perl = TRUE)
  x <- gsub(.accent_u, "u", x, perl = TRUE)
  x <- gsub(.accent_y, "y", x, perl = TRUE)
  x <- gsub(.accent_d, "d", x, perl = TRUE)
  x <- gsub("\u0142", "l", x, fixed = TRUE)   # l-stroke
  x
}


#' Vectorized Latin orthographic normalization
#'
#' Reduces common Latin spelling alternations to a canonical form so that
#' e.g. `hirtaeformis` and `hirtiformis` produce the same normalized key.
#' Applied identically to both query names and backbone names so the keys
#' line up on either side of the join.
#'
#' Pipeline:
#' 1. Lowercase.
#' 2. Strip Latin-1 diacritics and ligatures (e-acute to e, ae-ligature to
#'    ae, sharp-s to ss, etc.), applied to genus and epithet.
#' 3. Orthographic alternation on the epithet only: `ae`/`oe` -> `i`,
#'    trailing `ii` -> `i`, `y` -> `i`, `ph` -> `f`, `rh` -> `r`, `th` -> `t`.
#'
#' Step 2 runs before step 3, so ae-ligature -> `ae` -> `i` and oe-ligature
#' -> `oe` -> `i` fold into the same key as the de-ligatured forms.
#'
#' @param names Character vector of cleaned taxonomic names (genus + epithet).
#' @return Character vector of normalized forms.
#' @keywords internal
#' @export
normalize_epithets <- function(names) {
  genus <- sub(" .*", "", names)
  rest  <- sub("^\\S+\\s*", "", names)
  has_rest <- nzchar(rest) & !is.na(rest)

  genus <- .strip_accents(tolower(genus))
  rest  <- .strip_accents(tolower(rest))

  rest <- gsub("ae|oe", "i", rest)
  rest <- gsub("ii\\b", "i", rest, perl = TRUE)
  rest <- chartr("y", "i", rest)
  rest <- gsub("ph", "f", rest, fixed = TRUE)
  rest <- gsub("rh", "r", rest, fixed = TRUE)
  rest <- gsub("th", "t", rest, fixed = TRUE)

  result <- ifelse(has_rest, paste(genus, rest), genus)
  result[is.na(names)] <- NA_character_
  result
}
