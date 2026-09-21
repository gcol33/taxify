# .enrich_group_fill(prefer =): where parts of one taxon disagree on a group,
# the preferred value wins regardless of row order; .refused_report(): a refused
# recovery alternative is reported only where it would have filled an empty
# group.

group_x <- function() {
  data.frame(input_name = c("Polygonum aviculare", "Other"),
             accepted_name = c("Polygonum aviculare subsp. aviculare", "Other"),
             native_status_CLS = NA_character_,
             native_status_AGE = NA_character_,
             stringsAsFactors = FALSE)
}

part_rows <- function(order = 1:3) {
  nm <- "Polygonum aviculare subsp. aviculare"
  data.frame(
    lookup_name = nm,
    .source_key = c(nm, "Polygonum caballeroi", "Polygonum zeta")[order],
    tdwg_code = c("CLS", "CLS", "AGE")[order],
    native_status = c("introduced", "native", "introduced")[order],
    stringsAsFactors = FALSE)
}

wcvp_prefer <- list(col = "native_status",
                    order = c("native", "introduced", "extinct"))

test_that("native wins over introduced whatever the row order", {
  for (o in list(1:3, c(2, 1, 3), c(3, 2, 1))) {
    out <- .enrich_group_fill(group_x(), part_rows(o), group_x()$accepted_name,
                              c("CLS", "AGE"),
                              c(native_status = "native_status"), "tdwg_code",
                              wcvp_prefer)
    expect_identical(out$native_status_CLS, c("native", NA))
    expect_identical(out$native_status_AGE, c("introduced", NA))
  }
})

test_that("without prefer the first row wins", {
  out <- .enrich_group_fill(group_x(), part_rows(), group_x()$accepted_name,
                            c("CLS", "AGE"), c(native_status = "native_status"),
                            "tdwg_code")
  expect_identical(out$native_status_CLS, c("introduced", NA))
})

test_that("between equal values the name's own row wins, then parts by name", {
  nm <- "Polygonum aviculare subsp. aviculare"
  rows <- data.frame(lookup_name = nm,
                     .source_key = c("Polygonum zeta", "Polygonum beta", nm),
                     tdwg_code = "CLS", native_status = "native",
                     location_doubtful = c("z", "b", "own"),
                     stringsAsFactors = FALSE)
  x <- group_x(); x$location_doubtful_CLS <- NA_character_
  x$location_doubtful_AGE <- NA_character_
  vc <- c(native_status = "native_status", location_doubtful = "location_doubtful")
  out <- .enrich_group_fill(x, rows, x$accepted_name, c("CLS", "AGE"), vc,
                            "tdwg_code", wcvp_prefer)
  expect_identical(out$location_doubtful_CLS[1], "own")
  out <- .enrich_group_fill(x, rows[1:2, ], x$accepted_name, c("CLS", "AGE"),
                            vc, "tdwg_code", wcvp_prefer)
  expect_identical(out$location_doubtful_CLS[1], "b")
})

test_that("a refused alternative is reported only where it fills an empty group", {
  x <- group_x()
  x$native_status_AGE[1] <- "native"
  rec <- list(
    refused = data.frame(row = c(1L, 1L, 2L),
                         name = c(x$accepted_name[1], x$accepted_name[1], "Other"),
                         backbone = c("lcvp", "ott", "col"),
                         alt = c("Polygonum aviculare", "Polygonum aviculare",
                                 "Wider"),
                         reason = c("broader_rank", "broader_rank",
                                    "accepted_elsewhere"),
                         stringsAsFactors = FALSE),
    refused_rows = data.frame(
      lookup_name = c("Polygonum aviculare", "Polygonum aviculare", "Wider"),
      tdwg_code = c("CLS", "AGE", "XXX"), stringsAsFactors = FALSE))
  rep <- .refused_report(x, rec, c("CLS", "AGE"), "tdwg_code", "native_status")
  expect_identical(nrow(rep), 1L)
  expect_identical(rep$refused_name, "Polygonum aviculare")
  expect_identical(rep$via, "lcvp, ott")
  expect_identical(rep$n_groups, 1L)
  expect_identical(rep$reason, "broader_rank")

  x$native_status_CLS[1] <- "introduced"
  expect_null(.refused_report(x, rec, c("CLS", "AGE"), "tdwg_code",
                              "native_status"))
})
