# Per-door integration coverage, offline against the bundled example database.
# For each bundled single-source enrichment, this probes a species the .vtr
# covers well, calls its add_*() door, and asserts the door attaches its
# headline columns with a value in each, plus a value in most of the rest. This
# catches a door wired to the wrong enrichment key and a col_map whose source
# columns are misspelled (which would silently attach all-NA columns). The
# heavier real-backbone joins live in tests/e2e/, which need full backbones and
# network and are not run here.

# Bundled single-source doors whose function is add_<key> and which take only
# (x, [cols], verbose), each with headline columns of its own that the door must
# carry a value in for the probe species. Naming the columns is what makes the
# check discriminating: a door that still populates one passthrough column while
# every trait column it claims to attach comes back NA fails here. Group-filtered
# doors (griis, glonaf, wcvp, alien_first_records, common_names) need a group
# argument and are covered elsewhere.
.door_headline_cols <- list(
  zanne            = "woodiness",
  iucn             = "conservation_status",
  diaz_traits      = c("seed_mass_mg", "plant_height_m"),
  leda             = c("seed_mass_mg", "sla_mm2_mg"),
  gift             = c("gift_woodiness_1", "gift_plant_height_max"),
  eive             = c("eive_light", "eive_moisture"),
  avonet           = c("beak_length", "avonet_body_mass_g"),
  pantheria        = c("pantheria_body_mass_g", "litter_size"),
  amphibio         = c("body_size_mm", "litter_size"),
  anage            = c("max_longevity_yr", "anage_body_mass_g"),
  animaltraits     = "animaltraits_body_mass_kg",
  arthropod_traits = c("arthropod_body_size_mm", "arthropod_voltinism"),
  austraits        = c("austraits_woodiness", "austraits_plant_height_m"),
  baseflor         = c("pollination_vector", "flower_colour"),
  bien             = c("bien_plant_height_m", "bien_wood_density_g_cm3"),
  ecoflora         = c("life_form_uk", "seed_weight_mg_uk"),
  elton_traits     = c("elton_body_mass_g", "diet_inv"),
  fishbase         = c("fb_body_length_cm", "fb_trophic_level"),
  fishmorph        = c("fish_max_body_length", "fish_body_elongation"),
  floraweb         = c("life_form_de", "ell_light_de"),
  funguild         = c("trophic_mode", "guild"),
  groot            = c("root_diameter", "specific_root_length"),
  kew_sid          = c("sid_thousand_seed_weight", "sid_storage_behaviour"),
  leptraits        = c("wingspan_mm", "voltinism"),
  repttraits       = c("svl_mm", "diet"),
  sealifebase      = c("sb_body_length_cm", "sb_trophic_level"),
  algae_traits     = c("algae_body_size_cm", "algae_growth_form")
)
# Genus-keyed doors (fungal_traits, fungalroot) use a different join and are
# covered by test-fungalroot.R and test-trait-genus-join.R.

# The best-covered species of an enrichment .vtr -- the row carrying the most
# non-NA trait values -- or NULL when the enrichment is not bundled in the
# example database. Taking the best-covered row rather than the first populated
# one keeps the probe on a species whose headline columns the fixture fills.
door_probe_species <- function(key) {
  p <- file.path(taxify_example_data(), "enrichment", key, "latest",
                 paste0(key, ".vtr"))
  if (!file.exists(p)) return(NULL)
  d <- tryCatch(vectra::collect(utils::head(vectra::tbl(p), 200L)),
                error = function(e) NULL)
  if (is.null(d) || !"canonical_name" %in% names(d) || nrow(d) == 0L) {
    return(NULL)
  }
  trait_cols <- setdiff(names(d), c("canonical_name", "accepted_name", "genus"))
  if (!length(trait_cols)) return(d$canonical_name[1L])
  filled <- vapply(seq_len(nrow(d)), function(i) {
    sum(!is.na(unlist(d[i, trait_cols, drop = FALSE])))
  }, integer(1L))
  d$canonical_name[which.max(filled)]
}

test_that("each bundled door attaches columns and recovers its headline values", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  tested <- 0L
  for (key in names(.door_headline_cols)) {
    sp <- door_probe_species(key)
    if (is.null(sp)) next
    fn <- get(paste0("add_", key), envir = asNamespace("taxify"))
    # Provide genus too, so genus-keyed doors (fungal_traits) can join.
    x  <- data.frame(accepted_name = sp, genus = sub(" .*", "", sp),
                     stringsAsFactors = FALSE)
    out <- fn(x, verbose = FALSE)

    expect_s3_class(out, "data.frame")
    expect_true(ncol(out) > 2L, info = paste0(key, ": attaches columns"))

    added     <- setdiff(names(out), c("accepted_name", "genus"))
    recovered <- added[vapply(added, function(cc) any(!is.na(out[[cc]])),
                              logical(1L))]

    for (cc in .door_headline_cols[[key]]) {
      expect_true(cc %in% added,
                  info = paste0(key, ": attaches ", cc))
      expect_true(cc %in% recovered,
                  info = paste0(key, ": recovers ", cc, " for ", sp))
    }
    # Some trait columns are legitimately empty for any one species, so the
    # blanket bar is a majority rather than every column.
    expect_gt(length(recovered), length(added) / 2,
              label = paste0(key, ": columns recovering a value for ", sp))
    tested <- tested + 1L
  }
  # Guard against the probe silently testing nothing (wrong example-db path).
  skip_if(tested == 0L, "no bundled enrichments found")
  expect_gt(tested, 5L)
})
