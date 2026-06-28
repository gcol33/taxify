#' Add spider traits (World Spider Trait Database)
#'
#' Joins species-level spider morphometric and ecological traits to a [taxify()]
#' result by looking up `accepted_name`. Values are aggregated from the World
#' Spider Trait Database (numeric traits by median, categorical traits by mode);
#' access-restricted source records are excluded.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{spider_body_length_mm}{Body length (mm).}
#'   \item{spider_prosoma_length_mm}{Cephalothorax (prosoma) length (mm).}
#'   \item{spider_prosoma_width_mm}{Cephalothorax (prosoma) width (mm).}
#'   \item{spider_abdomen_length_mm}{Abdomen (opisthosoma) length (mm).}
#'   \item{spider_leg1_length_mm}{Leg I length (mm).}
#'   \item{spider_ballooning}{Ballooning (aerial dispersal): yes/no.}
#'   \item{spider_web_building}{Web building: yes/no.}
#'   \item{spider_hunting_guild}{Hunting guild.}
#'   \item{spider_web_type}{Web type.}
#'   \item{spider_circadian_activity}{Circadian activity (diurnal/nocturnal).}
#'   \item{spider_stratum}{Vertical stratum (habitat layer).}
#' }
#'
#' @details
#' Source: World Spider Trait Database (Pekar et al. 2021, Database, CC BY 4.0).
#' Coverage: ~7.3k spider species. Morphometry is sexually dimorphic in spiders;
#' the value here is the across-record median and is not split by sex.
#'
#' @references
#' Pekar S et al. (2021) The World Spider Trait database: a centralized global
#' open repository for curated data on spider traits. Database 2021:baab064.
#' \doi{10.1093/database/baab064}
#'
#' @examples
#' \donttest{
#' taxify("Araneus diadematus", backend = "gbif") |>
#'   add_spider_traits()
#' }
#'
#' @export
add_spider_traits <- function(x, verbose = TRUE) {
  col_map <- c(
    spider_body_length_mm     = "body_length_mm",
    spider_prosoma_length_mm  = "prosoma_length_mm",
    spider_prosoma_width_mm   = "prosoma_width_mm",
    spider_abdomen_length_mm  = "abdomen_length_mm",
    spider_leg1_length_mm     = "leg1_length_mm",
    spider_ballooning         = "ballooning",
    spider_web_building       = "web_building",
    spider_hunting_guild      = "hunting_guild",
    spider_web_type           = "web_type",
    spider_circadian_activity = "circadian_activity",
    spider_stratum            = "stratum"
  )
  na_types <- stats::setNames(
    rep(list(NA_character_), length(col_map)), names(col_map)
  )
  na_types[c("spider_body_length_mm", "spider_prosoma_length_mm",
             "spider_prosoma_width_mm", "spider_abdomen_length_mm",
             "spider_leg1_length_mm")] <- list(NA_real_)
  enrich_simple(
    x,
    enrichment_name = "spider_traits",
    col_map         = col_map,
    source_label    = "World Spider Trait Database",
    na_types        = na_types,
    verbose         = verbose
  )
}
