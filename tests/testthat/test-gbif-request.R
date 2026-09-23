# gbif_request() turns a matched name list into a GBIF request. Everything here
# runs offline: the keys come from a stubbed taxify_ids(), and the one test that
# reaches for a backbone uses the bundled example database, whose synthetic IDs
# are exactly the case the key check has to refuse.

# A taxify()-shaped frame carrying the columns gbif_request() reads.
fake_result <- function(backbone = "gbif",
                        input = c("Quercus robur", "Bellis perennis"),
                        accepted_id = c("2878688", "3117424")) {
  data.frame(input_name = input, backbone = backbone,
             accepted_id = accepted_id, stringsAsFactors = FALSE)
}

# What taxify_ids() would return for that frame: Quercus under two keys, one of
# them the pick, Bellis under one.
fake_ids <- function(...) {
  data.frame(
    input_name       = c("Quercus robur", "Quercus robur", "Bellis perennis"),
    backbone         = "gbif",
    accepted_id      = c("2878688", "7911626", "3117424"),
    accepted_name    = c("Quercus robur", "Quercus robur", "Bellis perennis"),
    authorship       = c("L.", "auct.", "L."),
    rank             = "species",
    taxonomic_status = c("ACCEPTED", "DOUBTFUL", "ACCEPTED"),
    family           = c("Fagaceae", "Fagaceae", "Asteraceae"),
    n_occurrences    = c(2000000, 0, 1107989),
    is_pick          = c(TRUE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )
}


test_that("every accepted key is requested, deduplicated, as integers", {
  local_mocked_bindings(taxify_ids = fake_ids)
  keys <- gbif_request(fake_result(), dry_run = TRUE, verbose = FALSE)

  expect_type(keys, "integer")
  expect_equal(as.integer(keys), c(2878688L, 7911626L, 3117424L))
  expect_equal(nrow(attr(keys, "taxa")), 3L)
})


test_that("strict = TRUE requests only the key taxify() reported", {
  local_mocked_bindings(taxify_ids = fake_ids)
  keys <- gbif_request(fake_result(), strict = TRUE, dry_run = TRUE,
                       verbose = FALSE)

  expect_equal(as.integer(keys), c(2878688L, 3117424L))
  expect_true(all(attr(keys, "taxa")$is_pick))
})


test_that("strict = TRUE says what it leaves behind", {
  local_mocked_bindings(taxify_ids = fake_ids)
  msg <- capture_messages(
    gbif_request(fake_result(), strict = TRUE, dry_run = TRUE, verbose = TRUE))
  expect_match(paste(msg, collapse = ""), "drops 1 other key\\(s\\)")
})


test_that("strict is off by default", {
  local_mocked_bindings(taxify_ids = fake_ids)
  expect_equal(formals(gbif_request)$strict, FALSE)
  keys <- gbif_request(fake_result(), dry_run = TRUE, verbose = FALSE)
  expect_length(keys, 3L)
})


test_that("strict rejects a non-logical", {
  expect_error(gbif_request(fake_result(), strict = "pick", dry_run = TRUE),
               "strict must be TRUE or FALSE")
})


test_that("dry_run contacts nothing, so it works without rgbif", {
  local_mocked_bindings(
    taxify_ids = fake_ids,
    require_rgbif = function(...) stop("rgbif must not be required for a dry run")
  )
  expect_no_error(gbif_request(fake_result(), dry_run = TRUE, verbose = FALSE))
})


test_that("the expected record count is reported before a request is sent", {
  local_mocked_bindings(taxify_ids = fake_ids)
  expect_message(
    gbif_request(fake_result(), dry_run = TRUE, verbose = TRUE),
    "3,107,989 occurrence record"
  )
})


test_that("a backbone with no occurrence counts reports no record estimate", {
  no_counts <- function(...) {
    d <- fake_ids()
    d$n_occurrences <- NA_real_
    d
  }
  local_mocked_bindings(taxify_ids = no_counts)
  # The key count is still reported; only the record estimate is withheld.
  msg <- capture_messages(
    gbif_request(fake_result(), dry_run = TRUE, verbose = TRUE))
  expect_match(paste(msg, collapse = ""), "3 GBIF key\\(s\\)")
  expect_false(any(grepl("occurrence record", msg)))
  expect_equal(expected_records_note(no_counts()), "")
})


test_that("names matched by another backbone are dropped, not silently sent", {
  local_mocked_bindings(taxify_ids = fake_ids)
  mixed <- fake_result(backbone = c("gbif", "col"))
  expect_message(
    gbif_request(mixed, dry_run = TRUE, verbose = TRUE),
    "matched by another backbone"
  )
})


test_that("a result with no GBIF rows is refused with the fix in the message", {
  x <- fake_result(backbone = "col")
  expect_error(gbif_request(x, dry_run = TRUE, verbose = FALSE),
               'backbone = "gbif"')
})


test_that("non-GBIF IDs are refused rather than sent as taxon keys", {
  synthetic <- function(...) {
    d <- fake_ids()
    d$accepted_id <- c("gbif-ex-001", "gbif-ex-002", "gbif-ex-003")
    d
  }
  local_mocked_bindings(taxify_ids = synthetic)
  expect_error(gbif_request(fake_result(), dry_run = TRUE, verbose = FALSE),
               "not GBIF taxon keys")
})


test_that("the bundled example database is refused for real", {
  # Not a stub: the example db genuinely carries synthetic IDs, so this is the
  # check firing end to end through taxify().
  old <- options(taxify.data_dir = taxify_example_data())
  withr::defer({ options(old); taxify_clear_cache() })
  taxify_clear_cache()

  expect_error(
    suppressWarnings(gbif_request("Quercus robur", dry_run = TRUE,
                                  verbose = FALSE)),
    "not GBIF taxon keys"
  )
})


test_that("matching arguments are refused when the input is already matched", {
  local_mocked_bindings(taxify_ids = fake_ids)
  expect_error(
    gbif_request(fake_result(), fuzzy = FALSE, dry_run = TRUE, verbose = FALSE),
    "only when x is a character vector"
  )
})


test_that("a download without credentials names the missing variables", {
  withr::local_envvar(GBIF_USER = "", GBIF_PWD = "", GBIF_EMAIL = "")
  expect_error(check_gbif_credentials(), "GBIF_USER, GBIF_PWD, GBIF_EMAIL")
  expect_error(check_gbif_credentials(), 'method = "search"')
})


test_that("credentials present pass the check", {
  withr::local_envvar(GBIF_USER = "u", GBIF_PWD = "p", GBIF_EMAIL = "e@x.org")
  expect_true(check_gbif_credentials())
})


# ---- gbif_backmatch() ----

# Records as GBIF returns them: one identified to the species itself, one to a
# subspecies of it. The subspecies row carries the subspecies key in taxonKey
# and the requested key only in speciesKey, which is the case a taxonKey join
# loses.
fake_records <- function() {
  data.frame(
    scientificName   = c("Quercus robur L.", "Quercus robur subsp. robur",
                         "Something else"),
    taxonKey         = c(2878688L, 9999999L, 123L),
    acceptedTaxonKey = c(2878688L, 9999999L, 123L),
    speciesKey       = c(2878688L, 2878688L, 123L),
    stringsAsFactors = FALSE
  )
}


test_that("a record identified to a descendant still links to its name", {
  taxa <- fake_ids()
  out <- gbif_backmatch(fake_records(), structure(list(), taxa = taxa),
                        verbose = FALSE)

  expect_equal(out$requested_key, c(2878688L, 2878688L, NA_integer_))
  expect_equal(out$input_name,
               c("Quercus robur", "Quercus robur", NA_character_))
  # The naive join would have matched only the first row.
  expect_equal(sum(fake_records()$taxonKey %in% as.integer(taxa$accepted_id)), 1L)
  expect_equal(sum(!is.na(out$input_name)), 2L)
})


test_that("a search result carries its own requested key and uses it", {
  recs <- fake_records()
  recs$taxon_key_requested <- c(2878688L, 2878688L, 7911626L)
  out <- gbif_backmatch(recs, structure(list(), taxa = fake_ids()),
                        verbose = FALSE)
  expect_equal(out$requested_key, c(2878688L, 2878688L, 7911626L))
})


test_that("records matching no requested key are reported, not dropped", {
  expect_message(
    out <- gbif_backmatch(fake_records(), structure(list(), taxa = fake_ids()),
                          verbose = TRUE),
    "1 of 3 record\\(s\\) matched no requested key"
  )
  expect_equal(nrow(out), 3L)
})


test_that("gbif_backmatch accepts a taxify_ids() table directly", {
  out <- gbif_backmatch(fake_records(), fake_ids(), verbose = FALSE)
  expect_equal(sum(!is.na(out$input_name)), 2L)
})


test_that("gbif_backmatch refuses an input it cannot get keys from", {
  expect_error(gbif_backmatch(fake_records(), list(a = 1)),
               "gbif_request\\(\\) result")
  expect_error(gbif_backmatch("not a frame", fake_ids()),
               "must be a data.frame")
})


test_that("an empty record set comes back with the columns added", {
  out <- gbif_backmatch(data.frame(), fake_ids(), verbose = FALSE)
  expect_true(all(c("requested_key", "input_name", "accepted_name") %in% names(out)))
  expect_equal(nrow(out), 0L)
})


# ---- sharding a list too long for one GBIF query ----

test_that("the chunk size stays inside GBIF's 12,000-character query limit", {
  # Measured against occ_download_prep(): 10 characters per key plus 125 of
  # envelope. If either the chunk size or GBIF's limit moves, this catches it.
  chars <- 125 + 10 * taxify:::.gbif_keys_per_query
  expect_lt(chars, 12000)
})


test_that("a list within the limit is one download", {
  submitted <- list()
  local_mocked_bindings(
    occ_download = function(...) { submitted[[length(submitted) + 1L]] <<- 1; "k1" },
    pred_in = function(...) NULL,
    .package = "rgbif")
  out <- gbif_download_keys(1:10, verbose = FALSE)
  expect_equal(out, "k1")
  expect_length(submitted, 1L)
})


test_that("a list over the limit is split and every download key returned", {
  n_chunks <- 0L
  local_mocked_bindings(
    occ_download = function(...) stop("should go through the queue"),
    occ_download_prep = function(...) "req",
    pred_in = function(...) NULL,
    occ_download_queue = function(.list, ...) {
      n_chunks <<- length(.list)
      as.list(paste0("k", seq_along(.list)))
    },
    .package = "rgbif")

  keys <- seq_len(2500)
  expect_message(out <- gbif_download_keys(keys, verbose = TRUE),
                 "splitting into 3 downloads")
  expect_equal(out, c("k1", "k2", "k3"))
  expect_equal(n_chunks, 3L)
})


test_that("cite() reports every DOI when a request was split", {
  local_mocked_bindings(gbif_download_citation = function(key)
    list(text = paste("download", key), doi = paste0("10.15468/dl.", key)))
  x <- data.frame(a = 1)
  attr(x, "gbif_download") <- c("aaa", "bbb")
  out <- capture.output(cite(x))
  expect_true(any(grepl("download aaa", out)))
  expect_true(any(grepl("download bbb", out)))

  bib <- tempfile(fileext = ".bib")
  cite(x, file = bib)
  txt <- paste(readLines(bib), collapse = "\n")
  expect_match(txt, "10\\.15468/dl\\.aaa")
  expect_match(txt, "10\\.15468/dl\\.bbb")
})


# ---- provenance carried to cite() ----

test_that("the backbone provenance travels to the records", {
  local_mocked_bindings(taxify_ids = fake_ids)
  x <- fake_result()
  attr(x, "taxify_meta") <- list(backends = "gbif")

  keys <- gbif_request(x, dry_run = TRUE, verbose = FALSE)
  expect_equal(attr(keys, "taxify_meta"), list(backends = "gbif"))

  out <- gbif_backmatch(fake_records(), keys, verbose = FALSE)
  expect_equal(attr(out, "taxify_meta"), list(backends = "gbif"))
})


test_that("a download key is attached only by the download method", {
  local_mocked_bindings(
    taxify_ids = fake_ids,
    require_rgbif = function(...) invisible(TRUE),
    check_gbif_credentials = function(...) invisible(TRUE),
    gbif_search_keys = function(...) data.frame(x = 1)
  )
  local_mocked_bindings(
    occ_download = function(...) structure("0001-abc", class = "occ_download"),
    pred_in = function(...) NULL,
    .package = "rgbif"
  )
  dl <- gbif_request(fake_result(), method = "download", verbose = FALSE)
  expect_equal(attr(dl, "gbif_download"), "0001-abc")

  sr <- gbif_request(fake_result(), method = "search", verbose = FALSE)
  expect_null(attr(sr, "gbif_download"))
})


test_that("the download key reaches the records through backmatch", {
  src <- structure(list(), taxa = fake_ids(), gbif_download = "0001-abc")
  out <- gbif_backmatch(fake_records(), src, verbose = FALSE)
  expect_equal(attr(out, "gbif_download"), "0001-abc")
})


test_that("cite() reports the GBIF download beside the backbone", {
  local_mocked_bindings(gbif_download_citation = function(key)
    list(text = sprintf("GBIF.org (2026-01-01) ... https://doi.org/10.15468/dl.%s", key),
         doi = "10.15468/dl.test"))
  x <- data.frame(a = 1)
  attr(x, "gbif_download") <- "abc"
  expect_output(cite(x), "10\\.15468/dl\\.abc")
})


test_that("cite() still refuses an object with no provenance at all", {
  expect_error(cite(data.frame(a = 1)), "taxify_meta")
})


test_that("a download with no DOI yet is reported as such, not as a citation", {
  local_mocked_bindings(
    occ_download_meta = function(key) list(status = "RUNNING", doi = NULL),
    .package = "rgbif")
  cit <- gbif_download_citation("0001-abc")
  expect_true(is.na(cit$doi))
  expect_match(cit$text, "No DOI yet")
})


test_that("an unreachable GBIF degrades to no download citation", {
  local_mocked_bindings(
    occ_download_meta = function(key) stop("offline"),
    .package = "rgbif")
  expect_null(gbif_download_citation("0001-abc"))
})


test_that("a missing rgbif is reported with an install instruction", {
  local_mocked_bindings(requireNamespace = function(...) FALSE,
                        .package = "base")
  expect_error(require_rgbif("gbif_request()"), "install.packages")
})
