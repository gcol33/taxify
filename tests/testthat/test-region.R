test_that("validate_region normalizes, de-dupes, and handles NULL/empty", {
  expect_null(validate_region(NULL))
  expect_null(validate_region(c("", NA, "  ")))
  expect_equal(validate_region(c(" bel ", "GER", "ger")), c("BEL", "GER"))
  expect_error(validate_region(42), "character vector")
})

test_that("range_status_ok maps modes to WCVP statuses", {
  st <- c("native", "introduced", "extinct", NA)
  expect_equal(range_status_ok("present", st),    c(TRUE, TRUE, TRUE, FALSE))
  expect_equal(range_status_ok("native", st),     c(TRUE, FALSE, FALSE, FALSE))
  expect_equal(range_status_ok("introduced", st), c(FALSE, TRUE, FALSE, FALSE))
  expect_error(range_status_ok("bogus", st), "unknown range mode")
})

test_that("filter_fuzzy_by_region is a no-op without a region", {
  m <- data.frame(row_idx = 1L, accepted_name = "Quercus robur",
                  stringsAsFactors = FALSE)
  expect_identical(filter_fuzzy_by_region(m, NULL, "present"), m)
  expect_identical(filter_fuzzy_by_region(m, character(0), "present"), m)
})

test_that("filter drops an out-of-region rival when a better candidate survives", {
  # Input 1 has two candidates: one recorded in region, one recorded elsewhere.
  # Input 2 has one candidate with no range data at all (e.g. an animal).
  m <- data.frame(
    row_idx       = c(1L, 1L, 2L),
    accepted_name = c("In Species", "Out Species", "No Data Species"),
    stringsAsFactors = FALSE
  )
  sets <- list(present  = "In Species",
               has_data = c("In Species", "Out Species"))

  out <- with_mocked_bindings(
    region_range_sets = function(...) sets,
    filter_fuzzy_by_region(m, "BEL", "present")
  )

  # The out-of-region candidate for input 1 is dropped; the in-region one and
  # the no-data candidate survive.
  expect_equal(nrow(out), 2L)
  expect_setequal(out$accepted_name, c("In Species", "No Data Species"))
})

test_that("a candidate with no range data is never dropped", {
  m <- data.frame(row_idx = 1L, accepted_name = "No Data Species",
                  stringsAsFactors = FALSE)
  sets <- list(present = character(0), has_data = character(0))
  out <- with_mocked_bindings(
    region_range_sets = function(...) sets,
    filter_fuzzy_by_region(m, "BEL", "present")
  )
  expect_equal(nrow(out), 1L)
})

test_that("when every candidate is out of region, all are kept (no lost match)", {
  m <- data.frame(
    row_idx       = c(1L, 1L),
    accepted_name = c("Out A", "Out B"),
    stringsAsFactors = FALSE
  )
  sets <- list(present = character(0), has_data = c("Out A", "Out B"))
  out <- with_mocked_bindings(
    region_range_sets = function(...) sets,
    filter_fuzzy_by_region(m, "BEL", "present")
  )
  expect_equal(nrow(out), 2L)
})

test_that("filter skips cleanly when WCVP range data is unavailable", {
  m <- data.frame(row_idx = c(1L, 1L),
                  accepted_name = c("In Species", "Out Species"),
                  stringsAsFactors = FALSE)
  out <- with_mocked_bindings(
    region_range_sets = function(...) NULL,
    filter_fuzzy_by_region(m, "BEL", "present")
  )
  expect_identical(out, m)
})

test_that("validate_region resolves region names to TDWG codes", {
  expect_equal(validate_region("Belgium"), "BGM")
  expect_equal(validate_region("belgium"), "BGM")
  expect_equal(validate_region("Germany"), "GER")
  # A Level 1 continent name expands to all its member codes.
  eur <- validate_region("Europe")
  expect_true(length(eur) > 20)
  expect_true(all(c("BGM", "GER") %in% eur))
  expect_false("ALG" %in% eur)   # Algeria is African, not European
})

test_that("validate_region folds accents in region names", {
  expect_equal(validate_region("Reunion"), "REU")   # matches "Reunion"
  expect_equal(validate_region("Quebec"), "QUE")    # matches "Quebec"
})

test_that("validate_region warns on unresolvable tokens, keeps bare codes", {
  expect_warning(r <- validate_region("Nowhereland"), "Unrecognized region")
  expect_null(r)
  expect_equal(suppressWarnings(validate_region("ZZZ")), "ZZZ")
})

test_that("taxify_regions lists and searches the WGSRPD crosswalk", {
  all_reg <- taxify_regions()
  expect_true(nrow(all_reg) > 300)
  expect_true(all(c("code", "name", "level2_name", "level1_name") %in%
                  names(all_reg)))
  expect_equal(taxify_regions("belgium")$code, "BGM")
  expect_true(nrow(taxify_regions("Europe")) > 20)
})

test_that("normalize_coords accepts vectors and frames, rejects bad input", {
  expect_equal(normalize_coords(c(4.35, 50.85)),
               matrix(c(4.35, 50.85), ncol = 2))
  df <- data.frame(lat = 50.85, lon = 4.35)
  expect_equal(normalize_coords(df), matrix(c(4.35, 50.85), ncol = 2))
  expect_error(normalize_coords(c(1, 2, 3)), "length 2")
  expect_error(normalize_coords(c(200, 0)), "out of range")
})

test_that("point-in-polygon locates points in a synthetic region", {
  ring  <- cbind(c(0, 10, 10, 0, 0), c(0, 0, 10, 10, 0))
  feats <- list(list(code = "BOX", bbox = c(0, 10, 0, 10),
                     polys = list(list(ring))))
  expect_equal(locate_points(c(5, 20), c(5, 20), feats), c("BOX", NA))
  expect_true(points_in_ring(5, 5, ring))
  expect_false(points_in_ring(50, 50, ring))
})

test_that("coords_to_codes and resolve_region union codes and coordinates", {
  old <- options(taxify.pip_engine = "native")  # use the mockable native path
  on.exit(options(old), add = TRUE)
  ring  <- cbind(c(0, 10, 10, 0, 0), c(0, 0, 10, 10, 0))
  feats <- list(list(code = "BOX", bbox = c(0, 10, 0, 10),
                     polys = list(list(ring))))
  out <- with_mocked_bindings(
    wgsrpd_polygons = function(...) feats,
    coords_to_codes(matrix(c(5, 5), ncol = 2))
  )
  expect_equal(out, "BOX")

  combined <- with_mocked_bindings(
    wgsrpd_polygons = function(...) feats,
    resolve_region(region = "Belgium", coords = c(5, 5))
  )
  expect_setequal(combined, c("BGM", "BOX"))
  expect_null(resolve_region(NULL, NULL))
})

test_that("coords_to_codes warns when boundaries are unavailable", {
  # Missing boundary file makes every engine return NULL (no download here).
  with_mocked_bindings(
    wgsrpd_geojson_path = function(...) NULL,
    {
      expect_warning(out <- coords_to_codes(c(5, 5)), "boundaries unavailable")
      expect_null(out)
    }
  )
})

test_that("region_pip_engine honors the taxify.pip_engine option", {
  old <- options(taxify.pip_engine = "native"); on.exit(options(old), add = TRUE)
  expect_equal(region_pip_engine(), "native")
  options(taxify.pip_engine = "sf")
  expect_equal(region_pip_engine(), "sf")
  options(taxify.pip_engine = "terra")
  expect_equal(region_pip_engine(), "terra")
})

test_that("normalize_coords reads sf and terra point objects", {
  skip_if_not_installed("sf")
  skip_if_not_installed("terra")
  target <- matrix(c(4.35, 50.85), ncol = 2)

  pt_sf <- sf::st_as_sf(data.frame(lon = 4.35, lat = 50.85),
                        coords = c("lon", "lat"), crs = 4326)
  expect_equal(normalize_coords(pt_sf), target)

  pt_v <- terra::vect(target, type = "points", crs = "EPSG:4326")
  expect_equal(normalize_coords(pt_v), target)

  # A projected sf point (Web Mercator) is reprojected back to lon/lat.
  pt_merc <- sf::st_transform(pt_sf, 3857)
  expect_equal(normalize_coords(pt_merc), target, tolerance = 1e-4)
})

test_that("terra and sf engines agree with native on a synthetic region", {
  skip_if_not_installed("sf")
  skip_if_not_installed("terra")

  rm(list = intersect(c("wgsrpd_terra", "wgsrpd_sf", "wgsrpd_polygons"),
                      ls(.taxify_env)), envir = .taxify_env)

  dd <- file.path(tempfile("taxregion_"))
  dir.create(file.path(dd, "wgsrpd"), recursive = TRUE)
  on.exit({
    unlink(dd, recursive = TRUE)
    rm(list = intersect(c("wgsrpd_terra", "wgsrpd_sf", "wgsrpd_polygons"),
                        ls(.taxify_env)), envir = .taxify_env)
  }, add = TRUE)
  gj <- paste0(
    '{"type":"FeatureCollection","features":[{"type":"Feature",',
    '"properties":{"LEVEL3_COD":"BOX"},"geometry":{"type":"Polygon",',
    '"coordinates":[[[0,0],[10,0],[10,10],[0,10],[0,0]]]}}]}'
  )
  writeLines(gj, file.path(dd, "wgsrpd", "level3.geojson"))
  old <- options(taxify.data_dir = dd); on.exit(options(old), add = TRUE)

  for (eng in c("native", "terra", "sf")) {
    options(taxify.pip_engine = eng)
    expect_equal(coords_to_codes(c(5, 5)), "BOX", info = eng)
    expect_equal(coords_to_codes(c(20, 20)), character(0), info = eng)
  }
})

test_that("region filtering runs end-to-end against the example database", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  base <- taxify("Quercus robus", verbose = FALSE)
  reg  <- taxify("Quercus robus", region = "EUR", verbose = FALSE)

  expect_s3_class(reg, "taxify_result")
  expect_equal(nrow(reg), 1L)
  # Quercus robur is recorded in EUR, so the fuzzy match is retained.
  expect_equal(reg$match_type, "fuzzy")
  expect_equal(reg$accepted_name, base$accepted_name)
})
