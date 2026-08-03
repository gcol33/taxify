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


# ---- mappers whose logic is more than a lookup -------------------------------
# The generic invariants above cannot catch a decoder that is well-formed but
# wrong. These two carry real logic, so they are pinned against hand-worked
# cases.

test_that(".austraits_flower_window() reads a flowering season circularly", {
  w <- taxify:::.austraits_flower_window(c(
    "nnnnnnnnyyyn",  # September to November, no wrap
    "yynnnnnnnnny",  # December to February, wraps the year boundary
    "yyyyyyyyyyyy",  # flowers year round
    "nnnnnnnnnnnn",  # never flowers: no window to report
    "nynynynynyny",  # alternating, so every run is one month long
    NA_character_,
    "not-a-pattern"))

  expect_equal(w[1, ], c(9, 11))
  # The wrap is the whole point: read left to right this would be January to
  # December, which is the entire year rather than a three-month summer.
  expect_equal(w[2, ], c(12, 2))
  expect_equal(w[3, ], c(1, 12))
  expect_true(all(is.na(w[4, ])))
  # Ties pick the first maximal run; the contract is only that it stays inside
  # the calendar and spans one month.
  expect_equal(w[5, 1], w[5, 2])
  expect_true(all(is.na(w[6, ])))
  expect_true(all(is.na(w[7, ])))

  # Both trait slots read the same source column, so they must not disagree
  # about which string they are decoding.
  reg <- taxify:::.trait_registry()
  expect_equal(reg$flowering_start$sources$austraits$col, "flowering_time")
  expect_equal(reg$flowering_end$sources$austraits$col, "flowering_time")
  expect_equal(reg$flowering_start$sources$austraits$map("yynnnnnnnnny"), 12)
  expect_equal(reg$flowering_end$sources$austraits$map("yynnnnnnnnny"), 2)
})

test_that("the BROT resprouting mapper reads all three of its encodings", {
  m <- taxify:::.trait_registry()$resprouting$sources$brot$map

  # resp_fire mixes yes/no, an ordinal, and the percentage of individuals
  # resprouting in one column. The numeric arm must not fall through to the
  # regex arm, where "0" and "100" would both come back NA.
  expect_equal(m(c("no", "yes", "high")),
               c("non_resprouter", "resprouter", "resprouter"))
  expect_equal(m(c("low", "variable")), c("partial", "partial"))
  expect_equal(m(c("0", "40", "100")),
               c("non_resprouter", "resprouter", "resprouter"))
  expect_true(is.na(m(NA_character_)))
  expect_true(is.na(m("")))
})


test_that("wing morphology keeps its three states", {
  reg <- taxify:::.trait_registry()
  m   <- reg$wing_morph$sources$chowdhury$map

  # Dimorphic species produce both a long-winged and a short-winged form. It is
  # the state carabid dispersal ecology cares about, so it must survive as its
  # own value rather than collapsing into either wing type or into NA.
  expect_equal(m(c("Long-winged", "Short-winged", "Dimorphic")),
               c("long-winged", "short-winged", "dimorphic"))
  expect_setequal(reg$wing_morph$vocab,
                  c("long-winged", "short-winged", "dimorphic"))
  # The entomological synonyms read the same way.
  expect_equal(m(c("macropterous", "brachypterous")),
               c("long-winged", "short-winged"))
  expect_true(is.na(m(NA_character_)))

  # flightless asks a different question (can it fly at all) and stays separate.
  expect_false("chowdhury" %in% names(reg$flightless$sources))
  expect_false(any(reg$flightless$vocab %in% reg$wing_morph$vocab))
})

test_that("the carabid habitat mapper drops the two non-habitat classes", {
  m <- taxify:::.trait_registry()$primary_habitat$sources$chowdhury$map

  expect_equal(m(c("Coastal", "Forest", "Open", "Riparian", "Wetland")),
               c("coastal", "forest", "open", "riparian", "wetland"))
  # Eurytopic states niche breadth, and "Special habitats" is a residual bin.
  # Neither names a habitat, so neither may be coerced into one.
  expect_true(all(is.na(m(c("Eurytopic", "Special habitats")))))
})

test_that("the German national Red List stays out of conservation_status", {
  reg <- taxify:::.trait_registry()
  # chowdhury red_list_iucn restates the German national assessment in IUCN
  # letters -- it is perfectly diagonal against red_list_germany over all 382
  # species -- and national risk is not global risk. It belongs to the door.
  expect_false("chowdhury" %in% names(reg$conservation_status$sources))
  used <- vapply(reg, function(t) {
    s <- t$sources$chowdhury
    if (is.null(s)) "" else s$col
  }, character(1L))
  expect_false(any(used %in% c("red_list_iucn", "red_list_germany",
                               "threat_status", "occupancy_trend")))
})

test_that("arthropod_traits contributes its guild but not its body size", {
  reg <- taxify:::.trait_registry()
  # body_size_mm is a true body length for spiders (1.000 against spider_traits)
  # and beetles (1.014 against chowdhury) but forewing length for Lepidoptera
  # (0.515 of the leptraits wingspan), and the .vtr carries no taxon column to
  # separate them -- gcol33/taxifydb#40.
  expect_false("arthropod_traits" %in% names(reg$body_length$sources))
  expect_true("arthropod_traits" %in% names(reg$diet_guild$sources))

  m <- reg$diet_guild$sources$arthropod_traits$map
  expect_equal(m(c("herbivore", "carnivore", "omnivore", "detritivore", "fungivore")),
               c("herbivore", "carnivore", "omnivore", "detritivore", "fungivore"))
  # "pollinator" names a function rather than a diet, and "non-eating" marks
  # adults that do not feed. Neither has a counterpart in the vocabulary.
  expect_true(all(is.na(m(c("pollinator", "non-eating")))))
})
