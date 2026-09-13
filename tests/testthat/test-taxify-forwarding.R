# Every verb that resolves names through taxify() forwards the matching
# arguments the same way (#70).

# Capture what reaches taxify() and stop there.
capture_taxify_args <- function(code) {
  seen <- NULL
  with_mocked_bindings(
    taxify = function(x, backbone = NULL, ..., verbose = TRUE) {
      seen <<- list(...)
      stop("captured")
    },
    tryCatch(code, error = function(e) {
      if (!identical(conditionMessage(e), "captured")) stop(e)
    })
  )
  seen
}

test_that("the name-taking verbs forward matching arguments to taxify()", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()

  calls <- list(
    synonyms = quote(synonyms("Quercus robus", backbone = "wfo",
                              fuzzy = FALSE, kingdom = "plantae",
                              verbose = FALSE)),
    upstream = quote(upstream("Quercus robus", backbone = "wfo",
                              fuzzy = FALSE, kingdom = "plantae",
                              verbose = FALSE)),
    sci2comm = quote(sci2comm("Quercus robus", backbone = "wfo",
                              fuzzy = FALSE, kingdom = "plantae",
                              verbose = FALSE)),
    comm2sci = quote(comm2sci("example_common_name", output = "result",
                              backbone = "wfo", fuzzy = FALSE,
                              kingdom = "plantae", verbose = FALSE)),
    reconcile = quote(reconcile("Quercus robus", backbone = "wfo",
                                fuzzy = FALSE, kingdom = "plantae",
                                verbose = FALSE)),
    lowest_common = quote(lowest_common(c("Quercus robur", "Quercus robus"),
                                        backbone = "wfo", fuzzy = FALSE,
                                        kingdom = "plantae",
                                        verbose = FALSE)),
    class2tree = quote(class2tree(c("Quercus robur", "Quercus robus"),
                                  backbone = "wfo", fuzzy = FALSE,
                                  kingdom = "plantae", verbose = FALSE))
  )
  for (verb in names(calls)) {
    seen <- capture_taxify_args(eval(calls[[verb]]))
    expect_identical(seen, list(fuzzy = FALSE, kingdom = "plantae"),
                     info = verb)
  }
})

test_that("no verb switches fuzzy matching on behind the caller's back", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()

  for (verb in list(
    quote(synonyms("Quercus robus", backbone = "wfo", verbose = FALSE)),
    quote(upstream("Quercus robus", backbone = "wfo", verbose = FALSE)),
    quote(sci2comm("Quercus robus", backbone = "wfo", verbose = FALSE))
  )) {
    expect_identical(capture_taxify_args(eval(verb)), list(), info = verb[[1]])
  }

  # And fuzzy = FALSE takes effect end to end.
  expect_gt(nrow(upstream("Quercus robus", backbone = "wfo", verbose = FALSE)),
            0L)
  expect_equal(nrow(upstream("Quercus robus", backbone = "wfo", fuzzy = FALSE,
                             verbose = FALSE)), 0L)
})

test_that("arguments passed on to taxify() must be named", {
  expect_error(taxify_input("Quercus robur", backbone = "wfo", FALSE,
                            verbose = FALSE), "must be named")
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  expect_error(reconcile("Quercus robur", "wfo", FALSE), "must be named")
})
