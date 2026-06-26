# A taxify_result fixture (as taxify() would return), for the result-input path.
make_fake_result <- function() {
  res <- data.frame(
    input_name        = c("Quercus robur", "Quercus robus", "Bogusus fakus",
                          "Panthera leo", "Acer pseudoplatanus"),
    matched_name      = c("Quercus robur", "Quercus robur", NA,
                          "Panthera leo", "Acer pseudoplatanus"),
    accepted_name     = c("Quercus robur", "Quercus robur", NA,
                          "Panthera leo", "Acer pseudoplatanus"),
    match_type        = c("exact", "fuzzy", "none", "exact", "exact"),
    fuzzy_dist        = c(NA, 0.08, NA, NA, NA),
    is_synonym        = c(FALSE, FALSE, FALSE, FALSE, TRUE),
    is_ambiguous      = c(FALSE, FALSE, FALSE, TRUE, FALSE),
    ambiguous_targets = c(NA, NA, NA, "123|456", NA),
    backend           = c("wfo", "wfo", NA, "col", "wfo"),
    stringsAsFactors  = FALSE
  )
  class(res) <- c("taxify_result", "data.frame")
  res
}

# Run inspect() against an empty data dir (deterministic offline) with verbose off.
inspect_offline <- function(x, ...) {
  dd <- tempfile("taxify_empty_dd_")
  dir.create(dd)
  old <- options(taxify.data_dir = dd)
  on.exit({ options(old); unlink(dd, recursive = TRUE) }, add = TRUE)
  inspect(x, ..., verbose = FALSE)
}

# Install a controlled genus register for the duration of `code`.
with_fake_register <- function(genera, code, kingdom_group = NA_character_) {
  old <- .taxify_env$register
  .taxify_env$register <- data.frame(
    genus         = genera,
    kingdom_group = rep_len(kingdom_group, length(genera)),
    stringsAsFactors = FALSE
  )
  on.exit(.taxify_env$register <- old, add = TRUE)
  force(code)
}

# Run `code` with no register available (NULL cache + empty data dir).
with_no_register <- function(code) {
  old <- .taxify_env$register
  .taxify_env$register <- NULL
  dd  <- tempfile("taxify_empty_dd_"); dir.create(dd)
  oldopt <- options(taxify.data_dir = dd)
  on.exit({
    .taxify_env$register <- old
    options(oldopt)
    unlink(dd, recursive = TRUE)
  }, add = TRUE)
  force(code)
}


# ---- result-input path: match-derived labels ----

test_that("inspecting a result keeps anomalous rows, drops the clean match", {
  out <- with_fake_register(
    c("Quercus", "Panthera", "Acer"),    # Bogusus is in no backbone
    inspect_offline(make_fake_result())
  )
  expect_s3_class(out, "taxify_inspection")
  expect_false("Quercus robur" %in% out$input_name)
  expect_setequal(out$input_name,
                  c("Quercus robus", "Bogusus fakus",
                    "Panthera leo", "Acer pseudoplatanus"))
})


test_that("a fuzzy result row is a typo with the corrected name", {
  res <- data.frame(
    input_name    = c("Quercus robus", "Pinus sylvestris"),
    matched_name  = c("Quercus robur", "Pinus sylvestris"),
    accepted_name = c("Quercus robur", "Pinus sylvestris"),
    match_type    = c("fuzzy", "exact"),
    fuzzy_dist    = c(0.08, NA),
    is_synonym    = c(FALSE, FALSE),
    is_ambiguous  = c(FALSE, FALSE),
    ambiguous_targets = c(NA, NA),
    backend       = c("wfo", "wfo"),
    stringsAsFactors = FALSE
  )
  class(res) <- c("taxify_result", "data.frame")

  out <- with_no_register(inspect(res, verbose = FALSE))
  expect_equal(out$input_name, "Quercus robus")
  expect_equal(out$anomalies, "typo")
  expect_equal(out$suggestion, "Quercus robur")
  expect_equal(as.character(out$tier), "review")
  expect_match(out$reason, "misspelling")
  expect_equal(out$fuzzy_dist, 0.08)
})


test_that("inspect labels each result signal with the right anomaly and tier", {
  out  <- with_fake_register(
    c("Quercus", "Panthera", "Acer"),
    inspect_offline(make_fake_result())
  )
  flag <- stats::setNames(out$anomalies, out$input_name)
  tier <- stats::setNames(as.character(out$tier), out$input_name)

  expect_equal(flag[["Quercus robus"]],       "typo")
  expect_equal(flag[["Bogusus fakus"]],       "unknown")
  expect_equal(flag[["Panthera leo"]],        "ambiguous")
  expect_equal(flag[["Acer pseudoplatanus"]], "synonym")

  expect_equal(tier[["Bogusus fakus"]],       "unresolved")
  expect_equal(tier[["Quercus robus"]],       "review")
  expect_equal(tier[["Panthera leo"]],        "review")
  expect_equal(tier[["Acer pseudoplatanus"]], "note")
})


test_that("inspect orders most-notable first", {
  out <- with_fake_register(
    c("Quercus", "Panthera", "Acer"),
    inspect_offline(make_fake_result())
  )
  expect_false(is.unsorted(rev(as.integer(out$tier))))
  expect_equal(as.character(out$tier[1]), "unresolved")
})


test_that("suggestion holds the accepted name, NA when unknown", {
  out <- with_fake_register(
    c("Quercus", "Panthera", "Acer"),
    inspect_offline(make_fake_result())
  )
  sug <- stats::setNames(out$suggestion, out$input_name)
  expect_equal(sug[["Quercus robus"]],       "Quercus robur")
  expect_equal(sug[["Acer pseudoplatanus"]], "Acer pseudoplatanus")
  expect_true(is.na(sug[["Bogusus fakus"]]))
})


test_that("min_tier narrows the report", {
  out <- with_fake_register(
    c("Quercus", "Panthera", "Acer"),
    inspect_offline(make_fake_result(), min_tier = "unresolved")
  )
  expect_equal(out$input_name, "Bogusus fakus")

  out_rev <- with_fake_register(
    c("Quercus", "Panthera", "Acer"),
    inspect_offline(make_fake_result(), min_tier = "review")
  )
  expect_setequal(out_rev$input_name,
                  c("Bogusus fakus", "Quercus robus", "Panthera leo"))
})


test_that("inspect does not modify the input result", {
  res    <- make_fake_result()
  before <- res
  out    <- with_no_register(inspect(res, verbose = FALSE))
  expect_identical(res, before)
  expect_false(identical(out, res))
})


test_that("a row can carry several anomalies at once", {
  res <- make_fake_result()
  res$is_synonym[2] <- TRUE          # the fuzzy row is also a synonym
  out  <- with_no_register(inspect(res, verbose = FALSE))
  flag <- out$anomalies[out$input_name == "Quercus robus"]
  expect_true(grepl("typo", flag) && grepl("synonym", flag))
  expect_equal(as.character(out$tier[out$input_name == "Quercus robus"]),
               "review")
})


# ---- inspect() does no matching itself ----

test_that("inspect does not match a character vector by default", {
  x <- c(rep("Mysticus ignotus", 5L), "Mysticus ignatus")
  out <- with_mocked_bindings(
    taxify = function(...) stop("inspect must not call taxify by default"),
    with_no_register(inspect(x, verbose = FALSE))
  )
  row <- out[out$input_name == "Mysticus ignatus", ]
  expect_match(row$anomalies, "near_duplicate")
  expect_equal(row$suggestion, "Mysticus ignotus")
})


test_that("backbones = TRUE matches against all installed backbones", {
  seen <- NULL
  with_mocked_bindings(
    installed_backbones = function() c("wfo", "col"),
    taxify = function(x, ..., backend = NULL) {
      seen <<- backend
      structure(
        data.frame(input_name = x, match_type = "exact", accepted_name = x,
                   matched_name = x, fuzzy_dist = NA, is_synonym = FALSE,
                   is_ambiguous = FALSE, ambiguous_targets = NA,
                   backend = "wfo", stringsAsFactors = FALSE),
        class = c("taxify_result", "data.frame")
      )
    },
    with_no_register(inspect(c("Aaa bbb", "Ccc ddd"), backbones = TRUE,
                             verbose = FALSE))
  )
  expect_equal(seen, c("wfo", "col"))
})


test_that("backbones = TRUE warns and degrades when none are installed", {
  expect_warning(
    out <- with_mocked_bindings(
      installed_backbones = function() character(0L),
      taxify = function(...) stop("must not be called"),
      with_no_register(inspect(c("Aaa bbb", "Ccc ddd"), backbones = TRUE,
                               verbose = FALSE))
    ),
    "none are installed"
  )
  expect_s3_class(out, "taxify_inspection")
})


test_that("the report header records which backbones were used", {
  none <- with_no_register(inspect(c("Aaa bbb", "Ccc ddd"), verbose = FALSE))
  txt  <- paste(capture.output(print(none)), collapse = "\n")
  expect_match(txt, "backbones: none")

  matched <- with_no_register(inspect(make_fake_result(), verbose = FALSE))
  txt2 <- paste(capture.output(print(matched)), collapse = "\n")
  expect_match(txt2, "backbones: .*wfo")
})


# ---- register check (genus recognition), needs no matching ----

test_that("inspect flags an unknown genus from the register alone", {
  out <- with_fake_register(
    c("Quercus"),
    inspect_offline(c("Quercus robur", "Bogusus fakus"))
  )
  expect_equal(out$input_name, "Bogusus fakus")
  expect_equal(out$anomalies, "unknown")
  expect_equal(as.character(out$tier), "unresolved")
  expect_match(out$reason, "not in the taxonomic register")
})


test_that("a recognised genus that was not matched is not flagged", {
  # Genus in the register, name unresolved: absence of a match is not an anomaly.
  res <- make_fake_result()
  res$match_type[3] <- "none"   # Bogusus fakus
  out <- with_fake_register(
    c("Quercus", "Panthera", "Acer", "Bogusus"),
    inspect_offline(res)
  )
  expect_false("Bogusus fakus" %in% out$input_name)
})


test_that("without a register, the genus-recognition check is skipped", {
  out <- with_no_register(inspect(c("Quercus robur", "Bogusus fakus"),
                                  verbose = FALSE))
  expect_false("Bogusus fakus" %in% out$input_name)
})


# ---- near-duplicate (backbone-free) ----

test_that("near_duplicate flags the rare spelling against a frequent twin", {
  x <- c(rep("Carexus mysteriosa", 6L), "Carexus mysteryosa")
  out <- with_no_register(inspect(x, verbose = FALSE))
  expect_equal(out$input_name, "Carexus mysteryosa")
  expect_match(out$anomalies, "near_duplicate")
  expect_equal(out$suggestion, "Carexus mysteriosa")
  expect_false("Carexus mysteriosa" %in% out$input_name)
})


test_that("equal-frequency near twins give no near_duplicate", {
  x <- c("Carexus mysteriosa", "Carexus mysteryosa")
  out <- with_no_register(inspect(x, verbose = FALSE))
  expect_false(any(grepl("near_duplicate", out$anomalies)))
})


# ---- single name ----

test_that("inspecting a single name warns that list checks need a batch", {
  res <- data.frame(
    input_name = "Quercus robus", matched_name = "Quercus robur",
    accepted_name = "Quercus robur", match_type = "fuzzy", fuzzy_dist = 0.08,
    is_synonym = FALSE, is_ambiguous = FALSE, ambiguous_targets = NA,
    backend = "wfo", stringsAsFactors = FALSE
  )
  class(res) <- c("taxify_result", "data.frame")

  expect_warning(out <- with_no_register(inspect(res, verbose = FALSE)),
                 "single name|batch")
  expect_equal(out$anomalies, "typo")
})


test_that("a batch does not trigger the single-name warning", {
  expect_silent(with_no_register(inspect(make_fake_result(), verbose = FALSE)))
})


# ---- kingdom-group outlier (register-derived) ----

test_that("outlier_group flags the lone kingdom among a coherent list", {
  res <- data.frame(
    input_name    = c(paste("Plantgenus", letters[1:6]), "Pieris napi"),
    matched_name  = c(paste("Plantgenus", letters[1:6]), "Pieris napi"),
    accepted_name = c(paste("Plantgenus", letters[1:6]), "Pieris napi"),
    match_type    = rep("exact", 7L),
    fuzzy_dist    = rep(NA_real_, 7L),
    is_synonym    = rep(FALSE, 7L),
    is_ambiguous  = rep(FALSE, 7L),
    ambiguous_targets = rep(NA_character_, 7L),
    kingdom_group = c(rep("plantae", 6L), "animalia"),
    backend       = rep("gbif", 7L),
    stringsAsFactors = FALSE
  )
  class(res) <- c("taxify_result", "data.frame")

  out <- with_no_register(inspect(res, verbose = FALSE))
  expect_equal(out$input_name, "Pieris napi")
  expect_match(out$anomalies, "outlier_group")
  expect_match(out$reason, "plantae")
  expect_equal(as.character(out$tier), "review")
})


test_that("a genuinely mixed list raises no outlier_group flag", {
  res <- data.frame(
    input_name    = paste("Genus", letters[1:8]),
    matched_name  = paste("Genus", letters[1:8]),
    accepted_name = paste("Genus", letters[1:8]),
    match_type    = rep("exact", 8L),
    fuzzy_dist    = rep(NA_real_, 8L),
    is_synonym    = rep(FALSE, 8L),
    is_ambiguous  = rep(FALSE, 8L),
    ambiguous_targets = rep(NA_character_, 8L),
    kingdom_group = rep(c("plantae", "animalia"), each = 4L),
    backend       = rep("gbif", 8L),
    stringsAsFactors = FALSE
  )
  class(res) <- c("taxify_result", "data.frame")

  out <- with_no_register(inspect(res, verbose = FALSE))
  expect_false(any(grepl("outlier_group", out$anomalies)))
})


# ---- range / geographic ----

test_that("out_of_range flags a species off the list's main continents", {
  euro <- c("Quercus robur", "Fagus sylvatica", "Betula pendula",
            "Acer campestre", "Tilia cordata", "Carpinus betulus")
  res <- data.frame(
    input_name    = c(euro, "Eucalyptus globulus"),
    matched_name  = c(euro, "Eucalyptus globulus"),
    accepted_name = c(euro, "Eucalyptus globulus"),
    match_type    = rep("exact", 7L),
    fuzzy_dist    = rep(NA_real_, 7L),
    is_synonym    = rep(FALSE, 7L),
    is_ambiguous  = rep(FALSE, 7L),
    ambiguous_targets = rep(NA_character_, 7L),
    kingdom_group = rep("plantae", 7L),
    backend       = rep("gbif", 7L),
    stringsAsFactors = FALSE
  )
  class(res) <- c("taxify_result", "data.frame")

  cmap <- stats::setNames(
    as.list(c(rep("1", 6L), "5")),     # Europe = "1", Australasia = "5"
    c(euro, "Eucalyptus globulus")
  )
  out <- with_no_register(with_mocked_bindings(
    species_range_continents = function(accepted_names, verbose = FALSE) cmap,
    inspect(res, verbose = FALSE)
  ))
  row <- out[out$input_name == "Eucalyptus globulus", ]
  expect_match(row$anomalies, "out_of_range")
  expect_match(row$reason, "Europe", ignore.case = TRUE)
  expect_false("Quercus robur" %in% out$input_name)
})


test_that("a globally spread list raises no out_of_range flag", {
  nm <- paste("Genus", letters[1:6])
  res <- data.frame(
    input_name = nm, matched_name = nm, accepted_name = nm,
    match_type = rep("exact", 6L), fuzzy_dist = rep(NA_real_, 6L),
    is_synonym = rep(FALSE, 6L), is_ambiguous = rep(FALSE, 6L),
    ambiguous_targets = rep(NA_character_, 6L),
    kingdom_group = rep("plantae", 6L), backend = rep("gbif", 6L),
    stringsAsFactors = FALSE
  )
  class(res) <- c("taxify_result", "data.frame")

  cmap <- stats::setNames(as.list(c("1", "2", "3", "5", "7", "8")), nm)
  out <- with_no_register(with_mocked_bindings(
    species_range_continents = function(accepted_names, verbose = FALSE) cmap,
    inspect(res, verbose = FALSE)
  ))
  expect_false(any(grepl("out_of_range", out$anomalies)))
})


test_that("geographic flag fires for an in-backbone but out-of-region match", {
  res <- make_fake_result()
  sets <- list(present  = "Quercus robur",
               has_data = c("Quercus robur", "Acer pseudoplatanus"))
  out <- with_no_register(with_mocked_bindings(
    region_range_sets = function(...) sets,
    inspect(res, region = "BEL", verbose = FALSE)
  ))
  flag <- out$anomalies[out$input_name == "Acer pseudoplatanus"]
  expect_true(grepl("geographic", flag))
  expect_false("Quercus robur" %in% out$input_name)
})


test_that("no geographic check without a region", {
  out <- with_no_register(inspect(make_fake_result(), verbose = FALSE))
  expect_false(any(grepl("geographic", out$anomalies)))
})


# ---- end to end ----

test_that("taxify() |> inspect() flags a fuzzy match as a typo", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  res <- taxify(c("Quercus robur", "Quercus robus"), verbose = FALSE)
  out <- inspect(res, verbose = FALSE)
  row <- out[out$input_name == "Quercus robus", ]
  expect_equal(nrow(row), 1L)
  expect_match(row$anomalies, "typo")
  expect_equal(row$suggestion, "Quercus robur")
})
