# Session memo keyed on arbitrary-length text (#55).
#
# R caps the name of a variable in an environment at 10000 bytes. The
# per-name-set memos are keyed on the query set itself, so a large enough batch
# pushed the key past that cap -- and reading the cache then *raised* rather
# than missing, which took the whole join down with it. The failure surfaced as
# every trait source returning NA for a large batch that a small one answered.

long_key <- function(n_names = 800L) {
  paste(sprintf("Genus%04d epithetlongenough%04d", seq_len(n_names),
                seq_len(n_names)), collapse = "|")
}

test_that("a key past R's 10000-byte variable-name cap round-trips", {
  k <- long_key()
  expect_gt(nchar(k, type = "bytes"), 10000L)

  # The cap is real: this is what the old env-keyed cache did.
  expect_error(.taxify_env[[k]], "10000 bytes")

  expect_null(memo_get(".test_memo", k))
  memo_set(".test_memo", k, data.frame(a = 1L))
  expect_equal(memo_get(".test_memo", k), data.frame(a = 1L))

  # A different key of the same size is a miss, not a collision.
  expect_null(memo_get(".test_memo", paste0(k, "|Zzz aaa")))
  rm(list = ".test_memo", envir = .taxify_env)
})

test_that("memo_set returns the value it stored", {
  expect_equal(memo_set(".test_memo", "k", 42), 42)
  rm(list = ".test_memo", envir = .taxify_env)
})

test_that(".cross_backbone_alternatives resolves a name set larger than the cap", {
  q <- sprintf("Genus%04d epithetlongenough%04d", 1:800, 1:800)
  expect_gt(nchar(paste(q, collapse = "|"), type = "bytes"), 10000L)

  calls <- 0L
  alts <- testthat::with_mocked_bindings(
    {
      first  <- .cross_backbone_alternatives(q)
      second <- .cross_backbone_alternatives(q)   # served from the memo
      expect_equal(first, second)
      first
    },
    installed_backbones = function(...) c("wfo", "col"),
    taxify = function(names_, backbone, ...) {
      calls <<- calls + 1L
      data.frame(input_name = names_, accepted_name = paste0(names_, " acc"),
                 accepted_authorship = NA_character_,
                 genus = sub(" .*", "", names_), stringsAsFactors = FALSE)
    },
    .package = "taxify"
  )

  expect_equal(nrow(alts), 2L * length(q))
  expect_equal(calls, 2L)          # one per backbone, and the repeat was memoized
  keys <- ls(.taxify_env, all.names = TRUE)
  rm(list = intersect(".xbb", keys), envir = .taxify_env)
})

test_that(".resolve_parents_resolved resolves a parent set larger than the cap", {
  parents <- sprintf("Genus%04d epithetlongenough%04d", 1:800, 1:800)
  expect_gt(nchar(paste(parents, collapse = "|"), type = "bytes"), 10000L)

  res <- testthat::with_mocked_bindings(
    .resolve_parents_resolved(parents, "wfo"),
    taxify = function(names_, backbone, ...) {
      data.frame(input_name = names_, accepted_name = paste0(names_, " acc"),
                 accepted_id = as.character(seq_along(names_)),
                 stringsAsFactors = FALSE)
    },
    .package = "taxify"
  )

  expect_equal(nrow(res), length(parents))
  expect_equal(res$accepted_name[1L], paste0(parents[1L], " acc"))
  keys <- ls(.taxify_env, all.names = TRUE)
  rm(list = intersect(".pres", keys), envir = .taxify_env)
})
