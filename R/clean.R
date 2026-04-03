# ---- Name cleaning pipeline ----
#
# Runs on the user's input vector (small), not the backbone (large).
# The backbone is already clean — this prepares user names for matching.

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

  # Normalize common mojibake: UTF-8 × (U+00D7) misread as Latin-1/CP1252
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

  # For nothospecies hybrids, build "Genus × epithet" form for backbone matching
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

  # Detect hybrids — must be per-element due to tokenization logic
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


#' Vectorized Latin orthographic normalization
#'
#' Reduces common Latin spelling alternations to a canonical form so that
#' e.g. `hirtaeformis` and `hirtiformis` produce the same normalized key.
#' Applied to the epithet portion only (everything after the genus).
#'
#' Handled alternations:
#' - `ae` -> `i`, `oe` -> `i`, `ii` -> `i` at word end
#' - `y` -> `i`, `ph` -> `f`, `rh` -> `r`, `th` -> `t`
#'
#' @param names Character vector of cleaned taxonomic names (genus + epithet).
#' @return Character vector of normalized forms.
#' @noRd
normalize_epithets <- function(names) {
  genus <- sub(" .*", "", names)
  rest  <- sub("^\\S+\\s*", "", names)
  has_rest <- nzchar(rest) & !is.na(rest)

  # Normalize epithet portion only — batch digraph replacements
  rest <- tolower(rest)
  rest <- gsub("ae|oe", "i", rest)
  rest <- gsub("ii\\b", "i", rest, perl = TRUE)
  rest <- chartr("y", "i", rest)
  rest <- gsub("ph", "f", rest, fixed = TRUE)
  rest <- gsub("rh", "r", rest, fixed = TRUE)
  rest <- gsub("th", "t", rest, fixed = TRUE)

  result <- ifelse(has_rest, paste(tolower(genus), rest), tolower(names))
  result[is.na(names)] <- NA_character_
  result
}
