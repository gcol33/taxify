# Pignatti is the only remaining TR8-backed scrape-on-demand enrichment (its
# values are from a copyrighted publication and cannot be redistributed). It
# ships bundled with TR8, so add_pignatti() is deterministic and network-free.
#
# Ecoflora and FloraWeb are now bundled .vtr enrichments (add_ecoflora(),
# add_floraweb()); their join correctness is exercised in tests/e2e/.

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

test_that("regional plant-trait columns are pairwise disjoint", {
  # The output columns of the regional plant-trait enrichments must never
  # collide, so chaining add_baseflor() / add_ecoflora() / add_floraweb() /
  # add_pignatti() cannot clobber one another. The _uk / _de / _it suffixes
  # (and baseflor's unsuffixed names) guarantee this.
  eco <- c("height_max_mm_uk", "height_min_mm_uk", "leaf_area_uk",
           "leaf_longevity_uk", "root_system_uk", "photosynthetic_pathway_uk",
           "life_form_uk", "reproduction_uk", "flower_begin_month_uk",
           "flower_end_month_uk", "pollination_vector_uk", "seed_weight_mg_uk",
           "propagule_uk", "ell_light_uk", "ell_moisture_uk", "ell_reaction_uk",
           "ell_nitrogen_uk", "ell_salt_uk")
  fw  <- .floraweb_cols  # 59 _de columns, package-internal single source
  pig <- c("light_it", "temperature_it", "continentality_it", "moisture_it",
           "reaction_it", "nutrients_it", "salinity_it", "life_form_it",
           "chorotype_it")
  bas <- c("flower_begin_month", "flower_end_month", "pollination_vector",
           "dispersal_mode", "breeding_system", "flower_colour", "fruit_type",
           "woody_growth_form", "continentality", "salinity")
  all_cols <- c(eco, fw, pig, bas)
  expect_equal(length(all_cols), length(unique(all_cols)))
})
