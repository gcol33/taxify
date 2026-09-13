# Every exported single-source door, parametrised over the namespace rather
# than a hand-kept list, so a door added without a test is covered the moment
# it is exported (#75). Each door is run twice. The first run swaps
# enrich_simple() for a recorder, which yields the enrichment key and column map
# the door declares; the second stages a mock .vtr carrying exactly those source
# columns (plus one column the door does not map) and runs the real door against
# it. test-doors.R keeps the value-level checks against the bundled fixtures.

# Doors with the plain (x, [cols], verbose) shape. Grouped doors take a group
# argument (country, region, lang, group) and the info/verb doors are not
# enrichment joins, so the signature is what selects the set.
single_source_doors <- function() {
  ex <- grep("^add_", getNamespaceExports("taxify"), value = TRUE)
  ok <- vapply(ex, function(nm) {
    f <- names(formals(get(nm, envir = asNamespace("taxify"))))
    identical(f, c("x", "cols", "verbose")) || identical(f, c("x", "verbose"))
  }, logical(1L))
  sort(setdiff(ex[ok], "add_pignatti"))    # scrape-on-demand, no .vtr
}

# Doors that read their column map off the .vtr schema before joining need a
# schema to read.
door_schema_seed <- list(
  add_gift = function() {
    df <- data.frame(canonical_name = "Aaa bbb", stringsAsFactors = FALSE)
    for (cc in taxify:::.gift_default_cols) df[[cc]] <- 1
    list(gift = df)
  }
)

# The enrich_simple() calls a door makes, with every argument resolved.
record_door_calls <- function(door, seed = NULL) {
  if (!is.null(seed)) {
    for (nm in names(seed)) install_mock_enrichment(nm, seed[[nm]])
  }
  calls <- list()
  rec <- function() {
    a <- mget(names(formals(sys.function())), envir = environment())
    calls[[length(calls) + 1L]] <<- a
    a$x
  }
  formals(rec) <- formals(taxify:::enrich_simple)
  x <- data.frame(accepted_name = "Aaa bbb", genus = "Aaa",
                  stringsAsFactors = FALSE)
  testthat::with_mocked_bindings(
    tryCatch(door(x, verbose = FALSE), error = function(e) NULL),
    enrich_simple = rec
  )
  calls
}

door_mock_frame <- function(call) {
  src <- unique(unname(call$col_map))
  df  <- data.frame(canonical_name = "Aaa bbb", genus = "Aaa",
                    stringsAsFactors = FALSE)
  for (s in setdiff(src, names(df))) df[[s]] <- 1
  df$zz_unmapped_trait <- 2
  df
}

door_calls <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) {
      doors <- single_source_doors()
      cache <<- stats::setNames(lapply(doors, function(d)
        record_door_calls(get(d, envir = asNamespace("taxify")),
                          seed = if (!is.null(door_schema_seed[[d]]))
                            door_schema_seed[[d]]())), doors)
    }
    cache
  }
})

test_that("every single-source door is found and declares its join", {
  calls <- door_calls()
  expect_gt(length(calls), 90L)
  for (d in names(calls)) {
    expect_gt(length(calls[[d]]), 0L, label = paste0(d, " calls enrich_simple()"))
  }
})

test_that("every door's enrichment key resolves to a published or build-only source", {
  mf <- taxify:::local_manifest()
  known <- c(names(mf$enrichments), taxify:::.build_only_enrichments())
  for (d in names(door_calls())) {
    for (cl in door_calls()[[d]]) {
      expect_true(cl$enrichment_name %in% known,
                  info = paste0(d, ": key '", cl$enrichment_name, "'"))
    }
  }
})

test_that("a door's column prefix is a whole token that its curated columns carry", {
  # col_prefix = "sid" pasted onto "thousand_seed_weight" gives
  # "sidthousand_seed_weight", so no unprefixed name could be selected (#74).
  for (d in names(door_calls())) {
    for (cl in door_calls()[[d]]) {
      p <- cl$col_prefix
      if (is.null(p)) next
      expect_match(p, "_$", info = d)
      expect_true(all(startsWith(names(cl$col_map), p)),
                  info = paste0(d, ": curated columns carry '", p, "'"))
    }
  }
})

test_that("every door attaches, selects and handles an empty input on a mock", {
  x <- data.frame(accepted_name = "Aaa bbb", genus = "Aaa",
                  stringsAsFactors = FALSE)
  for (d in names(door_calls())) {
    door  <- get(d, envir = asNamespace("taxify"))
    calls <- door_calls()[[d]]
    for (cl in calls) install_mock_enrichment(cl$enrichment_name,
                                              door_mock_frame(cl))
    has_cols <- "cols" %in% names(formals(door))

    out <- door(x, verbose = FALSE)
    expect_s3_class(out, "data.frame")
    expect_equal(nrow(out), 1L, info = d)
    # A door joining two sources (add_combine) folds them into its own columns,
    # so only a single join is held to its declared column names.
    if (length(calls) == 1L) {
      cl <- calls[[1L]]
      curated <- if (is.null(cl$default_cols)) names(cl$col_map) else
        intersect(cl$default_cols, names(cl$col_map))
      expect_true(all(curated %in% names(out)),
                  info = paste0(d, ": attaches ", paste(setdiff(curated, names(out)),
                                                         collapse = ", ")))
    } else {
      expect_gt(ncol(out), ncol(x))
    }

    empty <- door(x[0L, , drop = FALSE], verbose = FALSE)
    expect_equal(nrow(empty), 0L, info = paste0(d, ": 0-row input"))

    if (!has_cols || length(calls) != 1L) next
    cl <- calls[[1L]]

    all_out <- door(x, cols = "all", verbose = FALSE)
    expect_gte(ncol(all_out), ncol(out))

    # One curated column, written without the door's prefix.
    first <- names(cl$col_map)[1L]
    bare  <- if (is.null(cl$col_prefix)) first else
      sub(paste0("^", cl$col_prefix), "", first)
    one <- tryCatch(door(x, cols = bare, verbose = FALSE),
                    error = function(e) conditionMessage(e))
    expect_true(is.data.frame(one) && first %in% names(one),
                info = paste0(d, ": cols = \"", bare, "\" -> ",
                              if (is.character(one)) one else "missing column"))

    # The column the door does not map is exposed and selectable by the name a
    # user reads in enrichment_cols().
    if (is.null(cl$default_cols)) {
      ex <- tryCatch(door(x, cols = "zz_unmapped_trait", verbose = FALSE),
                     error = function(e) conditionMessage(e))
      expect_true(is.data.frame(ex),
                  info = paste0(d, ": cols = \"zz_unmapped_trait\" -> ",
                                if (is.character(ex)) ex else ""))
    }
  }
})

test_that("every column a door maps exists in its example-database fixture", {
  exdir <- file.path(taxify_example_data(), "enrichment")
  skip_if_not(dir.exists(exdir), "example database not available")
  checked <- 0L
  for (d in names(door_calls())) {
    for (cl in door_calls()[[d]]) {
      p <- file.path(exdir, cl$enrichment_name, "latest",
                     paste0(cl$enrichment_name, ".vtr"))
      if (!file.exists(p)) next
      have <- names(vectra::collect(utils::head(vectra::tbl(p), 1L)))
      miss <- setdiff(unique(unname(cl$col_map)), have)
      # A value column's optional spread partners are read when present.
      miss <- miss[!(grepl("_(min|max)$", miss) &
                     sub("_(min|max)$", "", miss) %in% cl$col_map)]
      expect_identical(miss, character(0),
                       info = paste0(d, " -> ", cl$enrichment_name, " fixture"))
      checked <- checked + 1L
    }
  }
  expect_gt(checked, 20L)
})
