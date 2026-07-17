# Marine region support (issue #21): when the marine_distribution asset is
# installed, region=/coords= resolve to MEOW ecoregion codes and the fuzzy
# region filter constrains marine candidates the same way WCVP constrains plants.

# A fixture data dir holding a marine_distribution enrichment .vtr and a MEOW
# boundary .vtr (one square ecoregion, code 9999, spanning (0,0)-(10,10)).
local_marine_data <- function(env = parent.frame()) {
  dd <- tempfile("taxmarine_")
  dir.create(file.path(dd, "enrichment", "marine_distribution", "latest"),
             recursive = TRUE)
  dir.create(file.path(dd, "meow", "latest"), recursive = TRUE)

  enr <- data.frame(
    canonical_name = c("Marine sp", "Marine sp", "Coastal sp"),
    region_code    = c("9999", "8888", "9999"),
    ecoregion      = c("Test Sea", "Other Sea", "Test Sea"),
    province       = c("Test Province", "Other Province", "Test Province"),
    realm          = c("Test Realm", "Other Realm", "Test Realm"),
    native_status  = c("native", "introduced", "native"),
    stringsAsFactors = FALSE
  )
  enr_path <- file.path(dd, "enrichment", "marine_distribution", "latest",
                        "marine_distribution.vtr")
  vectra::write_vtr(enr, enr_path)

  box <- data.frame(
    code = "9999", geom = 1L, ring = 1L, seq = 1:5,
    lon = c(0, 10, 10, 0, 0), lat = c(0, 0, 10, 10, 0),
    stringsAsFactors = FALSE
  )
  vectra::write_vtr(box, file.path(dd, "meow", "latest", "meow.vtr"))

  keys <- c("meow_df", "meow_polygons", "meow_wkt", "meow_terra", "meow_sf",
            "meow_alias_map", "enrichment_marine_distribution")
  rm(list = intersect(keys, ls(.taxify_env)), envir = .taxify_env)
  # Skip the once-per-session network freshness check for the fixture asset.
  assign(".enrichment_version_checked.marine_distribution", TRUE,
         envir = .taxify_env)

  withr::local_options(list(taxify.data_dir = dd, taxify.pip_engine = "native"),
                       .local_envir = env)
  withr::defer({
    rm(list = intersect(c(keys, ".enrichment_version_checked.marine_distribution"),
                        ls(.taxify_env)), envir = .taxify_env)
    unlink(dd, recursive = TRUE)
  }, envir = env)
  dd
}

test_that("marine support is inactive without the asset, active with it", {
  withr::local_options(list(taxify.data_dir = tempfile("empty_")))
  expect_false(marine_region_active())

  local_marine_data()
  expect_true(marine_region_active())
})

test_that("meow_alias_map resolves ecoregion, province, and realm names", {
  local_marine_data()
  am <- meow_alias_map()
  expect_true(all(c("key", "code") %in% names(am)))
  # ecoregion name -> its own code
  expect_equal(am$code[am$key == "test sea"], "9999")
  # a realm name expands to every member ecoregion code
  expect_setequal(am$code[am$key == "test realm"], "9999")
  expect_setequal(am$code[am$key == "other realm"], "8888")
})

test_that("validate_region resolves MEOW names and numeric codes when active", {
  local_marine_data()
  expect_equal(validate_region("Test Sea"), "9999")
  expect_equal(validate_region("test sea"), "9999")
  expect_equal(validate_region("9999"), "9999")
  # a bare TDWG-style token still passes through as before
  expect_equal(suppressWarnings(validate_region("ZZZ")), "ZZZ")
})

test_that("coords_to_codes maps a marine point to its MEOW ecoregion", {
  local_marine_data()
  # A point inside the marine box resolves to its ECO_CODE (unioned with any
  # WGSRPD land code, which is why we test membership, not equality: WGSRPD may
  # or may not be installed in the test environment).
  expect_true("9999" %in% coords_to_codes(c(5, 5)))
  # A point outside the box is not attributed to the marine ecoregion.
  expect_false("9999" %in% coords_to_codes(c(50, 50)))
})

test_that("region_range_sets routes numeric codes to the marine provider", {
  local_marine_data()
  sets <- region_range_sets(c("Marine sp", "Coastal sp", "No Data sp"),
                            "9999", "present")
  expect_setequal(sets$present, c("Marine sp", "Coastal sp"))
  expect_setequal(sets$has_data, c("Marine sp", "Coastal sp"))

  # native vs introduced status is honoured against the marine table
  nat <- region_range_sets("Marine sp", "8888", "native")
  expect_length(nat$present, 0L)          # Marine sp is introduced in 8888
  intro <- region_range_sets("Marine sp", "8888", "introduced")
  expect_setequal(intro$present, "Marine sp")
})

test_that("filter_fuzzy_by_region drops an out-of-region marine rival", {
  local_marine_data()
  # Input 1: an in-region marine candidate vs one recorded only in another sea.
  m <- data.frame(
    row_idx       = c(1L, 1L, 2L),
    accepted_name = c("Marine sp", "Other sp", "No Data sp"),
    stringsAsFactors = FALSE
  )
  # "Other sp" occurs only in 8888; Marine sp occurs in 9999.
  enr_extra <- data.frame(
    canonical_name = "Other sp", region_code = "8888", ecoregion = "Other Sea",
    province = "Other Province", realm = "Other Realm",
    native_status = "native", stringsAsFactors = FALSE
  )
  # append the extra row by rebuilding the enrichment for this test
  path <- enrichment_vtr_path("marine_distribution")
  cur <- vectra::collect(vectra::tbl(path))
  vectra::write_vtr(rbind(cur, enr_extra), path)
  rm(list = intersect("enrichment_marine_distribution", ls(.taxify_env)),
     envir = .taxify_env)

  out <- filter_fuzzy_by_region(m, "9999", "present")
  # Marine sp (in region) and No Data sp (no range data) survive; Other sp drops.
  expect_setequal(out$accepted_name, c("Marine sp", "No Data sp"))
})
