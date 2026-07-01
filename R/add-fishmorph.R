#' Add freshwater fish morphological traits (FISHMORPH)
#'
#' Joins FISHMORPH morphological trait data to a [taxify()] result by
#' looking up `accepted_name`. This is the source-named door for FISHMORPH;
#' for the fish reference database FishBase see [add_fishbase()].
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{fish_max_body_length}{Maximum body length (cm).}
#'   \item{fish_body_elongation}{Body elongation (body length / body depth).}
#'   \item{fish_vertical_eye_position}{Vertical eye position (eye position /
#'     head depth).}
#'   \item{fish_relative_eye_size}{Relative eye size (eye diameter / head
#'     length).}
#'   \item{fish_oral_gape_position}{Oral gape position (mouth position:
#'     0 = inferior, 0.5 = terminal, 1 = superior).}
#'   \item{fish_relative_maxillary_length}{Relative maxillary length (maxillary
#'     length / head length).}
#'   \item{fish_body_lateral_shape}{Body lateral shape (body depth /
#'     caudal peduncle depth).}
#'   \item{fish_pectoral_fin_position}{Pectoral fin vertical position (fin
#'     insertion depth / body depth).}
#'   \item{fish_pectoral_fin_size}{Pectoral fin size (fin length / body
#'     length).}
#'   \item{fish_caudal_peduncle_throttling}{Caudal peduncle throttling (caudal
#'     peduncle depth / caudal fin depth).}
#' }
#'
#' @details
#' Source: FISHMORPH (Brosse et al. 2021, Figshare, CC BY 4.0).
#' Coverage: ~8.3k freshwater fish species.
#'
#' @references
#' Brosse S, Charpin N, Su G, Toussaint A, Herrera-R GA, Tedesco PA,
#' Villeg\if{html}{\out{&eacute;}}
#' \if{text}{e}\if{latex}{\enc{é}{e}}r S (2021) FISHMORPH: A global database
#' on morphological traits of freshwater fishes. Global Ecology and
#' Biogeography 30:2330-2336. \doi{10.1111/geb.13395}
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Salmo trutta", backend = "gbif") |>
#'   add_fishmorph()
#'
#' options(old)
#'
#' @export
add_fishmorph <- function(x, verbose = TRUE) {
  col_map <- c(
    fish_max_body_length          = "max_body_length",
    fish_body_elongation          = "body_elongation",
    fish_vertical_eye_position    = "vertical_eye_position",
    fish_relative_eye_size        = "relative_eye_size",
    fish_oral_gape_position       = "oral_gape_position",
    fish_relative_maxillary_length = "relative_maxillary_length",
    fish_body_lateral_shape       = "body_lateral_shape",
    fish_pectoral_fin_position    = "pectoral_fin_position",
    fish_pectoral_fin_size        = "pectoral_fin_size",
    fish_caudal_peduncle_throttling = "caudal_peduncle_throttling"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)),
    names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "fish_traits",
    col_map         = col_map,
    source_label    = "FISHMORPH",
    na_types        = na_types,
    verbose         = verbose
  )
}
