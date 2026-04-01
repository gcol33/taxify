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
    c("cf", "aff", "s\\.l", "s\\.str", "sp", "spp",
      "subsp", "var", "f",
      "auct", "sensu", "non", "nec", "vel", "agg"),
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
#' @noRd
clean_one <- function(name) {
  if (is.na(name) || !nzchar(trimws(name))) {
    return(list(cleaned = NA_character_, is_hybrid = FALSE,
                qualifier = NA_character_))
  }

  s <- trimws(name)

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

  list(cleaned = s, is_hybrid = is_hybrid, qualifier = qualifier)
}


#' Clean a vector of taxonomic names
#'
#' Vectorized wrapper around `clean_one()`.
#'
#' @param x Character vector of taxonomic names.
#' @return A data.frame with columns: `original`, `cleaned`, `is_hybrid`,
#'   `qualifier`.
#' @noRd
clean_names <- function(x) {
  results <- lapply(x, clean_one)
  data.frame(
    original  = x,
    cleaned   = vapply(results, `[[`, character(1L), "cleaned"),
    is_hybrid = vapply(results, `[[`, logical(1L), "is_hybrid"),
    qualifier = vapply(results, `[[`, character(1L), "qualifier"),
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
