#' Add host-virus association breadth (VIRION)
#'
#' Joins per-host counts of recorded virus associations to a [taxify()] result.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) all, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `virion_` columns: `virus_richness`,
#'   `virus_family_count`, `virus_record_count`, `host_class`.
#'
#' @details Source: Carlson et al. (2022), 4223 vertebrate hosts and 9833
#'   viruses. ODbL-1.0. As with [add_globi()] and [add_invacost()], only the
#'   derived per-host counts are redistributed, not the association records.
#'
#'   These counts measure how much a host has been looked at as much as what
#'   infects it. *Homo sapiens* leads with 936 distinct viruses across 633,053
#'   records, and the ordering below it tracks livestock and laboratory species.
#'   `virus_record_count` travels alongside so the effort behind a richness is
#'   visible; treat richness as association breadth as recorded, not as a
#'   biological property of the host.
#'
#' @references
#' Carlson CJ, Gibb RJ, Albery GF, et al. (2022) The Global Virome in One
#' Network (VIRION): an atlas of vertebrate-virus associations. mBio
#' 13:e0298521. \doi{10.1128/mbio.02985-21}
#'
#' @examples
#' \dontrun{
#' taxify(c("Sus scrofa", "Myotis lucifugus")) |>
#'   add_virion()
#' }
#'
#' @export
add_virion <- function(x, cols = NULL, verbose = TRUE) {
  all_cols <- c("virus_richness", "virus_family_count", "virus_record_count",
                "host_class")
  col_map <- stats::setNames(all_cols, paste0("virion_", all_cols))
  enrich_simple(
    x,
    enrichment_name = "virion",
    col_map         = col_map,
    source_label    = "VIRION host-virus associations (Carlson et al.)",
    cols            = cols,
    verbose         = verbose
  )
}
