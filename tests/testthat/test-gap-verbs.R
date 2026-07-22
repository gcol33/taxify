# parse_name(), upstream(), sci2comm(), reconcile(), taxify_lock()/restore(),
# and the authorship-aware homonym tiebreak, run against the bundled example
# database and the mock backbone fixture.

backbone_ready <- function(be) {
  file.exists(file.path(taxify_example_data(), be, "latest", paste0(be, ".vtr")))
}
enrichment_ready <- function(name) {
  file.exists(file.path(taxify_example_data(), "enrichment", name, "latest",
                        paste0(name, ".vtr")))
}


# ---- parse_name() (pure, no backbone) ----

test_that("parse_name() decomposes a binomial with authorship", {
  p <- parse_name("Quercus robur L.")
  expect_equal(p$genus, "Quercus")
  expect_equal(p$specific_epithet, "robur")
  expect_equal(p$authorship, "L.")
  expect_equal(p$rank, "species")
  expect_equal(p$canonical, "Quercus robur")
  expect_true(is.na(p$qualifier))
  expect_false(p$is_hybrid)
})

test_that("parse_name() splits an infraspecific name", {
  p <- parse_name("Poa annua var. annua")
  expect_equal(p$infrasp_rank, "var.")
  expect_equal(p$infrasp_epithet, "annua")
  expect_equal(p$specific_epithet, "annua")
  expect_equal(p$rank, "infraspecies")
  expect_true(is.na(p$qualifier))
})

test_that("parse_name() flags qualifiers, abbreviations, and hybrids", {
  p <- parse_name(c("Pinus cf. sylvestris", "Q. robur",
                    "Salix alba x Salix fragilis"))
  expect_equal(nrow(p), 3L)
  expect_equal(p$qualifier[1], "cf.")
  expect_equal(p$genus[1], "Pinus")
  expect_equal(p$genus[2], "Q.")
  expect_equal(p$specific_epithet[2], "robur")
  expect_true(p$is_hybrid[3])
  expect_equal(p$hybrid_type[3], "formula")
  expect_equal(p$rank[3], "hybrid_formula")
  expect_true(is.na(p$canonical[3]))
})

test_that("parse_name() handles a parenthesized basionym author", {
  p <- parse_name("Picea abies (L.) H.Karst.")
  expect_equal(p$genus, "Picea")
  expect_equal(p$specific_epithet, "abies")
  expect_match(p$authorship, "L\\.")
  expect_match(p$authorship, "Karst")
})

test_that("parse_name() returns an empty frame for empty input", {
  p <- parse_name(character(0L))
  expect_equal(nrow(p), 0L)
  expect_true(all(c("genus", "authorship", "canonical") %in% names(p)))
})


# ---- upstream() ----

test_that("upstream() returns the lineage above a species", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("reptiledb"), "reptiledb example backbone missing")

  u <- upstream("Naja naja", backbone = "reptiledb", verbose = FALSE)
  expect_true(all(c("input_name", "accepted_name", "rank", "name", "backbone")
                  %in% names(u)))
  expect_true("genus" %in% u$rank)
  expect_equal(u$name[u$rank == "genus"], "Naja")
  # The species' own rank is never among the ancestors.
  expect_false("species" %in% u$rank)
  # Ordered coarse -> fine.
  expect_equal(u$rank, u$rank[order(match(u$rank,
    c("kingdom", "phylum", "class", "order", "family", "genus")))])
})

test_that("upstream(to=) restricts to one rank", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("reptiledb"), "reptiledb example backbone missing")

  u <- upstream("Naja naja", backbone = "reptiledb", to = "family",
                verbose = FALSE)
  expect_equal(nrow(u), 1L)
  expect_equal(u$rank, "family")
})

test_that("upstream() is empty for an unresolved taxon", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("reptiledb"), "reptiledb example backbone missing")

  expect_equal(nrow(upstream("Notagenus imaginus", backbone = "reptiledb",
                             verbose = FALSE)), 0L)
})


# ---- sci2comm() ----

test_that("sci2comm() returns the vernacular names of a scientific name", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(enrichment_ready("common_names"), "common_names example missing")

  r <- sci2comm("Quercus robur", resolve = FALSE, verbose = FALSE)
  expect_s3_class(r, "data.frame")
  expect_setequal(names(r),
                  c("input_name", "accepted_name", "common_name", "lang"))
  expect_true("example_common_name" %in% r$common_name)
  expect_setequal(r$lang, c("en", "de"))
})

test_that("sci2comm() honours the lang filter and is a clean inverse", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(enrichment_ready("common_names"), "common_names example missing")

  r <- sci2comm("Quercus robur", lang = "en", resolve = FALSE, verbose = FALSE)
  expect_equal(nrow(r), 1L)
  expect_equal(r$lang, "en")
  expect_equal(nrow(sci2comm("Nothing here", resolve = FALSE, verbose = FALSE)),
               0L)
})


# ---- reconcile() ----

test_that("reconcile() classifies a checklist against current treatment", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("reptiledb"), "reptiledb example backbone missing")

  # Amphibolurus vitticeps is a synonym of Pogona vitticeps in the example db.
  r <- reconcile(c("Pogona vitticeps", "Amphibolurus vitticeps",
                   "Pogona vitticep", "Notagenus imaginus"),
                 backbone = "reptiledb", verbose = FALSE)
  st <- stats::setNames(r$status, r$input_name)
  expect_equal(unname(st["Pogona vitticeps"]), "unchanged")
  expect_equal(unname(st["Amphibolurus vitticeps"]), "synonym")
  expect_equal(unname(st["Pogona vitticep"]), "misspelling")
  expect_equal(unname(st["Notagenus imaginus"]), "unresolved")

  # The three that resolve to Pogona vitticeps are flagged as merged together.
  merged <- stats::setNames(r$merged, r$input_name)
  expect_true(unname(merged["Pogona vitticeps"]))
  expect_true(unname(merged["Amphibolurus vitticeps"]))
  expect_false(unname(merged["Notagenus imaginus"]))
})

test_that("reconcile() does not report a case variant as a merge (#11)", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  # A name paired with its own upper-cased variant is one input, not a
  # many-to-one merge.
  r <- reconcile(c("Quercus robur", "QUERCUS ROBUR"), backbone = "wfo",
                 verbose = FALSE)
  expect_false(any(r$merged))
  expect_true(all(r$status == "unchanged"))
})


# ---- taxify_lock() / taxify_restore() ----

test_that("taxify_lock() captures the backbones behind a result", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  res  <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
  lock <- taxify_lock(res)
  expect_true(is.list(lock))
  expect_true(!is.null(lock$taxify_version))
  bb_names <- vapply(lock$backbones, function(b) b$name, character(1L))
  expect_true("wfo" %in% bb_names)
})

test_that("taxify_lock() round-trips through a file and restore() reports", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  res  <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
  f    <- tempfile(fileext = ".json")
  on.exit(unlink(f), add = TRUE)
  taxify_lock(res, file = f, verbose = FALSE)
  expect_true(file.exists(f))

  rep <- taxify_restore(f, verbose = FALSE)
  expect_s3_class(rep, "data.frame")
  expect_true("wfo" %in% rep$component)
  expect_true(all(c("component", "type", "status") %in% names(rep)))
  # Against the same install, nothing has drifted.
  expect_true(all(rep$status[rep$component == "wfo"] == "ok"))
})

test_that("taxify_restore() reports content, version, and missing drift", {
  # A staged install with a known version and content id, so a lockfile can
  # differ from it in exactly one field at a time.
  dd <- tempfile("taxlock_")
  dir.create(file.path(dd, "wfo", "latest"), recursive = TRUE)
  vectra::write_vtr(data.frame(canonical_name = "Quercus robur",
                               stringsAsFactors = FALSE),
                    file.path(dd, "wfo", "latest", "wfo.vtr"))
  jsonlite::write_json(list(version = "2026.06", content_id = "aaaaaaaaaa"),
                       file.path(dd, "wfo", "latest", "meta.json"),
                       pretty = TRUE, auto_unbox = TRUE)
  old <- options(taxify.data_dir = dd)
  on.exit({ options(old); unlink(dd, recursive = TRUE) }, add = TRUE)
  taxify_clear_cache()

  pin <- function(name, version, content_id) {
    list(backbones = list(list(name = name, version = version,
                              content_id = content_id)),
         enrichments = list())
  }

  # The lock matches the staged install on both identities.
  ok <- taxify_restore(pin("wfo", "2026.06", "aaaaaaaaaa"), verbose = FALSE)
  expect_equal(ok$component, "wfo")
  expect_equal(ok$status, "ok")

  # Same version, different bytes: a same-tag republish.
  cd <- taxify_restore(pin("wfo", "2026.06", "bbbbbbbbbb"), verbose = FALSE)
  expect_equal(cd$status, "content_drift")
  expect_equal(cd$locked_content_id, "bbbbbbbbbb")
  expect_equal(cd$installed_content_id, "aaaaaaaaaa")

  # An older locked version with no content id to compare.
  vd <- taxify_restore(pin("wfo", "2026.05", NA_character_), verbose = FALSE)
  expect_equal(vd$status, "version_drift")
  expect_equal(vd$locked_version, "2026.05")
  expect_equal(vd$installed_version, "2026.06")

  # A backbone the lock pins but this install does not carry.
  ms <- taxify_restore(pin("worms", "2026.06", "aaaaaaaaaa"), verbose = FALSE)
  expect_equal(ms$component, "worms")
  expect_equal(ms$status, "missing")
})

test_that(".restore_status() reports unverified and locked-vs-unknown drift", {
  # Neither a version nor a content id on either side: installed but
  # unverifiable, never a false "ok".
  expect_equal(.restore_status(NA, NA, NA, NA, installed = TRUE), "unverified")

  # A version was locked but the install exposes none: cannot be shown to
  # match, so not "ok".
  st <- .restore_status("1.0", NA, NA, NA, installed = TRUE)
  expect_false(st == "ok")
  expect_true(st %in% c("version_drift", "unverified"))

  # Matching versions on both sides is still "ok"; not installed is "missing".
  expect_equal(.restore_status("1.0", NA, "1.0", NA, installed = TRUE), "ok")
  expect_equal(.restore_status("1.0", NA, "9.9", NA, installed = TRUE),
               "version_drift")
  expect_equal(.restore_status("1.0", NA, "1.0", NA, installed = FALSE),
               "missing")
})

test_that(".restore_status() tolerates a zero-length lock field", {
  # jsonlite emits a zero-length vector for an empty JSON field; it must not
  # error, and must degrade to a reported status.
  expect_error(.restore_status(character(0), NA, "1.0", NA, installed = TRUE), NA)
  st <- .restore_status(character(0), NA, "1.0", NA, installed = TRUE)
  expect_true(st %in% c("unverified", "version_drift"))
})

test_that("summary() tolerates an enrichment entry with no version field", {
  res  <- data.frame(query = "x", accepted_name = "x", matched_name = "x",
                     stringsAsFactors = FALSE)
  meta <- list(
    backbone         = "wfo",
    n_input         = 1L,
    match_tally     = list(exact = 1L),
    life_form_tally = data.frame(taxon_group = character(0L), n = integer(0L),
                                 stringsAsFactors = FALSE),
    enrichments     = list(list(
      name = "demo", source = "Demo source", license = NA_character_,
      n_matched = 1L, n_total = 1L   # deliberately no `version` field
    ))
  )
  attr(res, "taxify_meta") <- meta
  class(res) <- c("taxify_result", "data.frame")
  expect_error(capture.output(summary(res)), NA)
})


# ---- authorship-aware homonym disambiguation ----

test_that("authorship resolves a homonym the query names an author for", {
  be <- wfo_backend()
  bb <- mock_backbone_vtr()

  # Three "Pinus abies" homonyms: Thunb. -> Picea polita (wfo-0000019),
  # L. -> wfo-0000005, Lour. -> Cunninghamia (wfo-0000022). Bare name is
  # ambiguous; the author picks one.
  res <- match_exact(be, clean_names("Pinus abies L."), bb)
  expect_true(res$is_ambiguous[1L])

  out <- disambiguate_by_authorship(res, bb)
  expect_false(out$is_ambiguous[1L])
  expect_equal(out$accepted_id[1L], "wfo-0000005")

  res2 <- match_exact(be, clean_names("Pinus abies Thunb."), bb)
  out2 <- disambiguate_by_authorship(res2, bb)
  expect_false(out2$is_ambiguous[1L])
  expect_equal(out2$accepted_id[1L], "wfo-0000019")
  expect_equal(out2$accepted_name[1L], "Picea polita")
  # The genus/family must be the ACCEPTED taxon's (Picea polita), not the
  # rejected synonym row's own (Pinus abies -> genus Pinus).
  expect_equal(out2$genus[1L], "Picea")
  expect_equal(out2$family[1L], "Pinaceae")
})

test_that("a bare homonym (no author) stays ambiguous", {
  be <- wfo_backend()
  bb <- mock_backbone_vtr()
  res <- match_exact(be, clean_names("Pinus abies"), bb)
  expect_true(res$is_ambiguous[1L])
  out <- disambiguate_by_authorship(res, bb)
  expect_true(out$is_ambiguous[1L])
})
