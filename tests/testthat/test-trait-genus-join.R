# The cross-source trait verb can consume genus-keyed enrichments: each registry
# source may set join_col = "genus", which add_trait() threads through to
# enrich_simple(). Species-keyed sources keep the default accepted_name join.
# Nineteenth wave: NestTrait nest modalities, FungalRoot mycorrhizal_type.

test_that("nineteenth-wave traits are registered and well-formed", {
  reg <- taxify:::.trait_registry()
  new <- c("nest_structure", "nest_site", "nest_attachment", "mycorrhizal_type")
  expect_true(all(new %in% names(reg)))
  for (t in new) expect_identical(reg[[t]]$kind, "categorical")
  # mycorrhizal_type joins on genus; nest traits keep the species default.
  expect_identical(reg$mycorrhizal_type$sources$fungalroot$join_col, "genus")
  expect_null(reg$nest_structure$sources$nesttrait$join_col)
  # The pre-existing genus-keyed FungalTraits source is now correctly flagged.
  expect_identical(reg$fungal_trophic_mode$sources$fungal_traits$join_col,
                   "genus")
})

test_that("every genus-keyed enrichment feeding the verb sets join_col=genus", {
  # A genus-resolved enrichment joined on the accepted_name default returns
  # all-NA through the verb (the latent bug the join_col unlock exists to fix).
  # Enumerate the known genus-keyed enrichments and assert no registry source
  # references one without join_col = "genus".
  genus_keyed <- genus_keyed_enrichments()
  reg <- taxify:::.trait_registry()
  for (tr in names(reg)) {
    for (sn in names(reg[[tr]]$sources)) {
      src <- reg[[tr]]$sources[[sn]]
      if (src$enrichment %in% genus_keyed) {
        expect_identical(
          src$join_col %||% "accepted_name", "genus",
          info = sprintf("trait '%s' source '%s' (enrichment '%s')",
                         tr, sn, src$enrichment)
        )
      }
    }
  }
})

test_that("nest modality maps keep multi-modal pipe sets verbatim", {
  reg <- taxify:::.trait_registry()
  m   <- reg$nest_structure$sources$nesttrait$map
  expect_identical(m(c("cup|dome", "", "scrape")),
                   c("cup|dome", NA, "scrape"))
})

# A synthetic genus-keyed enrichment named "fungalroot" (genus + mycorrhizal_type
# columns) staged in a temp data dir: add_trait() must join it by genus.
stage_fungalroot <- function(dd, df) {
  edir <- file.path(dd, "enrichment", "fungalroot", "latest")
  dir.create(edir, recursive = TRUE, showWarnings = FALSE)
  vectra::write_vtr(df, file.path(edir, "fungalroot.vtr"))
  writeLines(jsonlite::toJSON(list(
    name = "fungalroot", version = "test", static = TRUE,
    license = "CC BY-NC 4.0"
  ), auto_unbox = TRUE), file.path(edir, "meta.json"))
}

test_that("add_trait() joins a genus-keyed source on genus (recovery test)", {
  skip_if_not_installed("vectra")
  df <- data.frame(
    canonical_name   = c("Abies", "Betula", "Pisum"),
    genus            = c("Abies", "Betula", "Pisum"),
    mycorrhizal_type = c("EcM", "EcM", "AM"),
    stringsAsFactors = FALSE
  )
  dd <- tempfile("tx_dd_"); dir.create(dd)
  stage_fungalroot(dd, df)
  old <- options(taxify.data_dir = dd)
  on.exit(options(old), add = TRUE)

  # Hermetic against test-file ordering: drop any session-cached real fungalroot
  # path and short-circuit the version check so the staged temp dir is used.
  taxify:::set_backbone_path("enrichment_fungalroot", NULL)
  assign(".enrichment_version_checked.fungalroot", TRUE,
         envir = taxify:::.taxify_env)
  on.exit({
    taxify:::set_backbone_path("enrichment_fungalroot", NULL)
    assign(".enrichment_version_checked.fungalroot", NULL,
           envir = taxify:::.taxify_env)
  }, add = TRUE)

  x <- data.frame(
    accepted_name = c("Abies alba", "Betula pendula", "Pisum sativum", "Homo sapiens"),
    genus         = c("Abies", "Betula", "Pisum", "Homo"),
    qualifier     = NA_character_,
    stringsAsFactors = FALSE
  )
  r <- add_trait(x, "mycorrhizal_type", verbose = FALSE)

  expect_equal(r$mycorrhizal_type,
               c("EcM", "EcM", "AM", NA_character_))
  # Genus with no row in the source stays NA and contributes no source.
  expect_equal(r$mycorrhizal_type_n, c(1L, 1L, 1L, 0L))
})
