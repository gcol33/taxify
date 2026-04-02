# ---- Life form classification ----
#
# Maps (kingdom, class) pairs to a human-readable life-form category.
# Used by build_genus_register() to annotate each genus row.

# Class-level lookup: most specific, checked first.
# Each row: class -> life_form
.life_form_table <- data.frame(
  class = c(
    # Bryophytes
    "Bryopsida", "Sphagnopsida", "Andreaeopsida", "Oedipodiopsida",
    "Polytrichopsida", "Tetraphidopsida",
    # Liverworts
    "Marchantiopsida", "Jungermanniopsida",
    # Hornworts
    "Anthocerotopsida",
    # Lycophytes
    "Lycopodiopsida",
    # Ferns
    "Polypodiopsida", "Psilotopsida", "Equisetopsida", "Marattiopsida",
    # Angiosperms
    "Liliopsida", "Magnoliopsida",
    # Gymnosperms
    "Pinopsida", "Gnetopsida", "Cycadopsida", "Ginkgoopsida",
    # Lichens (fungal classes with obligate photobionts)
    "Lecanoromycetes", "Arthoniomycetes", "Lichinomycetes",
    "Candelariomycetes", "Coniocybomycetes"
  ),
  life_form = c(
    # Bryophytes
    "moss", "moss", "moss", "moss", "moss", "moss",
    # Liverworts
    "liverwort", "liverwort",
    # Hornworts
    "hornwort",
    # Lycophytes
    "lycophyte",
    # Ferns
    "fern", "fern", "fern", "fern",
    # Angiosperms
    "vascular", "vascular",
    # Gymnosperms
    "gymnosperm", "gymnosperm", "gymnosperm", "gymnosperm",
    # Lichens
    "lichen", "lichen", "lichen", "lichen", "lichen"
  ),
  stringsAsFactors = FALSE
)

# Note: "Graphidales" is an order, not a class — it belongs to Lecanoromycetes.
# It is already covered by that entry. No separate row needed.

# Kingdom-level fallback: when class is missing or unknown
.kingdom_life_form <- c(
  "Plantae"   = "vascular",   # generic fallback for plants without class
  "Fungi"     = "fungus",
  "Chromista" = "alga",
  "Protozoa"  = "protozoa",
  "Animalia"  = "animal",
  "Bacteria"  = "microbe",
  "Archaea"   = "microbe"
)


#' Assign life form from kingdom and class
#'
#' Vectorized lookup: checks class against `.life_form_table` first, then
#' falls back to `.kingdom_life_form` when class is missing or unknown.
#'
#' @param kingdom Character vector. Kingdom names.
#' @param class Character vector. Class names (may contain NAs).
#' @return Character vector of life-form labels, same length as `kingdom`.
#'   Returns `"unknown"` when neither class nor kingdom matches.
#' @noRd
assign_life_form <- function(kingdom, class) {
  n <- length(kingdom)
  if (length(class) != n) {
    stop("kingdom and class must have the same length", call. = FALSE)
  }

  # Build class -> life_form hash once
  class_lf <- stats::setNames(.life_form_table$life_form, .life_form_table$class)

  result <- character(n)

  # Step 1: class-level lookup (covers plants, some fungi)
  from_class <- class_lf[class]                # NA for unknown/missing class
  has_class_hit <- !is.na(from_class)
  result[has_class_hit] <- unname(from_class[has_class_hit])

  # Step 2: kingdom fallback for rows with no class hit
  needs_fallback <- !has_class_hit
  if (any(needs_fallback)) {
    from_kingdom <- .kingdom_life_form[kingdom[needs_fallback]]
    has_kingdom_hit <- !is.na(from_kingdom)
    idx <- which(needs_fallback)
    result[idx[has_kingdom_hit]] <- unname(from_kingdom[has_kingdom_hit])
    result[idx[!has_kingdom_hit]] <- "unknown"
  }

  result
}
