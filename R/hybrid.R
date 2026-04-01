# ---- Hybrid detection and formula parsing ----

# Unicode multiplication sign
.hybrid_sign <- "\u00d7"

# Pattern for the multiplication sign or standalone "x" as hybrid marker.
# Standalone "x" must be bounded by spaces (not part of a word like "Saxifraga").
# We also accept "X" in the same positions.
.hybrid_marker <- paste0("(?:", .hybrid_sign, "|(?<=\\s)[xX](?=\\s)|^[xX](?=\\s))")


#' Detect hybrid markers in a taxonomic name
#'
#' Identifies whether a name contains hybrid notation and classifies the type.
#' Returns a stripped version of the name (hybrid marker removed) for matching.
#'
#' @param name Character string. A single taxonomic name (already trimmed).
#' @return A list with elements:
#'   - `is_hybrid`: logical
#'   - `hybrid_type`: character or NA ("nothogenus", "nothospecies", "formula")
#'   - `stripped`: the name with hybrid markers removed, ready for cleaning
#' @noRd
detect_hybrid <- function(name) {
  no_hybrid <- list(is_hybrid = FALSE, hybrid_type = NA_character_,
                    stripped = name)

  if (is.na(name) || !nzchar(name)) return(no_hybrid)

  # Normalize: replace Unicode multiplication sign with " x " for uniform parsing
  s <- gsub(.hybrid_sign, " x ", name)
  s <- gsub("\\s+", " ", trimws(s))

  tokens <- strsplit(s, " ", fixed = TRUE)[[1L]]

  # Case 1: Leading "x" or "X" → nothogenus (e.g., "x Festulolium")
  if (length(tokens) >= 2L && tolower(tokens[1L]) == "x" &&
      grepl("^[A-Z]", tokens[2L])) {
    stripped <- paste(tokens[-1L], collapse = " ")
    return(list(is_hybrid = TRUE, hybrid_type = "nothogenus",
                stripped = stripped))
  }

  # Case 2: "x" between genus and epithet → nothospecies
  # e.g., "Quercus x hispanica"
  if (length(tokens) >= 3L && grepl("^[A-Z]", tokens[1L]) &&
      tolower(tokens[2L]) == "x" && grepl("^[a-z]", tokens[3L])) {
    # Check if there's more after — could be a formula
    # "Quercus x hispanica" = nothospecies (3 tokens)
    # vs. a formula would have another "x" later
    x_positions <- which(tolower(tokens) == "x")
    if (length(x_positions) == 1L) {
      stripped <- paste(c(tokens[1L], tokens[3L:length(tokens)]), collapse = " ")
      return(list(is_hybrid = TRUE, hybrid_type = "nothospecies",
                  stripped = stripped))
    }
  }

  # Case 3: Hybrid formula — "x" between two binomials (or abbreviated)
  # e.g., "Quercus pyrenaica x Q. petraea"
  # e.g., "Quercus pyrenaica x Quercus petraea"
  x_positions <- which(tolower(tokens) == "x")
  for (xp in x_positions) {
    # Must have content before and after
    if (xp > 1L && xp < length(tokens)) {
      before <- tokens[1L:(xp - 1L)]
      after <- tokens[(xp + 1L):length(tokens)]
      # Before should look like a binomial (genus + epithet or just genus)
      # After should start with a capital letter (genus) or abbreviated genus
      if (length(before) >= 2L && grepl("^[A-Z]", before[1L]) &&
          (grepl("^[A-Z]", after[1L]) || grepl("^[A-Z]\\.", after[1L]))) {
        # This is a formula hybrid
        stripped <- paste(before, collapse = " ")
        return(list(is_hybrid = TRUE, hybrid_type = "formula",
                    stripped = stripped))
      }
    }
  }

  no_hybrid
}


#' Parse a hybrid formula into parent names
#'
#' For formula hybrids like "Quercus pyrenaica x Q. petraea", extracts both
#' parent names with abbreviated genera expanded.
#'
#' @param name Character string. A single taxonomic name.
#' @return A list with elements:
#'   - `parent_1`: character or NA
#'   - `parent_2`: character or NA
#'   - `hybrid_type`: character or NA
#' @noRd
parse_hybrid_formula <- function(name) {
  no_formula <- list(parent_1 = NA_character_, parent_2 = NA_character_,
                     hybrid_type = NA_character_)

  if (is.na(name) || !nzchar(name)) return(no_formula)

  # Normalize hybrid markers
  s <- gsub(.hybrid_sign, " x ", name)
  s <- gsub("\\s+", " ", trimws(s))

  tokens <- strsplit(s, " ", fixed = TRUE)[[1L]]

  # Detect hybrid type first
  hybrid <- detect_hybrid(name)
  if (!hybrid$is_hybrid) return(no_formula)

  if (hybrid$hybrid_type == "nothogenus") {
    return(list(parent_1 = NA_character_, parent_2 = NA_character_,
                hybrid_type = "nothogenus"))
  }

  if (hybrid$hybrid_type == "nothospecies") {
    return(list(parent_1 = NA_character_, parent_2 = NA_character_,
                hybrid_type = "nothospecies"))
  }

  if (hybrid$hybrid_type == "formula") {
    # Find the "x" position
    x_positions <- which(tolower(tokens) == "x")
    for (xp in x_positions) {
      if (xp > 1L && xp < length(tokens)) {
        before <- tokens[1L:(xp - 1L)]
        after <- tokens[(xp + 1L):length(tokens)]

        if (length(before) >= 2L) {
          parent_1 <- paste(before, collapse = " ")
          genus <- before[1L]

          # Expand abbreviated genus in parent 2
          # e.g., "Q. petraea" -> "Quercus petraea"
          if (grepl("^[A-Z]\\.$", after[1L])) {
            after[1L] <- genus
          }
          parent_2 <- paste(after, collapse = " ")

          return(list(parent_1 = parent_1, parent_2 = parent_2,
                      hybrid_type = "formula"))
        }
      }
    }
  }

  no_formula
}
