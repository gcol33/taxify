#' Add plant traits from Baseflor (Catminat / Julve)
#'
#' Joins Baseflor (Julve, Programme Catminat) plant traits to a [taxify()]
#' result by looking up `accepted_name`. Baseflor covers the vascular flora of
#' France and neighbouring regions, providing flowering phenology, pollination
#' and breeding biology, dispersal mode, and floral and fruit morphology.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{flower_begin_month}{First month of flowering (1-12).}
#'   \item{flower_end_month}{Last month of flowering (1-12). A value smaller
#'     than \code{flower_begin_month} denotes a flowering period that wraps
#'     across the new year (e.g. begin 10, end 6).}
#'   \item{pollination_vector}{Pollination vector(s): insect, wind, water,
#'     self, apogamy. Comma-separated when more than one applies.}
#'   \item{dispersal_mode}{Diaspore dispersal mode(s): anemochory, barochory,
#'     epizoochory, endozoochory, myrmecochory, hydrochory, autochory,
#'     dyszoochory. Comma-separated when more than one applies.}
#'   \item{breeding_system}{Sexual system: hermaphroditic, monoecious,
#'     dioecious, gynodioecious, androdioecious, gynomonoecious, polygamous.}
#'   \item{flower_colour}{Flower colour(s): white, yellow, pink, green, blue,
#'     brown, black. Comma-separated when more than one applies.}
#'   \item{fruit_type}{Fruit type: achene, capsule, caryopsis, drupe, legume,
#'     silique, berry, follicle, cone, samara, pyxid.}
#'   \item{woody_growth_form}{Woody growth form for woody taxa: tree, small
#'     tree, large tree, shrub, bush, subshrub, liana, parasite. NA for
#'     non-woody (herbaceous) taxa.}
#'   \item{continentality}{Ellenberg-style continentality indicator value
#'     (1-9), the axis absent from EIVE.}
#'   \item{salinity}{Ellenberg-style salinity indicator value (0-9), the axis
#'     absent from EIVE.}
#' }
#'
#' @details
#' Source: Baseflor, Programme Catminat (Julve 1998 ff.). Coverage: ~7,000
#' vascular plant taxa of France and neighbouring regions. Data are released
#' under ODbL 1.0 / CC BY-SA 2.0.
#'
#' For ecological indicator values on the light, temperature, moisture,
#' reaction, and nutrient axes, see [add_eive()] (European calibration). For
#' Raunkiaer life form and seed, leaf, and clonality traits of the Northwest
#' European flora, see [add_leda()].
#'
#' @references
#' Julve, Ph. (1998 ff.) baseflor. Index botanique, ecologique et chorologique
#' de la Flore de France. Programme Catminat.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Bellis perennis") |>
#'   add_baseflor()
#'
#' options(old)
#'
#' @export
add_baseflor <- function(x, verbose = TRUE) {
  col_map <- c(
    flower_begin_month = "flower_begin_month",
    flower_end_month   = "flower_end_month",
    pollination_vector = "pollination_vector",
    dispersal_mode     = "dispersal_mode",
    breeding_system    = "breeding_system",
    flower_colour      = "flower_colour",
    fruit_type         = "fruit_type",
    woody_growth_form  = "woody_growth_form",
    continentality     = "continentality",
    salinity           = "salinity"
  )
  na_types <- list(
    flower_begin_month = NA_integer_,
    flower_end_month   = NA_integer_,
    pollination_vector = NA_character_,
    dispersal_mode     = NA_character_,
    breeding_system    = NA_character_,
    flower_colour      = NA_character_,
    fruit_type         = NA_character_,
    woody_growth_form  = NA_character_,
    continentality     = NA_integer_,
    salinity           = NA_integer_
  )
  enrich_simple(
    x,
    enrichment_name = "baseflor",
    col_map         = col_map,
    source_label    = "Baseflor (Catminat / Julve)",
    na_types        = na_types,
    verbose         = verbose
  )
}
