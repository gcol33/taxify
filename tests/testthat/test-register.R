test_that("assign_life_form() returns correct taxon_group for known families", {
  chk <- function(fam, expected_tg) {
    res <- assign_life_form(fam)
    expect_equal(res$taxon_group, expected_tg,
                 info = sprintf("family: %s", fam))
  }

  # Mosses
  chk("Sphagnaceae",   "moss")
  chk("Polytrichaceae", "moss")
  chk("Bryaceae",       "moss")

  # Liverworts
  chk("Marchantiaceae",  "liverwort")
  chk("Jungermanniaceae", "liverwort")

  # Hornworts
  chk("Anthocerotaceae", "hornwort")

  # Lycophytes
  chk("Lycopodiaceae",  "lycophyte")
  chk("Selaginellaceae", "lycophyte")
  chk("Isoetaceae",     "lycophyte")

  # Ferns
  chk("Polypodiaceae",  "fern")
  chk("Dryopteridaceae", "fern")
  chk("Cyatheaceae",    "fern")

  # Gymnosperms
  chk("Pinaceae",     "gymnosperm")
  chk("Cupressaceae", "gymnosperm")
  chk("Cycadaceae",   "gymnosperm")
  chk("Ginkgoaceae",  "gymnosperm")

  # Angiosperms
  chk("Asteraceae", "angiosperm")
  chk("Poaceae",    "angiosperm")
  chk("Fabaceae",   "angiosperm")
  chk("Rosaceae",   "angiosperm")
  chk("Fagaceae",   "angiosperm")

  # Lichens
  chk("Parmeliaceae", "lichen")
  chk("Cladoniaceae", "lichen")
  chk("Physciaceae",  "lichen")

  # Fungi (non-lichen)
  chk("Agaricaceae", "fungus")
  chk("Boletaceae",  "fungus")
  chk("Amanitaceae", "fungus")

  # Algae (differentiated)
  chk("Characeae",    "green_alga")
  chk("Fucaceae",     "brown_alga")
  chk("Corallinaceae", "red_alga")

  # Chromista
  chk("Peronosporaceae", "oomycete")
  chk("Bacillariaceae",  "diatom")

  # Slime moulds
  chk("Physaraceae", "slime_mould")
})


test_that("assign_life_form() returns correct kingdom_group for known families", {
  chk_kg <- function(fam, expected_kg) {
    res <- assign_life_form(fam)
    expect_equal(res$kingdom_group, expected_kg,
                 info = sprintf("family: %s", fam))
  }

  chk_kg("Asteraceae",     "plantae")
  chk_kg("Pinaceae",       "plantae")
  chk_kg("Sphagnaceae",    "plantae")
  chk_kg("Characeae",      "plantae")   # green alga → plantae
  chk_kg("Corallinaceae",  "plantae")   # red alga → plantae
  chk_kg("Parmeliaceae",   "fungi")
  chk_kg("Agaricaceae",    "fungi")
  chk_kg("Fucaceae",       "chromista") # brown alga → chromista
  chk_kg("Peronosporaceae", "chromista")
  chk_kg("Bacillariaceae", "chromista")
  chk_kg("Physaraceae",    "protozoa")
})


test_that("assign_life_form() life_form uses spaces not underscores", {
  res <- assign_life_form("Fucaceae")
  expect_equal(res$life_form, "brown alga")

  res2 <- assign_life_form("Physaraceae")
  expect_equal(res2$life_form, "slime mould")

  res3 <- assign_life_form("Characeae")
  expect_equal(res3$life_form, "green alga")
})


test_that("assign_life_form() uses kingdom fallback when family is NA or unknown", {
  chk <- function(fam, kg, exp_tg, exp_kg) {
    res <- assign_life_form(fam, kg)
    expect_equal(res$taxon_group,   exp_tg,  info = sprintf("fam=%s kg=%s", fam, kg))
    expect_equal(res$kingdom_group, exp_kg,  info = sprintf("fam=%s kg=%s", fam, kg))
  }

  chk(NA_character_, "Fungi",    "fungus",  "fungi")
  chk(NA_character_, "Animalia", "animal",  "animalia")
  chk(NA_character_, "Chromista", "unknown", "chromista")
  chk(NA_character_, "Protozoa",  "unknown", "protozoa")
  chk(NA_character_, "Bacteria",  "unknown", "bacteria")
  chk(NA_character_, "Archaea",   "unknown", "archaea")
  chk(NA_character_, "Plantae",   "unknown", "plantae")
  chk(NA_character_, "Viruses",   "unknown", "viruses")
})


test_that("assign_life_form() returns 'unknown' when family and kingdom both miss", {
  chk_unk <- function(fam, kg = NULL) {
    res <- assign_life_form(fam, kg)
    expect_equal(res$taxon_group,   "unknown")
    expect_equal(res$kingdom_group, "unknown")
    expect_equal(res$life_form,     "unknown")
  }

  chk_unk("Unknowniaceae")
  chk_unk(NA_character_)
  chk_unk(NA_character_, NA_character_)
  chk_unk(NA_character_, "Unknownia")
})


test_that("assign_life_form() is vectorized and returns three equal-length vectors", {
  family  <- c("Sphagnaceae", NA_character_, NA_character_, "Fucaceae")
  kingdom <- c("Plantae",     "Fungi",       "Animalia",   "Chromista")
  result  <- assign_life_form(family, kingdom)

  expect_type(result, "list")
  expect_named(result, c("kingdom_group", "taxon_group", "life_form"))
  expect_equal(length(result$taxon_group),   4L)
  expect_equal(length(result$kingdom_group), 4L)
  expect_equal(length(result$life_form),     4L)

  expect_equal(result$taxon_group,   c("moss",    "fungus", "animal", "brown_alga"))
  expect_equal(result$kingdom_group, c("plantae", "fungi",  "animalia", "chromista"))
  expect_equal(result$life_form,     c("moss",    "fungus", "animal", "brown alga"))
})


test_that("assign_life_form() family hit takes priority over kingdom", {
  res <- assign_life_form("Parmeliaceae", "Fungi")
  expect_equal(res$taxon_group,   "lichen")
  expect_equal(res$kingdom_group, "fungi")

  res2 <- assign_life_form("Pinaceae", "Plantae")
  expect_equal(res2$taxon_group,   "gymnosperm")
  expect_equal(res2$kingdom_group, "plantae")
})


# ---- lookup_genus() tests using a mock register ----

#' Build a minimal mock register and inject it into .taxify_env
setup_mock_register <- function() {
  reg <- data.frame(
    genus         = c("Quercus",     "Boletus",       "Aspergillus"),
    kingdom       = c("Plantae",     "Fungi",         "Fungi"),
    phylum        = c("Tracheophyta","Basidiomycota",  "Ascomycota"),
    class         = c("Magnoliopsida", NA_character_,  NA_character_),
    order         = c("Fagales",     "Boletales",     "Eurotiales"),
    family        = c("Fagaceae",    "Boletaceae",    "Aspergillaceae"),
    kingdom_group = c("plantae",     "fungi",         "fungi"),
    taxon_group   = c("angiosperm",  "fungus",        "fungus"),
    life_form     = c("angiosperm",  "fungus",        "fungus"),
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
  expect_equal(hit$genus,         "Quercus")
  expect_equal(hit$life_form,     "angiosperm")
  expect_equal(hit$taxon_group,   "angiosperm")
  expect_equal(hit$kingdom_group, "plantae")
  expect_equal(hit$family,        "Fagaceae")
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
    genus         = c("Quercus",    "Pinus",      "Boletus"),
    kingdom       = c("Plantae",    "Plantae",    "Fungi"),
    phylum        = c("Tracheophyta","Tracheophyta","Basidiomycota"),
    class         = c("Magnoliopsida","Pinopsida", NA_character_),
    order         = c("Fagales",    "Pinales",    "Boletales"),
    family        = c("Fagaceae",   "Pinaceae",   "Boletaceae"),
    kingdom_group = c("plantae",    "plantae",    "fungi"),
    taxon_group   = c("angiosperm", "gymnosperm", "fungus"),
    life_form     = c("angiosperm", "gymnosperm", "fungus"),
    stringsAsFactors = FALSE
  )

  # Coverage: WFO covers the plant genera but not Boletus, so Boletus is
  # out_of_scope. Mock the coverage file so the test does not depend on a real
  # coverage .vtr being present in the user data dir.
  cov_path <- mock_coverage_vtr(genus = c("Quercus", "Pinus"), backend = "wfo")
  clear_coverage_cache()
  on.exit(clear_coverage_cache(), add = TRUE)

  result <- with_mocked_bindings(
    coverage_vtr_path = function() cov_path,
    taxify(
      c("Quercus robur", "Boletus edulis", "Xxxx yyyyy"),
      backend = "wfo",
      fuzzy = FALSE,
      verbose = FALSE
    )
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
    .taxify_env$register <- NULL  # restore to allow real register on next load
  }, add = TRUE)

  # Ensure register is NOT loaded (empty sentinel — prevents file load)
  .taxify_env$register <- data.frame()

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
    genus         = c("Quercus",    "Pinus"),
    kingdom       = c("Plantae",    "Plantae"),
    phylum        = c("Tracheophyta","Tracheophyta"),
    class         = c("Magnoliopsida","Pinopsida"),
    order         = c("Fagales",    "Pinales"),
    family        = c("Fagaceae",   "Pinaceae"),
    kingdom_group = c("plantae",    "plantae"),
    taxon_group   = c("angiosperm", "gymnosperm"),
    life_form     = c("angiosperm", "gymnosperm"),
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
  # life_form and taxon_group are populated for matched rows when register available
  expect_equal(result$life_form[result$input_name == "Quercus robur"],
               "angiosperm")
  expect_equal(result$life_form[result$input_name == "Pinus sylvestris"],
               "gymnosperm")
  expect_equal(result$taxon_group[result$input_name == "Quercus robur"],
               "angiosperm")
  expect_equal(result$taxon_group[result$input_name == "Pinus sylvestris"],
               "gymnosperm")
})


test_that("taxify() returns a data.frame when the register exists but coverage does not", {
  # Regression: prefilter_out_of_scope() must not collapse `result` to NULL when
  # the coverage .vtr is absent (a clean install, before any download). Returning
  # NULL there turned `result` into a list via `$<-` and crashed as_taxify_result()
  # with "incorrect number of dimensions" on every machine without a cached
  # coverage file.
  bb_path <- mock_backbone_vtr()
  set_backbone_path("wfo", bb_path)
  on.exit({
    set_backbone_path("wfo", NULL)
    .taxify_env$register <- NULL
  }, add = TRUE)

  .taxify_env$register <- data.frame(
    genus = c("Quercus", "Pinus"), kingdom = c("Plantae", "Plantae"),
    family = c("Fagaceae", "Pinaceae"), kingdom_group = c("plantae", "plantae"),
    taxon_group = c("angiosperm", "gymnosperm"),
    life_form = c("angiosperm", "gymnosperm"), stringsAsFactors = FALSE
  )

  result <- with_mocked_bindings(
    coverage_vtr_path = function() file.path(tempdir(), "no_such_coverage.vtr"),
    taxify(c("Quercus robur", "Pinus sylvestris"), backend = "wfo",
           fuzzy = FALSE, verbose = FALSE)
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_true(all(result$match_type %in% c("exact", "exact_ci", "fuzzy")))
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
