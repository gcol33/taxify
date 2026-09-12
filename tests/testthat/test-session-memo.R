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


# ---- Per-backbone session state is keyed on the build, not the basename (#57) ----

test_that("the memo key separates two builds sharing a basename", {
  dir_a <- file.path(tempfile("memo_a")); dir.create(dir_a)
  dir_b <- file.path(tempfile("memo_b")); dir.create(dir_b)
  on.exit(unlink(c(dir_a, dir_b), recursive = TRUE), add = TRUE)

  a <- file.path(dir_a, "wfo.vtr")
  b <- file.path(dir_b, "wfo.vtr")
  writeLines("a", a)
  writeLines(c("b", "b"), b)

  expect_false(identical(backbone_memo_key(".blk_", a),
                         backbone_memo_key(".blk_", b)))
  # Same file, same key: the memo still hits within one build.
  expect_identical(backbone_memo_key(".blk_", a), backbone_memo_key(".blk_", a))
  # And a build replaced in place under the same path keys differently.
  before <- backbone_memo_key(".blk_", a)
  writeLines(c("a", "a", "a"), a)
  expect_false(identical(before, backbone_memo_key(".blk_", a)))
})

# Other test files leave their own backbones loaded, so count only the keys
# belonging to the build under test.
memo_keys_for <- function(vtr) {
  full <- normalizePath(vtr, winslash = "/", mustWork = FALSE)
  k <- ls(.taxify_env, all.names = TRUE)
  k <- k[startsWith(k, ".blk_") | startsWith(k, ".fuzzy_bb_")]
  k[startsWith(sub("^\\.(blk|fuzzy_bb)_", "", k), full)]
}

test_that("clearing a backbone path drops the build loaded from it", {
  vtr <- mock_backbone_vtr()
  set_backbone_path("wfo", vtr)
  taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
  expect_gt(length(memo_keys_for(vtr)), 0L)

  set_backbone_path("wfo", NULL)
  expect_length(memo_keys_for(vtr), 0L)
})

test_that("taxify_clear_cache() clears the loaded backbones, not just the paths", {
  vtr <- mock_backbone_vtr()
  set_backbone_path("wfo", vtr)
  taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
  expect_gt(length(memo_keys_for(vtr)), 0L)

  taxify_clear_cache()
  # Every build, not only this one: the cache clears the whole session.
  k <- ls(.taxify_env, all.names = TRUE)
  expect_length(k[startsWith(k, ".blk_") | startsWith(k, ".fuzzy_bb_")], 0L)
})

test_that("a data-dir switch under one basename matches the new build", {
  # Two backbones written to the same basename in different directories: the
  # session must answer from whichever the path cache currently resolves.
  first  <- mock_backbone_vtr()
  second <- mock_col_backbone_vtr()

  dir_a <- tempfile("build_a"); dir.create(dir_a)
  dir_b <- tempfile("build_b"); dir.create(dir_b)
  on.exit(unlink(c(dir_a, dir_b), recursive = TRUE), add = TRUE)
  a <- file.path(dir_a, "wfo.vtr")
  b <- file.path(dir_b, "wfo.vtr")
  file.copy(first, a)
  file.copy(second, b)

  set_backbone_path("wfo", a)
  # "Picea polita" is in the WFO mock only.
  expect_equal(taxify("Picea polita", backbone = "wfo",
                      verbose = FALSE)$match_type, "exact")

  set_backbone_path("wfo", NULL)
  set_backbone_path("wfo", b)
  expect_equal(taxify("Picea polita", backbone = "wfo",
                      verbose = FALSE)$match_type, "none")
  # The second build is being read, not simply failing to read: a name it does
  # carry still matches.
  expect_equal(taxify("Quercus robur", backbone = "wfo",
                      verbose = FALSE)$taxon_id, "5T6MX")
})
