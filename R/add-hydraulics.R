#' Add plant hydraulic traits (Sanchez-Martinez et al.)
#'
#' Joins the drought-mortality trait block -- xylem embolism resistance, xylem
#' and leaf conductivity, sapwood-to-leaf allocation and drought exposure -- to
#' a [taxify()] result by accepted name.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) all, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `hyd_` columns: `p50_mpa`,
#'   `sapwood_conductivity`, `leaf_conductivity`, `huber_value_cm2_m2`,
#'   `min_water_potential_mpa`, `hydraulic_safety_margin_mpa`,
#'   `mean_annual_temp_c`.
#'
#' @details Source: Sanchez-Martinez et al. (2020), 2024 seed-plant species.
#'   CC BY 4.0. The widest P50 coverage in the bundled sources by an order of
#'   magnitude: 894 species against the 123 AusTraits and BROT carry between
#'   them.
#'
#'   This is a literature compilation and so are AusTraits and BROT, so where
#'   they overlap they often carry the same primary record: 63% of the P50
#'   values shared with AusTraits and 65% of the Ks values are equal to the last
#'   digit. Agreement between them is not independent corroboration. The overlap
#'   is small against what this adds -- 74 of its 894 P50 species appear in
#'   either incumbent.
#'
#'   `huber_value_cm2_m2` is square centimetres of sapwood per square metre of
#'   leaf, so it runs 1e4 above the dimensionless AusTraits column. The factor
#'   is measured rather than assumed: 79 of the 208 species the two share are
#'   equal to the last digit once converted. [add_trait()] applies it.
#'
#'   `mean_annual_temp_c` describes where the species grows, not what it
#'   tolerates; it feeds `climatic_temp_mean`, never `thermal_max`.
#'
#' @references
#' Sanchez-Martinez P, Martinez-Vilalta J, Dexter KG, Segovia RA, Mencuccini M
#' (2020) Adaptation and coordinated evolution of plant hydraulic traits.
#' Ecology Letters 23:1599-1610. \doi{10.1111/ele.13584}
#'
#' Data: \doi{10.6084/m9.figshare.12625418.v1}
#'
#' @examples
#' \dontrun{
#' taxify(c("Quercus ilex", "Abies alba")) |>
#'   add_hydraulics()
#' }
#'
#' @export
add_hydraulics <- function(x, cols = NULL, verbose = TRUE) {
  all_cols <- c("p50_mpa", "sapwood_conductivity", "leaf_conductivity",
                "huber_value_cm2_m2", "min_water_potential_mpa",
                "hydraulic_safety_margin_mpa", "mean_annual_temp_c")
  col_map <- stats::setNames(all_cols, paste0("hyd_", all_cols))
  enrich_simple(
    x,
    enrichment_name = "hydraulics",
    col_map         = col_map,
    source_label    = "Plant hydraulic traits (Sanchez-Martinez et al.)",
    cols            = cols,
    verbose         = verbose
  )
}
