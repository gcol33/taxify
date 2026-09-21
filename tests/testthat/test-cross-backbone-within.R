# .alt_within_matched(): a recovered alternative is refused when it sits at a
# broader rank than the queried name, or when the matched backbone accepts it
# as a taxon of its own.

local_within_mocks <- function(env = parent.frame()) {
  held <- data.frame(
    lookup = c("Orostachys spinosa", "Viola tricolor subsp. matutina",
               "Melanoseris lessertiana var. lyrata", "Sedum album"),
    taxonomic_status = c("ACCEPTED", "UNCHECKED", "SYNONYM", "ACCEPTED"),
    is_synonym = c(FALSE, FALSE, TRUE, FALSE),
    accepted_taxon_id = c("m-spinosa", "m-matutina", "m-lessertiana", "m-album"),
    authorship = c("(L.) Sweet", "(Klokov) Valentine", "(Decne.) Ghafoor",
                   "Mill."),
    stringsAsFactors = FALSE)
  local_mocked_bindings(
    backbone_path = function(backbone, verbose = TRUE) paste0(backbone, ".vtr"),
    vtr_schema = function(path) c("canonical_name", "taxonomic_status",
                                  "is_synonym", "accepted_taxon_id",
                                  "authorship"),
    backbone_join = function(bb, values, bb_key, select_cols, pre = NULL) {
      held[held$lookup %in% values, , drop = FALSE]
    },
    .env = env
  )
}

cand_of <- function(name, alt, authorship = NA_character_, q_id = "m1",
                    q_backbone = "m") {
  data.frame(name = name, q_backbone = q_backbone, q_id = q_id, alt = alt,
             authorship = authorship, stringsAsFactors = FALSE)
}

test_that("a species offered for an infraspecific name is refused", {
  local_within_mocks()
  expect_false(.alt_within_matched(
    cand_of("Viola tricolor subsp. matutina", "Viola tricolor", "L.")))
  expect_false(.alt_within_matched(
    cand_of("Orostachys minuta f. alba", "Orostachys minuta", "(Kom.) A.Berger")))
})

test_that("an alternative the matched backbone accepts elsewhere is refused", {
  local_within_mocks()
  expect_false(.alt_within_matched(
    cand_of("Orostachys minuta", "Orostachys spinosa", "(L.) Sweet")))
})

test_that("an alternative held only as a synonym or unreviewed record is kept", {
  local_within_mocks()
  expect_true(.alt_within_matched(
    cand_of("Viola matutina", "Viola tricolor subsp. matutina",
            "(Klokov) Valentine")))
  expect_true(.alt_within_matched(
    cand_of("Mulgedium lessertianum subsp. lyratum",
            "Melanoseris lessertiana var. lyrata", "(Decne.) Ghafoor")))
})

test_that("an accepted homonym under another author does not refuse", {
  local_within_mocks()
  expect_true(.alt_within_matched(
    cand_of("Sedum foo", "Sedum album", "L.")))
  expect_false(.alt_within_matched(
    cand_of("Sedum foo", "Sedum album", "Mill.")))
})

test_that("the matched taxon itself, and an unjudged entry, are kept", {
  local_within_mocks()
  expect_true(.alt_within_matched(
    cand_of("Orostachys minuta", "Orostachys spinosa", "(L.) Sweet",
            q_id = "m-spinosa")))
  expect_true(.alt_within_matched(
    cand_of("Viola tricolor subsp. matutina", "Viola tricolor", "L.",
            q_backbone = NA, q_id = NA)))
})
