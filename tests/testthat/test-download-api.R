test_that("download kind selects the catalogue and forwards options", {
  calls <- list()
  capture <- function(kind) function(name, version, verbose, force) {
    calls[[length(calls) + 1L]] <<- list(name = name, kind = kind,
      version = version, force = force, verbose = verbose)
    paste0(kind, "/", name, ".vtr")
  }
  with_mocked_bindings({
    expect_identical(taxify_download("wcvp", verbose = FALSE),
                     c(wcvp = "backbone/wcvp.vtr"))
    expect_identical(taxify_download(c("wcvp", "gift"), kind = "enrichment",
                                   version = "2026.01", force = TRUE, verbose = FALSE),
                     c(wcvp = "enrichment/wcvp.vtr", gift = "enrichment/gift.vtr"))
  }, download_backbone = capture("backbone"),
     download_enrichment = capture("enrichment"))
  expect_identical(vapply(calls, `[[`, "", "kind"),
                   c("backbone", "enrichment", "enrichment"))
  expect_true(calls[[2]]$force)
  expect_identical(calls[[2]]$version, "2026.01")
  expect_error(taxify_download("wcvp", kind = "unknown"), "arg")
})

test_that("downloads retain register alias and backbone build delegation", {
  with_mocked_bindings({
    expect_identical(taxify_download("register", verbose = FALSE), c(register = "register.vtr"))
    expect_identical(taxify_download("wfo", verbose = FALSE), c(wfo = "built.vtr"))
  }, ensure_register = function(...) "register.vtr",
     ensure_coverage = function(...) "coverage.vtr",
     download_backbone = function(...) stop("unavailable"),
     taxify_build = function(...) "built.vtr")
})
