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


#' Clean a vector of taxonomic names
#'
#' Vectorized wrapper around `clean_one()`.
#'
#' @param x Character vector of taxonomic names.
#' @return A data.frame with columns: `original`, `cleaned`, `is_hybrid`,
#'   `qualifier`, `genus_only`.
#' @noRd
clean_names <- function(x) {
  results <- lapply(x, clean_one)
  data.frame(
    original    = x,
    cleaned     = vapply(results, `[[`, character(1L), "cleaned"),
    is_hybrid   = vapply(results, `[[`, logical(1L), "is_hybrid"),
    qualifier   = vapply(results, `[[`, character(1L), "qualifier"),
    genus_only  = vapply(results, `[[`, logical(1L), "genus_only"),
    hybrid_name = vapply(results, `[[`, character(1L), "hybrid_name"),
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


#' Normalize Latin orthographic variants in taxonomic epithets
#'
#' Reduces common Latin spelling alternations to a canonical form so that
#' e.g. `hirtaeformis` and `hirtiformis` produce the same normalized key.
#' Applied to the epithet portion only (everything after the genus).
#'
#' Handled alternations:
#' - `ae` -> `i` (e.g., hirtaeformis/hirtiformis, caeruleus/ciruleus)
#' - `oe` -> `i` (e.g., foetidus/fitidus)
#' - `ii` -> `i` at word end (e.g., wallichii/wallichi)
#' - `y` -> `i` (e.g., sylvestris/silvestris)
#' - `ph` -> `f` (e.g., phragmites)
#' - `rh` -> `r` (e.g., rhododendron)
#' - `th` -> `t` (e.g., thapsia)
#'
#' @param name Character string. A cleaned taxonomic name (genus + epithet).
#' @return The normalized form.
#' @noRd
normalize_epithet <- function(name) {
  if (is.na(name) || !nzchar(name)) return(name)
  parts <- strsplit(name, " ", fixed = TRUE)[[1L]]
  if (length(parts) < 2L) return(tolower(name))
  genus <- tolower(parts[1L])
  epithet <- tolower(paste(parts[-1L], collapse = " "))
  epithet <- gsub("ae", "i", epithet, fixed = TRUE)
  epithet <- gsub("oe", "i", epithet, fixed = TRUE)
  epithet <- gsub("ii\\b", "i", epithet, perl = TRUE)
  epithet <- gsub("y", "i", epithet, fixed = TRUE)
  epithet <- gsub("ph", "f", epithet, fixed = TRUE)
  epithet <- gsub("rh", "r", epithet, fixed = TRUE)
  epithet <- gsub("th", "t", epithet, fixed = TRUE)
  paste(genus, epithet)
}


#' Vectorized Latin orthographic normalization
#'
#' @param names Character vector.
#' @return Character vector of normalized forms.
#' @noRd
normalize_epithets <- function(names) {
  vapply(names, normalize_epithet, character(1L), USE.NAMES = FALSE)
}
