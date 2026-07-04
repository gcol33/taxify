# add_trait() attaches a single trait across every source that carries it,
# harmonizing vocabularies (categorical) and units (numeric). These run against
# the bundled example database, where Abies alba carries woodiness (Zanne +
# GIFT), seed mass (Diaz + GIFT), plant height (Diaz + GIFT), and SLA
# (LEDA + GIFT).

mk <- function(sp) data.frame(
  query = sp, accepted_name = sp, matched_name = sp, stringsAsFactors = FALSE
)

trait_ready <- function() {
  p <- file.path(taxify_example_data(), "enrichment", "woodiness", "latest",
                 "woodiness.vtr")
  file.exists(p)
}

test_that("add_trait() errors on input without accepted_name", {
  expect_error(add_trait(data.frame(x = 1), "woodiness"), "accepted_name")
})

test_that("add_trait() records its sources (with match counts) for cite()", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "trait enrichments not available")

  r   <- add_trait(mk("Abies alba"), "woodiness", verbose = FALSE)
  enr <- attr(r, "taxify_meta")$enrichments
  expect_true(length(enr) >= 1L)
  nm       <- vapply(enr, function(e) e$name, character(1L))
  nmatched <- vapply(enr, function(e) as.integer(e$n_matched), integer(1L))
  # Zanne (the "woodiness" enrichment) carries Abies alba -> recorded, matched.
  expect_true("woodiness" %in% nm)
  expect_true(any(nmatched > 0L))
  # A source with no value for the species is recorded with n_matched 0 so that
  # cite() drops it (Abies alba is absent from AusTraits in the example db).
  expect_true(any(nmatched == 0L))
})

test_that("list_traits() advertises the registered traits", {
  lt <- list_traits()
  expect_true(all(c("trait", "kind", "unit", "n_sources", "sources") %in% names(lt)))
  expect_true(all(c("woodiness", "plant_height", "seed_mass", "sla") %in% lt$trait))
  expect_equal(lt$kind[lt$trait == "woodiness"], "categorical")
  expect_equal(lt$kind[lt$trait == "seed_mass"], "numeric")
  expect_equal(lt$unit[lt$trait == "seed_mass"], "mg")
})

test_that("specific_root_area is registered GRooT-only in cm2/g", {
  lt <- list_traits()
  expect_true("specific_root_area" %in% lt$trait)
  expect_equal(lt$kind[lt$trait == "specific_root_area"], "numeric")
  expect_equal(lt$unit[lt$trait == "specific_root_area"], "cm2/g")
  expect_equal(lt$n_sources[lt$trait == "specific_root_area"], 1L)

  ti <- suppressMessages(trait_info("specific_root_area"))
  expect_equal(ti$source, "groot")
  expect_true(all(is.na(ti$caution)))          # no cautioned second source
})

test_that("diet_guild carries EltonTraits alongside AVONET and ReptTraits", {
  ti <- suppressMessages(trait_info("diet_guild"))
  expect_true("elton_traits" %in% ti$source)
  expect_true(all(c("avonet", "elton_traits", "repttraits") %in% ti$source))
  expect_equal(ti$column[ti$source == "elton_traits"], "diet_guild")
})

test_that("ellenberg_salt carries Baseflor on the same 0-9 scale", {
  lt <- list_traits()
  expect_equal(lt$unit[lt$trait == "ellenberg_salt"], "0-9 (classic)")
  ti <- suppressMessages(trait_info("ellenberg_salt"))
  expect_setequal(ti$source, c("floraweb", "ecoflora", "baseflor"))
  expect_equal(ti$column[ti$source == "baseflor"], "salinity")
})

test_that("egg_length and egg_width are registered in mm across three sources", {
  lt <- list_traits()
  for (tr in c("egg_length", "egg_width")) {
    expect_true(tr %in% lt$trait)
    expect_equal(lt$kind[lt$trait == tr], "numeric")
    expect_equal(lt$unit[lt$trait == tr], "mm")
    ti <- suppressMessages(trait_info(tr))
    expect_setequal(ti$source, c("amniote", "repttraits", "chelonians"))
  }
  # column names differ between the reptile sources and the turtle source
  til <- suppressMessages(trait_info("egg_length"))
  expect_equal(til$column[til$source == "chelonians"], "egg_size_length_mm")
})

test_that("brain_mass coalesces COMBINE grams with AnimalTraits kg (x1000)", {
  lt <- list_traits()
  expect_equal(lt$unit[lt$trait == "brain_mass"], "g")
  ti <- suppressMessages(trait_info("brain_mass"))
  expect_setequal(ti$source, c("combine", "animaltraits"))
  expect_equal(ti$column[ti$source == "animaltraits"], "brain_size")
  expect_true(any(grepl("x1000", ti$note)))       # kg -> g conversion noted
})

test_that("reptile/fish life-history sources widen the maturity traits", {
  # age_at_maturity gains turtles (chelonians) and fish (beukhof)
  am <- suppressMessages(trait_info("age_at_maturity"))
  expect_true(all(c("chelonians", "beukhof") %in% am$source))
  # longevity gains beukhof fish ages
  lg <- suppressMessages(trait_info("longevity"))
  expect_true("beukhof" %in% lg$source)
  # reproductive_frequency widened from 2 to 6 sources, same per-year unit
  rf <- suppressMessages(trait_info("reproductive_frequency"))
  expect_setequal(rf$source,
                  c("amniote", "combine", "anage", "pantheria",
                    "repttraits", "chelonians"))
  expect_equal(list_traits()$unit[list_traits()$trait == "reproductive_frequency"],
               "per year")
})

test_that("clutch_litter_size gains turtles and birds without double-counting", {
  ti <- suppressMessages(trait_info("clutch_litter_size"))
  expect_true(all(c("chelonians", "birdbase") %in% ti$source))
  # lizard_traits is the same underlying source as repttraits (already present),
  # so it must NOT be added as a duplicate
  expect_false("lizard_traits" %in% ti$source)
  expect_equal(ti$column[ti$source == "birdbase"], "clutch_mean")
})

test_that("pollination_vector widens with floraweb and austraits, not gift/bien", {
  ti <- suppressMessages(trait_info("pollination_vector"))
  expect_true(all(c("floraweb", "austraits") %in% ti$source))
  # GIFT/BIEN carry only coarse biotic/abiotic and must be excluded
  expect_false(any(c("gift", "bien") %in% ti$source))
  expect_setequal(ti$source, c("baseflor", "ecoflora", "floraweb", "austraits"))
  # the shared regex vocabulary now recognises named insect taxa
  reg <- taxify:::.trait_registry()
  m <- reg$pollination_vector$sources$austraits$map
  expect_equal(m(c("bee", "beetle", "fly", "wind", "abiotic", "bird")),
               c("insect", "insect", "insect", "wind", NA, NA))
})

test_that("male_maturity is the male analogue of age_at_maturity (days -> yr)", {
  lt <- list_traits()
  expect_true("male_maturity" %in% lt$trait)
  expect_equal(lt$kind[lt$trait == "male_maturity"], "numeric")
  expect_equal(lt$unit[lt$trait == "male_maturity"], "yr")
  ti <- suppressMessages(trait_info("male_maturity"))
  expect_setequal(ti$source, c("anage", "amniote", "combine"))
  expect_equal(ti$column[ti$source == "anage"], "male_maturity_d")
  expect_true(all(grepl("365.25", ti$note)))       # days -> years on every source
})

test_that("incubation_period is a days trait distinct from gestation_incubation", {
  lt <- list_traits()
  expect_equal(lt$unit[lt$trait == "incubation_period"], "days")
  ti <- suppressMessages(trait_info("incubation_period"))
  expect_setequal(ti$source, c("amniote", "chelonians"))
  expect_equal(ti$column[ti$source == "amniote"], "incubation_d")
  # the combined gestation-or-incubation trait stays separate
  gi <- suppressMessages(trait_info("gestation_incubation"))
  expect_equal(gi$column[gi$source == "amniote"], "gestation_d")
})

test_that("diet_breadth coalesces mammal and bird category counts", {
  lt <- list_traits()
  expect_equal(lt$unit[lt$trait == "diet_breadth"], "count")
  ti <- suppressMessages(trait_info("diet_breadth"))
  expect_setequal(ti$source, c("combine", "pantheria", "birdbase"))
  # birdbase covers birds (disjoint taxa) -> grounded on the count distribution
  expect_true(any(grepl("disjoint", ti$note)))
})

test_that("tongue_length and aspect_ratio are registered numeric traits", {
  lt <- list_traits()
  expect_equal(lt$unit[lt$trait == "tongue_length"], "mm")
  tt <- suppressMessages(trait_info("tongue_length"))
  expect_setequal(tt$source, c("bee_ostwald", "eupolltrait"))
  expect_equal(lt$unit[lt$trait == "aspect_ratio"], "index")
  ar <- suppressMessages(trait_info("aspect_ratio"))
  expect_setequal(ar$source, c("beukhof", "quimbayo"))
})

test_that("foraging_mode maps ACT/AMB/Mixed without double-counting lizard_traits", {
  lt <- list_traits()
  expect_equal(lt$kind[lt$trait == "foraging_mode"], "categorical")
  ti <- suppressMessages(trait_info("foraging_mode"))
  expect_setequal(ti$source, c("repttraits", "chelonians"))
  expect_false("lizard_traits" %in% ti$source)     # same Oskyrko source as repttraits
  reg <- taxify:::.trait_registry()
  m <- reg$foraging_mode$sources$repttraits$map
  expect_equal(m(c("ACT", "AMB", "Mixed", "")),
               c("active", "ambush", "mixed", NA))
})

test_that("diet_guild widens with chelonians and blanchard via ordered-regex diet", {
  ti <- suppressMessages(trait_info("diet_guild"))
  expect_true(all(c("chelonians", "blanchard") %in% ti$source))
  reg <- taxify:::.trait_registry()
  m <- reg$diet_guild$sources$chelonians$map
  # compound labels take the primary guild by pattern order; ant predator -> carnivore
  expect_equal(m(c("Omnivorous", "Carnivorous", "Herbivorous",
                   "Omnivorous to Carnivorous", "predator")),
               c("omnivore", "carnivore", "herbivore", "omnivore", "carnivore"))
})

test_that("reproductive_mode collapses shark strategies to a parity scheme", {
  lt <- list_traits()
  expect_equal(lt$kind[lt$trait == "reproductive_mode"], "categorical")
  ti <- suppressMessages(trait_info("reproductive_mode"))
  expect_setequal(ti$source, c("repttraits", "sharkipedia"))
  reg <- taxify:::.trait_registry()
  m <- reg$reproductive_mode$sources$sharkipedia$map
  expect_equal(m(c("Oviparous", "Matrotrophy", "Aplacental Viviparity",
                   "ovoviviparous", "Placentotrophy")),
               c("oviparous", "viviparous", "viviparous",
                 "ovoviviparous", "viviparous"))
})

test_that("coral habitat traits share a clean vocabulary", {
  lt <- list_traits()
  for (tr in c("coloniality", "wave_exposure", "water_clarity")) {
    ti <- suppressMessages(trait_info(tr))
    expect_setequal(ti$source, c("coral_traits", "octocoral"))
  }
  reg <- taxify:::.trait_registry()
  wm <- reg$wave_exposure$sources$coral_traits$map
  expect_equal(wm(c("protected", "exposed", "broad", "both")),
               c("protected", "exposed", "intermediate", "intermediate"))
})

test_that("head_length and head_width are mm morphometrics", {
  lt <- list_traits()
  for (tr in c("head_length", "head_width")) {
    expect_equal(lt$unit[lt$trait == tr], "mm")
    ti <- suppressMessages(trait_info(tr))
    expect_setequal(ti$source, c("huang_amph", "saproxylic"))
  }
})

test_that("depth_min/depth_max gain coral occurrence-depth sources", {
  dmin <- suppressMessages(trait_info("depth_min"))
  dmax <- suppressMessages(trait_info("depth_max"))
  expect_true(all(c("coral_traits", "octocoral") %in% dmin$source))
  expect_true(all(c("coral_traits", "octocoral") %in% dmax$source))
  expect_equal(dmin$column[dmin$source == "coral_traits"], "depth_upper_m")
  expect_equal(dmax$column[dmax$source == "coral_traits"], "depth_lower_m")
})

test_that("caudal_fin_shape and voltinism coalesce their two sources", {
  cf <- suppressMessages(trait_info("caudal_fin_shape"))
  expect_setequal(cf$source, c("beukhof", "quimbayo"))
  reg <- taxify:::.trait_registry()
  m <- reg$caudal_fin_shape$sources$quimbayo$map
  expect_equal(m(c("truncated", "lanceolated", "rounded", "forked")),
               c("truncate", "lanceolate", "rounded", "forked"))
  vo <- suppressMessages(trait_info("voltinism"))
  expect_setequal(vo$source, c("arthropod_traits", "eupolltrait"))
  expect_equal(list_traits()$unit[list_traits()$trait == "voltinism"], "per year")
})

test_that("single-source vertebrate behaviour traits are registered", {
  lt <- list_traits()
  expect_true(all(c("migration", "flightless", "venomous", "sociality") %in% lt$trait))
  expect_equal(suppressMessages(trait_info("migration"))$source, "avonet")
  expect_equal(suppressMessages(trait_info("flightless"))$source, "birdbase")
  expect_equal(suppressMessages(trait_info("venomous"))$source, "repttraits")
})

test_that("prokaryote traits (Madin) map cleanly, including tricky substrings", {
  lt <- list_traits()
  expect_true(all(c("gram_stain", "oxygen_metabolism", "cell_shape",
                    "optimal_growth_temperature", "genome_size") %in% lt$trait))
  expect_equal(lt$unit[lt$trait == "genome_size"], "bp")
  expect_equal(lt$unit[lt$trait == "optimal_growth_temperature"], "deg C")
  reg <- taxify:::.trait_registry()
  # microaerophilic / anaerobic tested before aerobic (both contain "aero")
  om <- reg$oxygen_metabolism$sources$madin$map
  expect_equal(om(c("obligate aerobic", "obligate anaerobic", "microaerophilic",
                    "facultative")),
               c("aerobic", "anaerobic", "microaerophilic", "facultative"))
  # coccobacillus tested before bacillus and coccus
  cs <- reg$cell_shape$sources$madin$map
  expect_equal(cs(c("coccobacillus", "bacillus", "coccus")),
               c("coccobacillus", "bacillus", "coccus"))
})

test_that("thermal_max gains the pottier amphibian source", {
  ti <- suppressMessages(trait_info("thermal_max"))
  expect_setequal(ti$source, c("globtherm", "pottier"))
  expect_equal(ti$column[ti$source == "pottier"], "heat_tolerance_c")
})

test_that("trait_info() returns one row per source with harmonization notes", {
  ti <- suppressMessages(trait_info("seed_mass"))
  expect_true(all(c("source", "enrichment", "column", "note") %in% names(ti)))
  expect_setequal(ti$source, c("diaz", "gift", "austraits", "bien", "brot", "ecoflora"))
  expect_true(any(grepl("x1000", ti$note)))          # GIFT g -> mg conversion noted
  expect_error(suppressMessages(trait_info("nope")), "unknown trait")
})

test_that("wide mode attaches one harmonized column per source (categorical)", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  r <- add_trait(mk("Abies alba"), "woodiness", mode = "wide", verbose = FALSE)
  expect_true(all(c("woodiness_zanne", "woodiness_gift") %in% names(r)))
  # Zanne 'woody' and GIFT 'woody' both map to canonical 'woody'.
  expect_equal(r$woodiness_zanne, "woody")
  expect_equal(r$woodiness_gift, "woody")
})

test_that("mode defaults to coalesce (one value plus provenance columns)", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  r <- add_trait(mk("Abies alba"), "seed_mass", verbose = FALSE)
  expect_true(all(c("seed_mass", "seed_mass_unit", "seed_mass_sources",
                    "seed_mass_n") %in% names(r)))
  expect_equal(r$seed_mass_unit, "mg")            # canonical unit column
  expect_false("seed_mass_diaz" %in% names(r))    # not wide by default
})

test_that("numeric sources are converted to the canonical unit", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  # Seed mass: Diaz already mg; GIFT grams x1000 -> mg.
  sm <- add_trait(mk("Abies alba"), "seed_mass", mode = "wide", verbose = FALSE)
  expect_type(sm$seed_mass_diaz, "double")
  expect_type(sm$seed_mass_gift, "double")
  expect_equal(sm$seed_mass_diaz, 62.007, tolerance = 1e-3)
  expect_equal(sm$seed_mass_gift, 73.9425, tolerance = 1e-3)   # 0.0739425 * 1000

  # SLA: LEDA mm2/mg; GIFT cm2/g x0.1 -> mm2/mg. Same species -> equal here.
  sl <- add_trait(mk("Abies alba"), "sla", mode = "wide", verbose = FALSE)
  expect_equal(sl$sla_leda, 5.87, tolerance = 1e-3)
  expect_equal(sl$sla_gift, 5.87, tolerance = 1e-3)            # 58.7 * 0.1
})

test_that("coalesce defaults to median for numeric traits", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  # Default numeric combine is median across all sources that carry the row.
  w <- add_trait(mk("Abies alba"), "seed_mass", mode = "wide", verbose = FALSE)
  src_cols  <- setdiff(grep("^seed_mass_", names(w), value = TRUE),
                       c("seed_mass_unit", "seed_mass_caution"))
  wide_vals <- unlist(w[1, src_cols], use.names = FALSE)
  wide_vals <- wide_vals[!is.na(wide_vals)]

  d <- add_trait(mk("Abies alba"), "seed_mass", mode = "coalesce", verbose = FALSE)
  expect_true(all(c("seed_mass", "seed_mass_sources", "seed_mass_n") %in% names(d)))
  expect_gte(d$seed_mass_n, 2L)
  expect_equal(d$seed_mass_n, length(wide_vals))
  expect_equal(d$seed_mass, stats::median(wide_vals), tolerance = 1e-6)
  expect_match(d$seed_mass_sources, "diaz")
  expect_match(d$seed_mass_sources, "gift")
})

test_that("combine = 'first' honours priority order", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  d <- add_trait(mk("Abies alba"), "seed_mass", mode = "coalesce",
                 combine = "first", verbose = FALSE)
  expect_equal(d$seed_mass_sources, "diaz")       # default priority diaz > gift
  expect_equal(d$seed_mass, 62.007, tolerance = 1e-3)

  g <- add_trait(mk("Abies alba"), "seed_mass", mode = "coalesce",
                 combine = "first", priority = "gift", verbose = FALSE)
  expect_equal(g$seed_mass_sources, "gift")
  expect_equal(g$seed_mass, 73.9425, tolerance = 1e-3)
})

test_that("combine rejects reducers that do not fit the trait kind", {
  expect_error(add_trait(mk("Abies alba"), "seed_mass", mode = "coalesce",
                         combine = "vote"), "not valid for a numeric")
  expect_error(add_trait(mk("Abies alba"), "woodiness", mode = "coalesce",
                         combine = "median"), "not valid for a categorical")
})

test_that("sources= restricts which sources are joined", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  r <- add_trait(mk("Abies alba"), "woodiness", sources = "gift",
                 mode = "wide", verbose = FALSE)
  expect_true("woodiness_gift" %in% names(r))
  expect_false("woodiness_zanne" %in% names(r))
})

test_that("unknown trait and unknown source error informatively", {
  expect_error(add_trait(mk("Abies alba"), "woodyness"),
               "unknown trait|Did you mean")
  expect_error(add_trait(mk("Abies alba"), "woodiness", sources = "bogus"),
               "unknown source")
})

test_that("absent species get NA across sources", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  r <- add_trait(mk("Zzznotaspecies fakename"), "seed_mass", mode = "wide",
                 verbose = FALSE)
  expect_true(is.na(r$seed_mass_diaz))
  expect_true(is.na(r$seed_mass_gift))
})

test_that("EIVE dimensions are their own add_trait() traits, apart from ellenberg", {
  reg_traits <- list_traits()$trait
  expect_true(all(c("eive_light", "eive_temperature", "eive_moisture",
                    "eive_reaction", "eive_nutrients") %in% reg_traits))
  # EIVE is single-source and never a source on the classic ellenberg_* traits.
  el <- suppressMessages(trait_info("ellenberg_light"))
  expect_false("eive" %in% el$enrichment)
  ei <- suppressMessages(trait_info("eive_light"))
  expect_equal(ei$enrichment, "eive")
})

test_that("trait_info() carries a caution column; root traits gain cautioned sources", {
  ti <- suppressMessages(trait_info("root_diameter"))
  expect_true("caution" %in% names(ti))
  expect_setequal(ti$source, c("groot", "austraits"))
  expect_true(is.na(ti$caution[ti$source == "groot"]))
  expect_match(ti$caution[ti$source == "austraits"], "maximum root diameter")

  rn <- suppressMessages(trait_info("root_n_concentration"))
  expect_match(rn$caution[rn$source == "austraits"], "whole-root N")
  rd <- suppressMessages(trait_info("rooting_depth"))
  expect_match(rd$caution[rd$source == "brot"], "typical depth")
})

test_that("combine = 'complete' selects the most populated source (ties by priority)", {
  per <- list(a = c(1, NA, NA), b = c(2, 3, NA))       # b more complete
  co  <- .coalesce_sources(per, c("a", "b"), "numeric", "complete")
  expect_equal(co$best, "b")
  expect_equal(co$value, c(2, 3, NA))
  expect_equal(co$source, c("b", "b", NA))
  expect_equal(co$n, c(1L, 1L, 0L))

  per2 <- list(a = c(1, NA), b = c(NA, 2))             # equal counts -> first
  co2  <- .coalesce_sources(per2, c("a", "b"), "numeric", "complete")
  expect_equal(co2$best, "a")
})

test_that("discordant sources are not blended: caution explains the method choice", {
  per  <- list(groot = c(0.3, 0.3, NA), austraits = c(4, NA, 5))
  cvec <- c(groot = NA_character_, austraits = "maximum diameter, incl. coarse roots")
  co   <- .coalesce_sources(per, c("groot", "austraits"), "numeric", "complete")
  expect_equal(co$best, "groot")                       # 2 vs 2 -> priority (groot)
  expect_equal(co$value, c(0.3, 0.3, NA))              # verbatim, not a blend

  cr <- .trait_caution_col(co, cvec, disc = TRUE, combine = "complete")
  expect_match(cr[1], "measure this differently")
  expect_match(cr[1], "maximum diameter")
  expect_true(is.na(cr[3]))                            # no value -> no caution
})

test_that("add_zanne() is the source-named woodiness door", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  r <- add_zanne(mk("Quercus robur"), verbose = FALSE)
  expect_true("woodiness" %in% names(r))
  expect_equal(r$woodiness, "woody")
})
