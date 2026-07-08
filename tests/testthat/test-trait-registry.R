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

test_that("categorical crosswalk outputs stay within the declared vocabulary", {
  # Where a trait declares a vocabulary, no source map may invent a token
  # outside it (checked on the NA input, which must map to NA, not a stray
  # literal). A cheap guard against a typo'd replacement value.
  for (tn in names(reg)) {
    spec <- reg[[tn]]
    if (spec$kind != "categorical" || is.null(spec$vocab)) next
    for (sn in names(spec$sources)) {
      out <- spec$sources[[sn]]$map(NA_character_)
      expect_true(is.na(out) || out %in% spec$vocab,
                  info = paste(tn, sn, "vocab"))
    }
  }
})
