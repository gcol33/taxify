# Structural invariants over the whole cross-source trait registry. These do not
# assert specific harmonized values (test-add-trait.R does that for a sample of
# traits); they check that every one of the ~400 source crosswalk closures is
# well-formed: NA-safe, length-preserving, and of the declared output type. A
# mapper that errors on NA or changes vector length is a real bug that would only
# surface on a particular species otherwise.

reg <- taxify:::.trait_registry()

test_that("list_traits() and trait_info() agree with the registry", {
  lt <- list_traits()
  expect_setequal(lt$trait, names(reg))
  expect_true(all(lt$kind %in% c("numeric", "categorical")))
  # n_sources matches the registry
  ns <- vapply(reg, function(t) length(t$sources), integer(1L))
  expect_equal(lt$n_sources[match(names(ns), lt$trait)], unname(ns))
})

test_that("every source crosswalk is a function with the documented metadata", {
  for (tn in names(reg)) {
    spec <- reg[[tn]]
    expect_true(spec$kind %in% c("numeric", "categorical"),
                info = tn)
    for (sn in names(spec$sources)) {
      s <- spec$sources[[sn]]
      expect_true(is.function(s$map), info = paste(tn, sn, "map is function"))
      expect_true(is.character(s$enrichment) && length(s$enrichment) == 1L,
                  info = paste(tn, sn, "enrichment"))
      expect_true(is.character(s$col) && length(s$col) == 1L,
                  info = paste(tn, sn, "col"))
    }
  }
})

test_that("every source crosswalk is NA-safe and length-preserving", {
  for (tn in names(reg)) {
    spec  <- reg[[tn]]
    na_in <- if (spec$kind == "numeric") NA_real_ else NA_character_
    for (sn in names(spec$sources)) {
      m <- spec$sources[[sn]]$map
      out1 <- m(na_in)
      expect_equal(length(out1), 1L,
                   info = paste(tn, sn, "scalar NA -> length 1"))
      expect_true(is.na(out1),
                  info = paste(tn, sn, "NA -> NA"))
      out3 <- m(rep(na_in, 3L))
      expect_equal(length(out3), 3L,
                   info = paste(tn, sn, "length preserved"))
      if (spec$kind == "numeric") {
        expect_true(is.numeric(out1) || all(is.na(out1)),
                    info = paste(tn, sn, "numeric out"))
      } else {
        expect_true(is.character(out1) || all(is.na(out1)),
                    info = paste(tn, sn, "character out"))
      }
    }
  }
})

# The crosswalk tables behind a map. `.xw_cat()` and `.xw_grep()` closures hold
# their lookup in the enclosing environment, so the table is read off the call
# in the map's body and evaluated there. Returns a list of `kind` + `table`
# pairs, empty for a map written out by hand.
crosswalk_tables <- function(f) {
  found <- list()
  env   <- environment(f)
  walk <- function(e) {
    if (!is.call(e)) return(invisible(NULL))
    fn <- e[[1L]]
    if (is.name(fn) && as.character(fn) %in% c(".xw_cat", ".xw_grep") &&
        length(e) >= 3L) {
      tab <- tryCatch(eval(e[[3L]], env), error = function(err) NULL)
      if (is.character(tab) && !is.null(names(tab))) {
        found[[length(found) + 1L]] <<- list(kind = as.character(fn),
                                             table = tab)
      }
    }
    for (i in seq_along(e)) {
      el <- tryCatch(e[[i]], error = function(err) NULL)
      if (!is.null(el)) walk(el)
    }
  }
  walk(body(f))
  found
}

# A `covr:::count("<file>:<line>:...")` call, which covr inserts as a sibling of
# every instrumented expression. Its key is a string literal that is not a source
# value, so the call is skipped rather than read for literals.
is_covr_count <- function(e) {
  fn <- e[[1L]]
  if (is.call(fn) && length(fn) == 3L && is.name(fn[[1L]]) &&
      as.character(fn[[1L]]) %in% c("::", ":::")) {
    fn <- fn[[3L]]
  }
  is.name(fn) && identical(as.character(fn), "count")
}

# Every character literal in a function body. For a map written out by hand
# these are the source tokens it tests against.
body_literals <- function(f) {
  acc <- character(0L)
  walk <- function(e) {
    if (is.character(e)) {
      acc <<- c(acc, e)
      return(invisible(NULL))
    }
    if (is.call(e) || is.pairlist(e)) {
      if (is.call(e) && is_covr_count(e)) return(invisible(NULL))
      for (i in seq_along(e)) {
        el <- tryCatch(e[[i]], error = function(err) NULL)
        if (!is.null(el)) walk(el)
      }
    }
  }
  walk(body(f))
  unique(acc)
}

# Representative non-NA source values for a map: the keys of its lookup tables
# (each ordered-regex pattern also split into its literal alternatives) plus
# the literals of its body.
crosswalk_inputs <- function(f, tabs) {
  probes <- body_literals(f)
  for (t in tabs) {
    probes <- c(probes, names(t$table))
    if (identical(t$kind, ".xw_grep")) {
      probes <- c(probes, unlist(strsplit(names(t$table), "|", fixed = TRUE)))
    }
  }
  probes <- probes[!is.na(probes) & nzchar(probes)]
  unique(probes)
}

test_that("categorical crosswalk outputs stay within the declared vocabulary", {
  # Where a trait declares a vocabulary, no source map may emit a token outside
  # it. Each map is driven with the source values it is built from, so a typo'd
  # replacement value or a lookup wired to the wrong vocabulary shows up.
  for (tn in names(reg)) {
    spec <- reg[[tn]]
    if (spec$kind != "categorical" || is.null(spec$vocab)) next
    for (sn in names(spec$sources)) {
      m    <- spec$sources[[sn]]$map
      tabs <- crosswalk_tables(m)

      # A lookup table names every value the map can emit, so the whole emitted
      # set is checkable whether or not a probe reaches it.
      emitted <- unique(unlist(lapply(tabs, function(t) unname(t$table))))
      expect_true(all(emitted %in% spec$vocab),
                  info = paste(tn, sn, "declares",
                               paste(setdiff(emitted, spec$vocab),
                                     collapse = ", ")))

      probes <- crosswalk_inputs(m, tabs)
      # A source that already stores the canonical token has a verbatim map and
      # no crosswalk to read; there its own values are the vocabulary.
      if (!length(probes)) probes <- spec$vocab

      out <- m(probes)
      expect_equal(length(out), length(probes),
                   info = paste(tn, sn, "length preserved on source values"))
      # A value the source does not carry may map to NA; a non-NA output
      # outside the vocabulary is a token the trait never declared.
      seen <- unique(out[!is.na(out)])
      expect_true(all(seen %in% spec$vocab),
                  info = paste(tn, sn, "emits",
                               paste(setdiff(seen, spec$vocab),
                                     collapse = ", ")))
      # The map must recognise its own source values, so one wired to the wrong
      # column or lookup cannot pass by returning NA throughout.
      expect_true(length(seen) > 0L,
                  info = paste(tn, sn, "recognises no source value"))
    }
  }
})
