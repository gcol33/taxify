test_that("source doors declare distinct prefixed output columns", {
  doors <- setdiff(grep("^add_", getNamespaceExports("taxify"), value = TRUE),
    c("add_data", "add_trait", "add_classification", "add_col_info",
      "add_gbif_info", "add_wfo_info", "add_hybrid_info"))
  columns <- character()
  for (door in doors) {
    source <- substring(door, 5L)
    available <- data.frame(column = taxify:::.gift_default_cols)
    spec <- taxify:::.enrichment_door_spec(source, available)
    overrides <- taxify:::.enrichment_prefix_overrides
    expected_prefix <- if (source %in% names(overrides)) overrides[[source]] else
      paste0(source, "_")
    expect_identical(spec$prefix, expected_prefix, info = door)
    expect_type(spec$map, "character")
    expect_true(all(startsWith(names(spec$map), spec$prefix)), info = door)
    expect_identical(intersect(columns, names(spec$map)), character(), info = door)
    columns <- c(columns, names(spec$map))
  }
})

test_that("all selectors reach curated and extra columns in both join paths", {
  x <- data.frame(accepted_name = "Aaa bbb")
  df <- data.frame(canonical_name = "Aaa bbb", raw = 7, extra = 8, place = "AT")
  install_mock_enrichment("demo", df)
  run <- function(cols, grouped = FALSE) {
    if (grouped) taxify:::enrich_by_group(
      x, "demo", "place", "AT", c(value = "raw"), "demo", cols = cols,
      verbose = FALSE) else taxify:::enrich_simple(
        x, "demo", c(value = "raw"), "demo", cols = cols, verbose = FALSE)
  }
  for (grouped in c(FALSE, TRUE)) {
    for (selector in c("demo_value", "value", "raw")) {
      expect_equal(run(selector, grouped)$demo_value, 7)
    }
    for (selector in c("demo_extra", "extra")) {
      expect_equal(run(selector, grouped)$demo_extra, 8)
    }
    expect_true(all(startsWith(setdiff(names(run("all", grouped)), names(x)), "demo_")))
    with_mocked_bindings({
      expect_equal(run("raw", grouped)$demo_value, 7)
      expect_equal(run("extra", grouped)$demo_extra, 8)
    }, ensure_enrichment = function(...) NULL,
       try_emergency_fallback = function(...) df)
  }
})

test_that("trait registry columns address the source independently of door names", {
  x <- data.frame(accepted_name = "Aaa bbb")
  install_mock_enrichment("avonet", data.frame(
    canonical_name = "Aaa bbb", body_mass_g = 12))
  expect_equal(add_avonet(x, cols = "body_mass_g", verbose = FALSE)$avonet_body_mass_g, 12)
  expect_equal(taxify:::.trait_join_one(x, "avonet", "body_mass_g", "numeric"), 12)
  expect_equal(taxify:::.trait_join_spread(x, "avonet", "body_mass_g")$value, 12)
  browse <- enrichment_cols("avonet")
  expect_identical(browse$output[browse$column == "body_mass_g"], "avonet_body_mass_g")
})

test_that("overlapping trait names coexist after consecutive source joins", {
  pairs <- list(
    list(sources = c("italic", "fungal_traits"), column = "growth_form"),
    list(sources = c("amphibio", "pantheria"), column = "litter_size"),
    list(sources = c("repttraits", "amphibio"), column = "longevity_yr"),
    list(sources = c("diaz_traits", "leda"), column = "seed_mass_mg"))
  for (pair in pairs) {
    x <- data.frame(accepted_name = "Aaa bbb", genus = "Aaa")
    outputs <- paste0(pair$sources, "_", pair$column)
    for (i in seq_along(pair$sources)) {
      source <- pair$sources[i]
      spec <- taxify:::.enrichment_door_spec(source)
      df <- data.frame(canonical_name = "Aaa bbb", genus = "Aaa")
      df[[spec$map[[outputs[i]]]]] <- i
      install_mock_enrichment(source, df)
      door <- get(paste0("add_", source), asNamespace("taxify"))
      x <- door(x, cols = pair$column, verbose = FALSE)
    }
    expect_equal(x[[outputs[1]]], 1)
    expect_equal(x[[outputs[2]]], 2)
  }
})
