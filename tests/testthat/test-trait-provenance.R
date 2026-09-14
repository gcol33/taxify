# add_trait(provenance = TRUE) returns the references behind each value, read
# from the `<col>_source` columns an enrichment build records, and cite()
# resolves them against the reference table shipped with the enrichment.

mk_prov <- function(sp) data.frame(
  query = sp, accepted_name = sp, matched_name = sp, stringsAsFactors = FALSE
)

# Stage one installed enrichment build (with an optional reference table) in a
# throwaway data dir. No `downloaded_at`, so the content gate leaves it alone.
stage_enrichment <- function(dd, name, df, refs = NULL) {
  dir <- file.path(dd, "enrichment", name, "latest")
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  vectra::write_vtr(df, file.path(dir, paste0(name, ".vtr")))
  meta <- list(name = name, version = "test", static = TRUE)
  if (!is.null(refs)) {
    rf <- paste0(name, "_references.vtr")
    vectra::write_vtr(refs, file.path(dir, rf))
    meta$references <- list(file = rf, nrow = nrow(refs))
  }
  jsonlite::write_json(meta, file.path(dir, "meta.json"), auto_unbox = TRUE)
}

local_provenance_db <- function(env = parent.frame()) {
  dd <- withr::local_tempdir(.local_envir = env)
  stage_enrichment(dd, "austraits",
    data.frame(canonical_name = c("Acacia alata", "Banksia serrata"),
               dispersal_syndrome = c("myrmecochory", "anemochory"),
               dispersal_syndrome_source = c("ABRS_1981|Smith_2005", "Jones_2010"),
               stringsAsFactors = FALSE),
    refs = data.frame(ref_id = c("ABRS_1981", "Jones_2010", "Smith_2005"),
                      citation = c("Barlow (1981) Flora of Australia.",
                                   "Jones (2010) Wind.", "Smith (2005) Seeds."),
                      doi = c(NA, "10.1234/jones", NA),
                      stringsAsFactors = FALSE))
  stage_enrichment(dd, "gift",
    data.frame(canonical_name = c("Acacia alata", "Banksia serrata"),
               gift_dispersal_syndrome_1 = c("myrmecochorous", "zoochorous"),
               gift_dispersal_syndrome_1_source = c("10255", "272|10599"),
               stringsAsFactors = FALSE),
    refs = data.frame(ref_id = c("10255", "10599", "272"),
                      citation = c("Kew (2016) Seed information database.",
                                   "Ghazanfar (2001) Coastal vegetation.",
                                   "Linhart (1980) Caribbean atoll."),
                      doi = NA_character_, stringsAsFactors = FALSE))
  # A source without a reference table: its values count, its references do not.
  stage_enrichment(dd, "brot",
    data.frame(canonical_name = "Acacia alata", disp_mode = "myrmecochory",
               stringsAsFactors = FALSE))
  for (n in c("austraits", "gift", "brot")) {
    key <- paste0(".enrichment_version_checked.", n)
    .taxify_env[[key]] <- TRUE
    set_backbone_path(paste0("enrichment_", n), NULL)
  }
  withr::local_options(taxify.data_dir = dd, taxify.offline = TRUE,
                       .local_envir = env)
  withr::defer({
    for (n in c("austraits", "gift", "brot")) {
      set_backbone_path(paste0("enrichment_", n), NULL)
      key <- paste0(".enrichment_version_checked.", n)
      if (exists(key, envir = .taxify_env)) rm(list = key, envir = .taxify_env)
    }
  }, envir = env)
  dd
}

test_that("coalesce refs name the sources behind the reported value", {
  local_provenance_db()
  x <- mk_prov(c("Acacia alata", "Banksia serrata", "Unknown species"))
  r <- add_trait(x, "dispersal_syndrome",
                 sources = c("gift", "austraits", "brot"),
                 provenance = TRUE, verbose = FALSE)
  expect_equal(r$dispersal_syndrome, c("ant", "animal", NA))
  # combine = "first": the reported value is GIFT's, so only GIFT's references.
  expect_equal(r$dispersal_syndrome_sources, c("gift", "gift", NA))
  expect_equal(r$dispersal_syndrome_refs, c("gift:10255", "gift:10599|gift:272", NA))
})

test_that("vote keeps only the references of sources that agree", {
  local_provenance_db()
  x <- mk_prov(c("Acacia alata", "Banksia serrata"))
  r <- add_trait(x, "dispersal_syndrome",
                 sources = c("gift", "austraits", "brot"), combine = "vote",
                 provenance = TRUE, verbose = FALSE)
  expect_equal(r$dispersal_syndrome, c("ant", "animal"))
  # Acacia: all three agree on ant, brot has no references to give.
  expect_equal(r$dispersal_syndrome_refs[1],
               "austraits:ABRS_1981|austraits:Smith_2005|gift:10255")
  # Banksia: AusTraits says wind, GIFT animal; the tie goes to GIFT (priority).
  expect_equal(r$dispersal_syndrome_refs[2], "gift:10599|gift:272")
})

test_that("wide mode returns one refs column per source", {
  local_provenance_db()
  r <- add_trait(mk_prov("Acacia alata"), "dispersal_syndrome",
                 sources = c("gift", "austraits", "brot"), mode = "wide",
                 provenance = TRUE, verbose = FALSE)
  expect_equal(r$dispersal_syndrome_austraits_refs,
               "austraits:ABRS_1981|austraits:Smith_2005")
  expect_equal(r$dispersal_syndrome_gift_refs, "gift:10255")
  expect_true(is.na(r$dispersal_syndrome_brot_refs))
})

test_that("provenance = FALSE adds no refs columns", {
  local_provenance_db()
  r <- add_trait(mk_prov("Acacia alata"), "dispersal_syndrome",
                 sources = c("gift", "austraits"), verbose = FALSE)
  expect_false(any(grepl("_refs$", names(r))))
})

test_that("cite() resolves qualified reference ids to citations", {
  local_provenance_db()
  ids <- c("austraits:ABRS_1981|gift:10255", NA, "austraits:Jones_2010")
  out <- NULL
  printed <- capture.output(out <- cite(ids))
  expect_equal(out$ref, c("austraits:ABRS_1981", "gift:10255", "austraits:Jones_2010"))
  expect_equal(out$citation,
               c("Barlow (1981) Flora of Australia.",
                 "Kew (2016) Seed information database.", "Jones (2010) Wind."))
  expect_equal(out$doi[3], "10.1234/jones")
  expect_true(any(grepl("Jones (2010) Wind. doi:10.1234/jones", printed, fixed = TRUE)))

  bib <- withr::local_tempfile(fileext = ".bib")
  capture.output(cite(ids, file = bib))
  txt <- readLines(bib)
  expect_true(any(grepl("@misc{austraits:ABRS_1981,", txt, fixed = TRUE)))
  expect_true(any(grepl("doi = {10.1234/jones}", txt, fixed = TRUE)))
})

test_that("cite() takes bare ids from a door's _source column with source =", {
  local_provenance_db()
  out <- NULL
  capture.output(out <- cite("ABRS_1981|Smith_2005", source = "austraits"))
  expect_equal(out$ref, c("austraits:ABRS_1981", "austraits:Smith_2005"))
  expect_equal(out$citation[2], "Smith (2005) Seeds.")
  expect_error(cite("ABRS_1981"), "source prefix")
})

test_that("cite() warns on an id its source's table does not hold", {
  local_provenance_db()
  expect_warning(capture.output(out <- cite("gift:99999")), "not found")
  expect_error(capture.output(cite("brot:X1")), "no reference table")
})

test_that("cite() on a taxify result is unchanged by the character method", {
  expect_error(cite(data.frame(a = 1)), "taxify_meta")
})

test_that("the downloaded meta declares a manifest entry's reference table", {
  vtr <- withr::local_tempfile(fileext = ".vtr")
  vectra::write_vtr(data.frame(canonical_name = "A b"), vtr)
  entry <- list(static = TRUE, references = list(
    url = "https://example.org/enrichment-2026.09/austraits_references.vtr",
    content_id = "0123456789abcdef0123456789abcdef", nrow = 410L))
  meta <- build_enrichment_meta(entry, "2026.09", pinned = FALSE, vtr)
  expect_equal(meta$references$file, "austraits_references.vtr")
  expect_equal(meta$references$nrow, 410L)
  expect_null(build_enrichment_meta(list(static = TRUE), "1", FALSE, vtr)$references)
})

test_that("a reference table whose bytes do not match the manifest is not installed", {
  dir <- withr::local_tempdir()
  src <- file.path(dir, "src.vtr")
  vectra::write_vtr(data.frame(ref_id = "a", citation = "A", doi = NA), src)
  good <- list(references = list(url = paste0("file:///", normalizePath(src, winslash = "/")),
                                 content_id = unname(tools::md5sum(src))))
  dest <- file.path(dir, "dest"); dir.create(dest)
  expect_true(suppressMessages(download_enrichment_references(good, dest, verbose = FALSE)))
  expect_true(file.exists(file.path(dest, "src.vtr")))

  bad <- good; bad$references$content_id <- strrep("0", 32)
  dest2 <- file.path(dir, "dest2"); dir.create(dest2)
  expect_warning(ok <- download_enrichment_references(bad, dest2, verbose = FALSE),
                 "not installed")
  expect_false(ok)
  expect_false(file.exists(file.path(dest2, "src.vtr")))
})
