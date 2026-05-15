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
                qualifier = NA_character_, genus_only = FALSE,
                hybrid_name = NA_character_))
  }

  s <- trimws(name)

  # Normalize common mojibake: UTF-8 \u00d7 (U+00D7) misread as Latin-1/CP1252
  s <- gsub("\u00c3\u0097", "\u00d7", s, fixed = TRUE)
  s <- gsub("\u00c3\u2014", "\u00d7", s, fixed = TRUE)

  # Strip leading "Cf." / "CF." prefix (case-insensitive for this position)
  s <- sub("^[Cc][Ff]\\.?\\s+", "", s)

  # Detect hybrid markers (before stripping anything else)
  hybrid <- detect_hybrid(s)
  is_hybrid <- hybrid$is_hybrid
  s <- hybrid$stripped

  # Detect and strip qualifiers
  qualifier <- extract_qualifier(s)
  s <- strip_qualifier(s)

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

  # If qualifier was sp/spp/species and only the genus remains, flag it
  genus_only <- FALSE
  if (!is.na(qualifier) &&
      qualifier %in% c("sp", "spp", "species", "sect", "aggr") &&
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

  list(cleaned = s, is_hybrid = is_hybrid, qualifier = qualifier,
       genus_only = genus_only, hybrid_name = hybrid_name)
}


#' Clean a vector of taxonomic names (vectorized)
#'
#' All regex operations run on the full vector at once. Falls back to
#' per-element `detect_hybrid()` only for the small subset of names
#' that contain hybrid markers.
#'
#' @param x Character vector of taxonomic names.
#' @return A data.frame with columns: `original`, `cleaned`, `is_hybrid`,
#'   `qualifier`, `genus_only`, `hybrid_name`.
#' @noRd
clean_names <- function(x) {
  n <- length(x)
  s <- trimws(x)
  na_mask <- is.na(s) | !nzchar(s)

  # Normalize common mojibake
  s <- gsub("\u00c3\u0097", "\u00d7", s, fixed = TRUE)
  s <- gsub("\u00c3\u2014", "\u00d7", s, fixed = TRUE)

  # Strip leading "Cf." / "CF." prefix
  s <- sub("^[Cc][Ff]\\.?\\s+", "", s)

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

  # Extract qualifiers: grepl locates matches, then regexpr only on those strings
  # (saves one full-vector regex pass vs the original 3-pass approach)
  qualifier <- rep(NA_character_, n)
  has_qual  <- grepl(.qualifier_pattern, s, perl = TRUE)
  if (any(has_qual)) {
    m_sub <- regexpr(.qualifier_pattern, s[has_qual], perl = TRUE)
    qualifier[has_qual] <- regmatches(s[has_qual], m_sub)
  }

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
    qualifier %in% c("sp", "spp", "species", "sect", "aggr") &
    word_count == 1L

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
  genus_only[na_mask] <- FALSE
  hybrid_name[na_mask] <- NA_character_

  data.frame(
    original    = x,
    cleaned     = s,
    is_hybrid   = is_hybrid,
    qualifier   = qualifier,
    genus_only  = genus_only,
    hybrid_name = hybrid_name,
    stringsAsFactors = FALSE
  )
}


#' Extract the first qualifier from a name
#'
#' @param name Character string.
#' @return The qualifier string (e.g., "cf.") or NA_character_.
#' @noRd
extract_qualifier <- function(name) {
  m <- regexpr(.qualifier_pattern, name, perl = TRUE)
  if (m == -1L) return(NA_character_)
  regmatches(name, m)
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
#' variants of German-author species names (`b\u00f6hmi`/`boehmi`) fold to
#' the same key. Ligatures and special letters that don't decompose to a
#' single base letter expand similarly (ae-ligature -> ae, oe-ligature ->
#' oe, sharp-s -> ss, thorn -> th, l-stroke -> l).
#'
#' Operates on lowercased input \u2014 callers are responsible for
#' lowercasing upstream.
#'
#' @param x Character vector.
#' @return Character vector with accents/ligatures stripped.
#' @noRd
.strip_accents <- function(x) {
  # German umlauts first \u2014 digraph transliteration matches both the
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
#'    ae, sharp-s to ss, etc.) \u2014 applied to genus and epithet.
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
