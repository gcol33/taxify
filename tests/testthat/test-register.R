test_that("assign_life_form() works for class-level hits", {
  # Mosses
  expect_equal(assign_life_form("Plantae", "Bryopsida"), "moss")
  expect_equal(assign_life_form("Plantae", "Sphagnopsida"), "moss")
  expect_equal(assign_life_form("Plantae", "Polytrichopsida"), "moss")

  # Liverworts
  expect_equal(assign_life_form("Plantae", "Marchantiopsida"), "liverwort")
  expect_equal(assign_life_form("Plantae", "Jungermanniopsida"), "liverwort")

  # Hornworts
  expect_equal(assign_life_form("Plantae", "Anthocerotopsida"), "hornwort")

  # Lycophytes
  expect_equal(assign_life_form("Plantae", "Lycopodiopsida"), "lycophyte")

  # Ferns
  expect_equal(assign_life_form("Plantae", "Polypodiopsida"), "fern")
  expect_equal(assign_life_form("Plantae", "Equisetopsida"), "fern")

  # Angiosperms
  expect_equal(assign_life_form("Plantae", "Liliopsida"), "vascular")
  expect_equal(assign_life_form("Plantae", "Magnoliopsida"), "vascular")

  # Gymnosperms
  expect_equal(assign_life_form("Plantae", "Pinopsida"), "gymnosperm")
  expect_equal(assign_life_form("Plantae", "Cycadopsida"), "gymnosperm")

  # Lichens
  expect_equal(assign_life_form("Fungi", "Lecanoromycetes"), "lichen")
  expect_equal(assign_life_form("Fungi", "Arthoniomycetes"), "lichen")
})


test_that("assign_life_form() uses kingdom fallback when class is NA", {
  expect_equal(assign_life_form("Fungi", NA_character_), "fungus")
  expect_equal(assign_life_form("Animalia", NA_character_), "animal")
  expect_equal(assign_life_form("Chromista", NA_character_), "alga")
  expect_equal(assign_life_form("Protozoa", NA_character_), "protozoa")
  expect_equal(assign_life_form("Bacteria", NA_character_), "microbe")
  expect_equal(assign_life_form("Archaea", NA_character_), "microbe")
})


test_that("assign_life_form() returns 'unknown' for unrecognized kingdom+class", {
  expect_equal(assign_life_form("Unknownia", NA_character_), "unknown")
  expect_equal(assign_life_form(NA_character_, NA_character_), "unknown")
})


test_that("assign_life_form() is vectorized", {
  kingdom <- c("Plantae", "Fungi", "Animalia", "Plantae")
  class   <- c("Bryopsida", NA_character_, NA_character_, "Liliopsida")
  result  <- assign_life_form(kingdom, class)
  expect_equal(result, c("moss", "fungus", "animal", "vascular"))
})


test_that("assign_life_form() errors on mismatched lengths", {
  expect_error(assign_life_form(c("Plantae", "Fungi"), "Bryopsida"),
               "same length")
})


# ---- lookup_genus() tests using a mock register ----

#' Build a minimal mock register and inject it into .taxify_env
setup_mock_register <- function() {
  reg <- data.frame(
    genus     = c("Quercus", "Boletus", "Aspergillus"),
    kingdom   = c("Plantae", "Fungi", "Fungi"),
    phylum    = c("Tracheophyta", "Basidiomycota", "Ascomycota"),
    class     = c("Magnoliopsida", NA_character_, NA_character_),
    order     = c("Fagales", "Boletales", "Eurotiales"),
    family    = c("Fagaceae", "Boletaceae", "Aspergillaceae"),
    life_form = c("vascular", "fungus", "fungus"),
    stringsAsFactors = FALSE
  )
  .taxify_env$register <- reg
  reg
}

teardown_mock_register <- function() {
  .taxify_env$register <- NULL
}


test_that("lookup_genus() returns the correct row", {
  setup_mock_register()
  on.exit(teardown_mock_register())

  hit <- lookup_genus("Quercus")
  expect_false(is.null(hit))
  expect_equal(nrow(hit), 1L)
  expect_equal(hit$genus, "Quercus")
  expect_equal(hit$life_form, "vascular")
  expect_equal(hit$family, "Fagaceae")
})


test_that("lookup_genus() returns NULL for unknown genus", {
  setup_mock_register()
  on.exit(teardown_mock_register())

  expect_null(lookup_genus("Nonexistia"))
  expect_null(lookup_genus(""))
})


test_that("lookup_genus() errors on non-scalar input", {
  expect_error(lookup_genus(c("Quercus", "Pinus")), "scalar")
  expect_error(lookup_genus(1L), "character scalar")
})


# ---- out_of_scope enrichment tests ----

test_that("taxify() sets match_type = 'out_of_scope' and life_form for genus-in-register", {
  # Set up mock WFO backbone (Quercus and Pinus are plants, Boletus is not in WFO)
  bb_path <- mock_backbone_vtr()
  be <- wfo_backend()

  # Inject mock backbone path into cache
  set_backbone_path("wfo", bb_path)
  on.exit({
    set_backbone_path("wfo", NULL)
    .taxify_env$register <- NULL
  }, add = TRUE)

  # Set up a register that includes Boletus (a fungus genus not in WFO backbone)
  .taxify_env$register <- data.frame(
    genus     = c("Quercus", "Pinus", "Boletus"),
    kingdom   = c("Plantae", "Plantae", "Fungi"),
    phylum    = c("Tracheophyta", "Tracheophyta", "Basidiomycota"),
    class     = c("Magnoliopsida", "Pinopsida", NA_character_),
    order     = c("Fagales", "Pinales", "Boletales"),
    family    = c("Fagaceae", "Pinaceae", "Boletaceae"),
    life_form = c("vascular", "gymnosperm", "fungus"),
    stringsAsFactors = FALSE
  )

  result <- taxify(
    c("Quercus robur", "Boletus edulis", "Xxxx yyyyy"),
    backend = "wfo",
    fuzzy = FALSE,
    verbose = FALSE
  )

  # Quercus robur is in WFO — matched
  qr_row <- result[result$input_name == "Quercus robur", ]
  expect_true(qr_row$match_type %in% c("exact", "exact_ci"))

  # Boletus edulis: genus Boletus is in register but not WFO backbone
  be_row <- result[result$input_name == "Boletus edulis", ]
  expect_equal(be_row$match_type, "out_of_scope")
  expect_equal(be_row$life_form, "fungus")

  # Xxxx yyyyy: genus not in register either — stays "none"
  xx_row <- result[result$input_name == "Xxxx yyyyy", ]
  expect_equal(xx_row$match_type, "none")
  expect_true(is.na(xx_row$life_form))
})


test_that("taxify() does not enrich when register is unavailable", {
  bb_path <- mock_backbone_vtr()
  set_backbone_path("wfo", bb_path)
  on.exit({
    set_backbone_path("wfo", NULL)
    .taxify_env$register <- NULL
  }, add = TRUE)

  # Ensure register is NOT loaded
  .taxify_env$register <- NULL

  result <- taxify(
    c("Quercus robur", "Boletus edulis"),
    backend = "wfo",
    fuzzy = FALSE,
    verbose = FALSE
  )

  # No out_of_scope — register not available
  expect_false(any(result$match_type == "out_of_scope", na.rm = TRUE))
})


test_that("out_of_scope enrichment does not affect matched names", {
  bb_path <- mock_backbone_vtr()
  set_backbone_path("wfo", bb_path)
  on.exit({
    set_backbone_path("wfo", NULL)
    .taxify_env$register <- NULL
  }, add = TRUE)

  .taxify_env$register <- data.frame(
    genus     = c("Quercus", "Pinus"),
    kingdom   = c("Plantae", "Plantae"),
    phylum    = c("Tracheophyta", "Tracheophyta"),
    class     = c("Magnoliopsida", "Pinopsida"),
    order     = c("Fagales", "Pinales"),
    family    = c("Fagaceae", "Pinaceae"),
    life_form = c("vascular", "gymnosperm"),
    stringsAsFactors = FALSE
  )

  result <- taxify(
    c("Quercus robur", "Pinus sylvestris"),
    backend = "wfo",
    fuzzy = FALSE,
    verbose = FALSE
  )

  # Both should be matched, not out_of_scope
  expect_true(all(result$match_type %in% c("exact", "exact_ci", "fuzzy")))
  # life_form is NA for matched rows (not populated from register for matches)
  expect_true(all(is.na(result$life_form)))
})


# ---- resolve_genus_classification() ----

test_that("resolve_genus_classification() prefers COL > GBIF > WFO", {
  col_genera <- data.frame(
    genus = "Quercus", kingdom = "Plantae", phylum = "Tracheophyta",
    class = "Magnoliopsida", order = "Fagales", family = "Fagaceae",
    stringsAsFactors = FALSE
  )
  wfo_genera <- data.frame(
    genus = "Quercus", kingdom = NA_character_, phylum = NA_character_,
    class = NA_character_, order = NA_character_, family = "Fagaceae",
    stringsAsFactors = FALSE
  )
  gbif_genera <- data.frame(
    genus = "Quercus", kingdom = NA_character_, phylum = NA_character_,
    class = "Magnoliopsida_gbif", order = NA_character_, family = "Fagaceae",
    stringsAsFactors = FALSE
  )

  resolved <- resolve_genus_classification(
    list(col = col_genera, gbif = gbif_genera, wfo = wfo_genera)
  )

  expect_equal(nrow(resolved), 1L)
  # COL class wins over GBIF class
  expect_equal(resolved$class, "Magnoliopsida")
  expect_equal(resolved$kingdom, "Plantae")
})


test_that("resolve_genus_classification() uses GBIF when COL missing", {
  gbif_genera <- data.frame(
    genus = "Boletus", kingdom = "Fungi", phylum = "Basidiomycota",
    class = "Agaricomycetes", order = "Boletales", family = "Boletaceae",
    stringsAsFactors = FALSE
  )
  wfo_genera <- data.frame(
    genus = "Boletus", kingdom = NA_character_, phylum = NA_character_,
    class = NA_character_, order = NA_character_, family = "Boletaceae",
    stringsAsFactors = FALSE
  )

  resolved <- resolve_genus_classification(
    list(col = NULL, gbif = gbif_genera, wfo = wfo_genera)
  )

  expect_equal(nrow(resolved), 1L)
  expect_equal(resolved$kingdom, "Fungi")
  expect_equal(resolved$class, "Agaricomycetes")
})


test_that("resolve_genus_classification() unions genera across backends", {
  col_genera <- data.frame(
    genus = "Quercus", kingdom = "Plantae", phylum = NA_character_,
    class = "Magnoliopsida", order = "Fagales", family = "Fagaceae",
    stringsAsFactors = FALSE
  )
  gbif_genera <- data.frame(
    genus = "Boletus", kingdom = "Fungi", phylum = NA_character_,
    class = "Agaricomycetes", order = "Boletales", family = "Boletaceae",
    stringsAsFactors = FALSE
  )

  resolved <- resolve_genus_classification(
    list(col = col_genera, gbif = gbif_genera, wfo = NULL)
  )

  expect_equal(nrow(resolved), 2L)
  expect_true("Quercus" %in% resolved$genus)
  expect_true("Boletus" %in% resolved$genus)
})
