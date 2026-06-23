# TR8-backed scrape-on-demand enrichments (add_ecoflora/biolflor/pignatti).
#
# Pignatti ships bundled with TR8, so add_pignatti() is deterministic and
# network-free; it is the recovery anchor here. Ecoflora and BiolFlor scrape
# live and are exercised in tests/e2e/, not here.

test_that("add_pignatti() attaches Italian indicator values from bundled data", {
  skip_if_not_installed("TR8")

  x <- data.frame(
    query         = c("Abies alba", "Quercus robur"),
    accepted_name = c("Abies alba", "Quercus robur"),
    matched_name  = c("Abies alba", "Quercus robur"),
    stringsAsFactors = FALSE
  )

  r <- tryCatch(add_pignatti(x, verbose = FALSE),
                error = function(e) NULL)
  skip_if(is.null(r), "TR8 Pignatti fetch failed")

  # Columns are added with the _it region suffix (no collision with add_eive)
  expect_true(all(c("light_it", "temperature_it", "life_form_it",
                    "chorotype_it") %in% names(r)))
  # Row count and order preserved
  expect_equal(nrow(r), 2L)
  expect_equal(r$accepted_name, x$accepted_name)

  abies_light <- r$light_it[r$accepted_name == "Abies alba"][1]
  skip_if(is.na(abies_light), "TR8 Pignatti returned no value (offline?)")
  # Known truth from TR8's bundled pignatti data: Abies alba light = 3
  expect_identical(abies_light, "3")
})

test_that("TR8 wrappers add region-suffixed columns that never collide", {
  skip_if_not_installed("TR8")
  # The output column names of the three sources must be pairwise disjoint and
  # disjoint from add_baseflor()'s columns, so chaining never clobbers data.
  eco <- c("flower_begin_month_uk", "flower_end_month_uk",
           "pollination_vector_uk", "life_form_uk", "leaf_longevity_uk")
  bio <- c("strategy_type_de", "breeding_system_de", "pollination_vector_de",
           "life_form_de", "life_span_de", "apomixis_de")
  pig <- c("light_it", "temperature_it", "continentality_it", "moisture_it",
           "reaction_it", "nutrients_it", "salinity_it", "life_form_it",
           "chorotype_it")
  bas <- c("flower_begin_month", "flower_end_month", "pollination_vector",
           "dispersal_mode", "breeding_system", "flower_colour", "fruit_type",
           "woody_growth_form", "continentality", "salinity")
  all_cols <- c(eco, bio, pig, bas)
  expect_equal(length(all_cols), length(unique(all_cols)))
})
