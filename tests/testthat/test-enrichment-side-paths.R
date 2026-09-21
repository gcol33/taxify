# The less-travelled enrichment join paths (#64).

test_that("species-level recovery runs before the genus fill", {
  install_mock_enrichment("mockgenusfb", data.frame(
    canonical_name = c("Sabulina tenuifolia", "Minuartia"),
    habit          = c("species value", "genus value"),
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Minuartia hybrida", genus = "Minuartia",
                  qualifier = NA_character_, stringsAsFactors = FALSE)

  r <- testthat::with_mocked_bindings(
    enrich_simple(x, "mockgenusfb", col_map = c(habit = "habit"),
                  source_label = "mock", genus_fallback = TRUE,
                  verbose = FALSE),
    .cross_backbone_alternatives = function(names_in, kingdoms = NULL, only = NULL) {
      data.frame(input_name = "Minuartia hybrida", backbone = "wcvp",
                 alt_name = "Sabulina tenuifolia", alt_authorship = NA_character_,
                 alt_genus = "Sabulina", stringsAsFactors = FALSE)
    },
    .package = "taxify"
  )
  expect_equal(r$habit, "species value")

  # With nothing to recover, the genus row still fills the gap.
  g <- testthat::with_mocked_bindings(
    enrich_simple(x, "mockgenusfb", col_map = c(habit = "habit"),
                  source_label = "mock", genus_fallback = TRUE,
                  verbose = FALSE),
    .cross_backbone_alternatives = function(names_in, kingdoms = NULL, only = NULL) {
      data.frame(input_name = character(0), backbone = character(0),
                 alt_name = character(0), alt_authorship = character(0),
                 alt_genus = character(0), stringsAsFactors = FALSE)
    },
    .package = "taxify"
  )
  expect_equal(g$habit, "genus value")
})

stage_grouped <- function(name, df, groups_in_meta) {
  dd <- tempfile("grp_")
  latest <- file.path(dd, "enrichment", name, "latest")
  dir.create(latest, recursive = TRUE)
  vectra::write_vtr(df, file.path(latest, paste0(name, ".vtr")))
  jsonlite::write_json(
    list(version = "2026.06", static = TRUE, group_col = "lang",
         available_groups = groups_in_meta),
    file.path(latest, "meta.json"), auto_unbox = TRUE)
  set_backbone_path(paste0("enrichment_", name), NULL)
  .taxify_env[[paste0(".enrichment_version_checked.", name)]] <- TRUE
  dd
}

test_that('groups = "all" reads the installed build, not the manifest', {
  df <- data.frame(canonical_name = c("Quercus robur", "Quercus robur"),
                   lang = c("de", "fr"), vname = c("Stieleiche", "chene"),
                   stringsAsFactors = FALSE)
  dd <- stage_grouped("mockgrp", df, c("de", "fr"))
  withr::local_options(taxify.data_dir = dd)
  orig <- .taxify_env$manifest
  .taxify_env$manifest <- list(schema_version = 2L, enrichments = list(
    mockgrp = list(latest = "2026.08", available_groups = c("en", "it"))))
  on.exit(.taxify_env$manifest <- orig, add = TRUE)

  vtr <- enrichment_vtr_path("mockgrp", "latest")
  expect_equal(resolve_all_groups(vtr, "mockgrp", "lang"), c("de", "fr"))

  x <- data.frame(accepted_name = "Quercus robur", matched_name = "Quercus robur",
                  stringsAsFactors = FALSE)
  r <- enrich_by_group(x, "mockgrp", "lang", "all", c(vname = "vname"),
                       "mock", verbose = FALSE)
  expect_true(all(c("vname_de", "vname_fr") %in% names(r)))
  expect_false(any(c("vname_en", "vname_it") %in% names(r)))
  expect_equal(r$vname_de, "Stieleiche")
})

test_that("the emergency grouped path keeps the NA group", {
  df <- data.frame(canonical_name = c("Quercus robur", "Quercus robur"),
                   lang = c(NA, "en"), common_name = c("oak (ncbi)", "oak"),
                   stringsAsFactors = FALSE)
  x <- data.frame(accepted_name = "Quercus robur", matched_name = "Quercus robur",
                  stringsAsFactors = FALSE)
  r <- enrich_from_dataframe_grouped(x, df, "common_names", "lang",
                                     NA_character_,
                                     c(common_name = "common_name"), "mock")
  expect_equal(r$common_name, "oak (ncbi)")
})
