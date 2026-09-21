# Regression tests for #50: enrich_by_group() joined on a bare accepted-name
# string, so a name that is a homonym in the enrichment source (two distinct
# concepts sharing one canonical_name, told apart only by authorship) could
# silently attach the wrong concept's data -- add_wcvp() reported
# *Erigeron pulchellus* Michx. (eastern North America) as native in Germany,
# which was actually *Erigeron pulchellus* Hoppe & Hornsch. ex Bluff &
# Fingerh.'s European range.

setup_mock_wfo <- function() {
  vtr_path <- mock_backbone_vtr()
  set_backbone_path("wfo", vtr_path)
}

# Build a WCVP-shaped enrichment .vtr where "Quercus robur" covers two
# distinct concepts (authorship "L." vs the fictitious homonym "Mill."):
# the "L." concept is native to EUR and introduced in NAM, and the "Mill."
# concept -- a different taxon that just happens to share the bare name --
# has its own native record in GER. Pre-fix, a GER lookup would have kept
# whichever row survived the per-group dedup regardless of concept.
setup_mock_wcvp <- function(wcvp = NULL) {
  data_dir <- tempfile("taxify_wcvp_auth_")
  latest <- file.path(data_dir, "enrichment", "wcvp", "latest")
  dir.create(latest, recursive = TRUE)

  if (is.null(wcvp)) {
    wcvp <- data.frame(
      canonical_name = c("Quercus robur", "Quercus robur", "Quercus robur"),
      tdwg_code      = c("EUR", "NAM", "GER"),
      native_status  = c("native", "introduced", "native"),
      taxon_authors  = c("L.", "L.", "Mill."),
      stringsAsFactors = FALSE
    )
  }
  vectra::write_vtr(wcvp, file.path(latest, "wcvp.vtr"))
  jsonlite::write_json(
    list(version = "2026.06", static = TRUE, license = "CC BY 4.0"),
    file.path(latest, "meta.json"), auto_unbox = TRUE
  )

  set_backbone_path("enrichment_wcvp", NULL)
  .taxify_env[[".enrichment_version_checked.wcvp"]] <- NULL

  data_dir
}


test_that("add_wcvp() does not attach a homonym's native range", {
  setup_mock_wfo()
  data_dir <- setup_mock_wcvp()
  old <- options(taxify.data_dir = data_dir)
  on.exit(options(old), add = TRUE)

  r <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
  expect_equal(r$accepted_authorship, "L.")

  # EUR and NAM both belong to the "L." concept x actually resolved to, and
  # keep working as before -- the authorship match is unambiguous, so this
  # is the silent, no-warning path.
  in_concept <- expect_no_warning(
    add_wcvp(r, region = c("EUR", "NAM"), verbose = FALSE))
  expect_equal(in_concept$native_status_EUR, "native")
  expect_equal(in_concept$native_status_NAM, "introduced")

  # GER only exists for the "Mill." homonym in this fixture: it must come
  # back NA, not the wrong concept's "native".
  out <- expect_no_warning(
    add_wcvp(r, region = c("EUR", "GER"), verbose = FALSE))
  expect_equal(out$native_status_EUR, "native")
  expect_true(is.na(out$native_status_GER))
})

test_that("add_wcvp() warns 'no match' when the query shares nothing with any candidate", {
  setup_mock_wfo()
  data_dir <- setup_mock_wcvp()
  old <- options(taxify.data_dir = data_dir)
  on.exit(options(old), add = TRUE)

  # A resolved authorship that matches neither concept in the fixture (e.g.
  # a third backbone's homonym record) shares nothing with either "L." or
  # "Mill." -- not a tie between plausible candidates (#87), so this gets the
  # "no candidate shares any authorship" warning rather than "more than one
  # concept". The earlier "does not attach a homonym's native range" case
  # shows the authorship still resolves the right concept when it does match.
  r <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
  r$accepted_authorship <- "Nomatch."

  expect_warning(add_wcvp(r, region = "GER", verbose = FALSE),
                 "none share any authorship")
  out <- suppressWarnings(add_wcvp(r, region = c("EUR", "GER"), verbose = FALSE))
  expect_true(is.na(out$native_status_EUR))
  expect_true(is.na(out$native_status_GER))
})

test_that("a single-concept name is unaffected by the authorship check", {
  setup_mock_wfo()
  data_dir <- setup_mock_wcvp()
  old <- options(taxify.data_dir = data_dir)
  on.exit(options(old), add = TRUE)

  r <- taxify("Quercus petraea", backbone = "wfo", verbose = FALSE)
  # Not in the fixture at all: normal "no data for this name" path, no warning.
  expect_no_warning(add_wcvp(r, region = "EUR", verbose = FALSE))
})


# Regression tests for #51: the #50 check compared authorship strings exactly,
# but the sources disagree over how an author is written (WFO records *Calluna
# vulgaris* as (L.) Hill where every other source says (L.) Hull) and over who
# is credited with a recombination (*Glaucium corniculatum* is (L.) Curtis in
# WFO, (L.) Rudolph in WCVP). Both read as a homonym collision, so a name that
# is not a homonym at all lost its enrichment entirely.

# Two concepts under one name, where the second concept's authorship is a
# spelling variant of the query's rather than a different author.
wcvp_variant_df <- function(second) {
  data.frame(
    canonical_name = rep("Quercus robur", 3L),
    tdwg_code      = c("EUR", "NAM", "GER"),
    native_status  = c("native", "introduced", "native"),
    taxon_authors  = c(second, second, "Mill."),
    stringsAsFactors = FALSE
  )
}

enrich_with <- function(authorship, wcvp) {
  setup_mock_wfo()
  data_dir <- setup_mock_wcvp(wcvp)
  old <- options(taxify.data_dir = data_dir)
  on.exit(options(old), add = TRUE)
  r <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
  r$accepted_authorship <- authorship
  add_wcvp(r, region = c("EUR", "NAM"), verbose = FALSE)
}


test_that("a spelling variant of the resolved authorship still matches", {
  # "(L.) Hill" vs "(L.) Hull": one edit apart on a four-letter surname, same
  # basionym author. Pre-fix this dropped every row and returned NA.
  out <- expect_no_warning(
    enrich_with("(L.) Hill", wcvp_variant_df("(L.) Hull")))
  expect_equal(out$native_status_EUR, "native")
  expect_equal(out$native_status_NAM, "introduced")

  # Abbreviated to full: "Schischk." of "Schischkin".
  out <- expect_no_warning(
    enrich_with("(Vill.) Schischk.", wcvp_variant_df("(Vill.) Schischkin")))
  expect_equal(out$native_status_EUR, "native")

  # "et" and "&" are the same separator.
  out <- expect_no_warning(
    enrich_with("Hoppe et Hornsch.", wcvp_variant_df("Hoppe & Hornsch.")))
  expect_equal(out$native_status_EUR, "native")
})

test_that("a shared basionym author resolves a recombination disagreement", {
  # Same basionym, different combining author: the same taxon whoever made the
  # combination, and the only candidate carrying the query's basionym author.
  out <- expect_no_warning(
    enrich_with("(L.) Curtis", wcvp_variant_df("(L.) Rudolph")))
  expect_equal(out$native_status_EUR, "native")
  expect_equal(out$native_status_NAM, "introduced")
})

test_that("the basionym pass needs a unique candidate and a real basionym", {
  # Two candidates share the query's basionym author, so it does not separate
  # them: unresolved rather than a guess.
  two <- data.frame(
    canonical_name = rep("Quercus robur", 3L),
    tdwg_code      = c("EUR", "NAM", "GER"),
    native_status  = c("native", "introduced", "native"),
    taxon_authors  = c("(L.) Rudolph", "(L.) Mory", "Mill."),
    stringsAsFactors = FALSE
  )
  expect_warning(enrich_with("(L.) Curtis", two), "more than one concept")
  out <- suppressWarnings(enrich_with("(L.) Curtis", two))
  expect_true(is.na(out$native_status_EUR))

  # No basionym author on either side: two original publications of one
  # binomial are genuine homonyms (#50's Erigeron pulchellus), and an author
  # this short is never read as a spelling variant either. Neither candidate
  # shares anything with the query, so this is the "no match" reason (#87),
  # not a tie between plausible candidates.
  expect_warning(enrich_with("L.f.", wcvp_variant_df("L.")),
                 "none share any authorship")
  out <- suppressWarnings(enrich_with("L.f.", wcvp_variant_df("L.")))
  expect_true(is.na(out$native_status_EUR))
})

test_that("add_wcvp() gives the 'no match' warning for #87's own repro shape", {
  # Three unrelated homonyms under one canonical name, none sharing any
  # authorship component with the queried concept -- the WCVP enrichment
  # simply doesn't hold this concept under any spelling. This is not a tie
  # to break, so it must not read as "match more than one concept".
  setup_mock_wfo()
  three <- data.frame(
    canonical_name = rep("Quercus robur", 3L),
    tdwg_code      = c("EUR", "NAM", "GER"),
    native_status  = c("native", "introduced", "native"),
    taxon_authors  = c("Muhl. ex Willd.", "(Shinners) Noyes", "(L.) Desf."),
    stringsAsFactors = FALSE
  )
  data_dir <- setup_mock_wcvp(three)
  old <- options(taxify.data_dir = data_dir)
  on.exit(options(old), add = TRUE)

  r <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
  r$accepted_authorship <- "(Fernald & Wiegand) Fernald"

  expect_warning(add_wcvp(r, region = c("EUR", "GER"), verbose = FALSE),
                 "none share any authorship")
  out <- suppressWarnings(add_wcvp(r, region = c("EUR", "GER"), verbose = FALSE))
  expect_true(is.na(out$native_status_EUR))
  expect_true(is.na(out$native_status_GER))
})


# A row with no authorship is an autonym: WCVP writes none for one, and the
# build keys an autonym's range under every name a backbone sends it to, so
# Erigeron caucasicus subsp. caucasicus arrived under Erigeron pulchellus and
# attached Turkey, Iran and the Caucasus to a North American species.
wcvp_ranked_df <- function(name, tdwg, authors, rank, infra) {
  data.frame(
    canonical_name = rep(name, length(tdwg)),
    tdwg_code      = tdwg,
    native_status  = rep("native", length(tdwg)),
    taxon_authors  = authors,
    taxon_rank     = rank,
    infraspecies   = infra,
    stringsAsFactors = FALSE
  )
}

enrich_ranked <- function(name, wcvp, region) {
  setup_mock_wfo()
  data_dir <- setup_mock_wcvp(wcvp)
  old <- options(taxify.data_dir = data_dir)
  on.exit(options(old), add = TRUE)
  r <- taxify(name, backbone = "wfo", verbose = FALSE)
  add_wcvp(r, region = region, verbose = FALSE)
}

test_that("another name's autonym under a name is not its range", {
  df <- wcvp_ranked_df("Quercus robur", c("EUR", "TUR"), c("L.", NA),
                       c("Species", "Subspecies"), c(NA, "caucasicus"))
  out <- expect_no_warning(enrich_ranked("Quercus robur", df, c("EUR", "TUR")))
  expect_equal(out$native_status_EUR, "native")
  expect_true(is.na(out$native_status_TUR))
})

test_that("the concept of a name the matched backbone places inside the taxon is added", {
  # The mock WFO lists Quercus pedunculata (Mattusch.) Bonnier & Layens as a
  # synonym of Q. robur L., so the concept the source keys under that name,
  # picked by that author, is part of Q. robur: its GER record is added even
  # though nothing filed it under Q. robur. A row under Q. robur that no part
  # of the taxon accounts for (NAM, "Mill.") is dropped.
  df <- rbind(
    wcvp_ranked_df("Quercus robur", c("EUR", "NAM"), c("L.", "Mill."),
                   rep("Species", 2L), rep(NA, 2L)),
    wcvp_ranked_df("Quercus pedunculata", c("GER", "SPA"),
                   c("(Mattusch.) Bonnier & Layens", "Hoffm."),
                   rep("Species", 2L), rep(NA, 2L))
  )
  out <- expect_no_warning(
    enrich_ranked("Quercus robur", df, c("EUR", "GER", "NAM", "SPA")))
  expect_equal(out$native_status_EUR, "native")
  expect_equal(out$native_status_GER, "native")
  expect_true(is.na(out$native_status_NAM))
  # The other concept under the synonym's name is not the synonym's.
  expect_true(is.na(out$native_status_SPA))
})

test_that("a name with rows of one foreign concept only keeps none of them", {
  # Every row under the name belongs to a concept that is neither the name's
  # nor any part's -- the case a collision-only check never looked at.
  df <- wcvp_ranked_df("Quercus robur", c("EUR", "NAM"), c("Mill.", "Mill."),
                       rep("Species", 2L), rep(NA, 2L))
  expect_warning(out <- enrich_ranked("Quercus robur", df, c("EUR", "NAM")),
                 "none share any authorship")
  expect_true(is.na(out$native_status_EUR))
  expect_true(is.na(out$native_status_NAM))
})

test_that("an accepted subspecies' range is part of its species", {
  # The mock WFO accepts Quercus robur subsp. robur under Q. robur; its rows
  # under its own key count for the species.
  df <- rbind(
    wcvp_ranked_df("Quercus robur", "EUR", "L.", "Species", NA),
    wcvp_ranked_df("Quercus robur subsp. robur", "TUR", NA, "Subspecies",
                   "robur")
  )
  out <- expect_no_warning(
    enrich_ranked("Quercus robur", df, c("EUR", "TUR")))
  expect_equal(out$native_status_EUR, "native")
  expect_equal(out$native_status_TUR, "native")
})

test_that("an autonym keeps its own rows, not its species' range", {
  # The mock WFO writes the autonym with its species' author, "L.", which is
  # also the author of the species rows keyed under it.
  df <- wcvp_ranked_df("Quercus robur subsp. robur", c("EUR", "NAM"),
                       c(NA, "L."), c("Subspecies", "Species"),
                       c("robur", NA))
  out <- expect_no_warning(
    enrich_ranked("Quercus robur subsp. robur", df, c("EUR", "NAM")))
  expect_equal(out$native_status_EUR, "native")
  expect_true(is.na(out$native_status_NAM))
})

test_that("a recombination of a part, filed under the name, is kept", {
  # The mock WFO places Quercus pedunculata (Mattusch.) Bonnier & Layens inside
  # Q. robur. A subspecies row with that epithet whose basionym authors are
  # the part's authors is the same type at another rank; one with another
  # epithet is not.
  df <- wcvp_ranked_df("Quercus robur", c("EUR", "GER", "NAM"),
                       c("L.", "(Bonnier & Layens) Schwarz", "(Bonnier & Layens) Schwarz"),
                       c("Species", "Subspecies", "Subspecies"),
                       c(NA, "pedunculata", "sessiliflora"))
  out <- expect_no_warning(
    enrich_ranked("Quercus robur", df, c("EUR", "GER", "NAM")))
  expect_equal(out$native_status_EUR, "native")
  expect_equal(out$native_status_GER, "native")
  expect_true(is.na(out$native_status_NAM))
})
