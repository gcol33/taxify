# export_data() writes a result to .vtr / .csv / .tsv / .xlsx, inferring the
# format from the extension and preserving column types on the .vtr round trip.

mk_df <- function() data.frame(
  name = c("Quercus robur", "Pinus sylvestris"),
  count = c(1L, 2L),
  value = c(1.5, 2.5),
  stringsAsFactors = FALSE
)

test_that("export_data() round-trips a data.frame through .vtr with types", {
  df <- mk_df()
  p <- tempfile(fileext = ".vtr")
  on.exit(unlink(p), add = TRUE)
  expect_equal(export_data(df, p), p)
  back <- vectra::collect(vectra::tbl(p))
  expect_equal(back$name, df$name)
  expect_equal(as.numeric(back$count), as.numeric(df$count))
  expect_equal(back$value, df$value)
  expect_true(is.numeric(back$count))
})

test_that("export_data() writes CSV and TSV readable back", {
  df <- mk_df()
  pc <- tempfile(fileext = ".csv")
  pt <- tempfile(fileext = ".tsv")
  on.exit(unlink(c(pc, pt)), add = TRUE)
  export_data(df, pc)
  export_data(df, pt)
  back_c <- utils::read.csv(pc, stringsAsFactors = FALSE)
  back_t <- utils::read.delim(pt, stringsAsFactors = FALSE)
  expect_equal(back_c$name, df$name)
  expect_equal(back_c$count, df$count)
  expect_equal(back_t$name, df$name)
  expect_equal(back_t$value, df$value)
})

test_that("export_data() refuses to overwrite unless asked", {
  df <- mk_df()
  p <- tempfile(fileext = ".csv")
  on.exit(unlink(p), add = TRUE)
  export_data(df, p)
  expect_error(export_data(df, p), "already exists")
  expect_equal(export_data(df, p, overwrite = TRUE), p)
})

test_that("export_data() defaults a missing extension to .vtr", {
  df <- mk_df()
  base <- tempfile()
  p <- paste0(base, ".vtr")
  on.exit(unlink(p), add = TRUE)
  expect_message(out <- export_data(df, base), "\\.vtr")
  expect_equal(out, p)
  expect_true(file.exists(p))
})

test_that("export_data() rejects an unsupported extension", {
  df <- mk_df()
  expect_error(export_data(df, tempfile(fileext = ".json")), "Unsupported")
})

test_that("export_data() validates its arguments", {
  expect_error(export_data(list(a = 1), tempfile(fileext = ".csv")),
               "data.frame")
  expect_error(export_data(mk_df(), c("a", "b")), "single file path")
})
