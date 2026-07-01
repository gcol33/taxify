# GIFT is an on-demand enrichment (like Pignatti): its per-reference-licensed
# trait values are fetched live via the GIFT package, not redistributed. The
# join tests below require internet and the GIFT package, and skip otherwise.

test_that("add_gift() errors on input without accepted_name", {
  expect_error(add_gift(data.frame(x = 1)), "accepted_name")
})

test_that("add_gift() attaches curated GIFT trait columns by accepted name", {
  skip_if_not_installed("GIFT")
  skip_on_cran()

  x <- data.frame(
    query         = c("Abies alba", "Quercus robur"),
    accepted_name = c("Abies alba", "Quercus robur"),
    matched_name  = c("Abies alba", "Quercus robur"),
    stringsAsFactors = FALSE
  )

  r <- tryCatch(add_gift(x, verbose = FALSE), error = function(e) NULL)
  skip_if(is.null(r), "GIFT fetch failed (offline?)")

  expect_true(all(c("gift_woodiness", "gift_growth_form",
                    "gift_plant_height_max", "gift_seed_mass_mean",
                    "gift_sla_mean") %in% names(r)))
  # Row count and order preserved
  expect_equal(nrow(r), 2L)
  expect_equal(r$accepted_name, x$accepted_name)
  # Numeric traits come back numeric
  expect_type(r$gift_plant_height_max, "double")
  expect_type(r$gift_seed_mass_mean, "double")

  woody <- r$gift_woodiness[r$accepted_name == "Abies alba"][1]
  skip_if(is.na(woody), "GIFT returned no value for Abies alba (offline?)")
  # Known truth from GIFT: Abies alba is woody with a large max height
  expect_identical(woody, "woody")
  expect_true(is.finite(r$gift_plant_height_max[r$accepted_name == "Abies alba"][1]))
})

test_that("add_gift() attaches NA for species absent from GIFT", {
  skip_if_not_installed("GIFT")
  skip_on_cran()

  x <- data.frame(
    query         = "Panthera leo",
    accepted_name = "Panthera leo",
    matched_name  = "Panthera leo",
    stringsAsFactors = FALSE
  )
  r <- tryCatch(add_gift(x, verbose = FALSE), error = function(e) NULL)
  skip_if(is.null(r), "GIFT fetch failed (offline?)")

  expect_true("gift_woodiness" %in% names(r))
  expect_true(is.na(r$gift_woodiness))
  expect_true(is.na(r$gift_plant_height_max))
})
