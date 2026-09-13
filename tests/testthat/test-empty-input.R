# A query that resolves to nothing is ordinary input (#65).
#
# A result filtered to zero rows inside a pipeline, or a vernacular that matches
# no name, has to come back as an empty result with the full output schema --
# not as "replacement has 1 row, data has 0", and not with a warning per source.

test_that("empty_taxify_result() has the schema of a real taxify() result", {
  r <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
  e <- empty_taxify_result("wfo")

  expect_s3_class(e, "taxify_result")
  expect_equal(nrow(e), 0L)
  expect_identical(names(e), names(r))
  expect_identical(vapply(e, function(v) class(v)[1L], character(1L)),
                   vapply(r, function(v) class(v)[1L], character(1L)))
  expect_identical(attr(e, "taxify_meta")$backbone, "wfo")
  expect_output(summary(e), "0 names submitted")
})

test_that("comm2sci(output = 'result') returns an empty result when nothing matches", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  hit <- comm2sci("example_common_name", output = "result", backbone = "wfo",
                  verbose = FALSE)
  for (q in list("no such vernacular xyz", NA_character_)) {
    out <- expect_no_warning(
      comm2sci(q, output = "result", backbone = "wfo", verbose = FALSE))
    expect_s3_class(out, "taxify_result")
    expect_equal(nrow(out), 0L)
    expect_identical(names(out), names(hit))
  }

  # A lang filter that removes every row takes the same exit.
  none <- comm2sci("example_common_name", lang = "zz", output = "result",
                   backbone = "wfo", verbose = FALSE)
  expect_equal(nrow(none), 0L)
  expect_identical(names(none), names(hit))
})

test_that("add_trait() and the doors accept a zero-row result without warnings", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  r  <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
  r0 <- r[0, ]

  full <- add_trait(r, "seed_mass", verbose = FALSE)
  zero <- expect_no_warning(add_trait(r0, "seed_mass", verbose = FALSE))
  expect_equal(nrow(zero), 0L)
  expect_identical(names(zero), names(full))

  cat_full <- add_trait(r, "woodiness", verbose = FALSE)
  cat_zero <- expect_no_warning(add_trait(r0, "woodiness", verbose = FALSE))
  expect_identical(names(cat_zero), names(cat_full))

  door <- expect_no_warning(add_iucn(r0, verbose = FALSE))
  expect_equal(nrow(door), 0L)
  expect_identical(names(door), names(add_iucn(r, verbose = FALSE)))
})

test_that("set_col_value() recycles to the frame, including zero rows", {
  df0 <- data.frame(a = character(0))
  expect_identical(set_col_value(df0, "b", NA_real_)$b, numeric(0))
  df2 <- data.frame(a = c("x", "y"))
  expect_identical(set_col_value(df2, "b", "mg")$b, c("mg", "mg"))
})
