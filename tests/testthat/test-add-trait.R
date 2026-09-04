# add_trait() attaches a single trait across every source that carries it,
# harmonizing vocabularies (categorical) and units (numeric). These run against
# the bundled example database, where Abies alba carries woodiness (Zanne +
# GIFT), seed mass (Diaz + GIFT), plant height (Diaz + GIFT), and SLA
# (LEDA + GIFT).

mk <- function(sp) data.frame(
  query = sp, accepted_name = sp, matched_name = sp, stringsAsFactors = FALSE
)

trait_ready <- function() {
  p <- file.path(taxify_example_data(), "enrichment", "zanne", "latest",
                 "zanne.vtr")
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
  # Zanne (the "zanne" enrichment) carries Abies alba -> recorded, matched.
  expect_true("zanne" %in% nm)
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
  expect_setequal(ti$source, c("globtherm", "pottier", "thermofresh"))
  expect_equal(ti$column[ti$source == "pottier"], "heat_tolerance_c")
})

test_that("thermofresh feeds both thermal limits from its CTmax/CTmin columns", {
  # Calibrated against globtherm before wiring: ratio 1.00 on 135 shared species
  # for ctmax, 1.00 on 16 for ctmin. The source's lethal columns (lt50, ltmax,
  # ltmin) are deliberately left out, so one record type feeds each trait.
  tmax <- suppressMessages(trait_info("thermal_max"))
  tmin <- suppressMessages(trait_info("thermal_min"))
  expect_equal(tmax$column[tmax$source == "thermofresh"], "ctmax")
  expect_equal(tmin$column[tmin$source == "thermofresh"], "ctmin")
  expect_setequal(tmin$source, c("globtherm", "thermofresh"))
  # Both limits stay on one unit, so the coalesce never mixes scales.
  lt <- list_traits()
  expect_equal(lt$unit[lt$trait == "thermal_max"], "deg C")
  expect_equal(lt$unit[lt$trait == "thermal_min"], "deg C")
})

test_that("forearm_length is registered from the three mammal sources", {
  # combine and pantheria both carried the standard bat measurement without any
  # trait claiming it; they agree at ratio 1.00 on 972 shared species.
  ti <- suppressMessages(trait_info("forearm_length"))
  expect_setequal(ti$source, c("combine", "pantheria", "eurobat"))
  expect_equal(ti$column[ti$source == "pantheria"], "x8_1_adultforearmlen_mm")
  lt <- list_traits()
  expect_equal(lt$unit[lt$trait == "forearm_length"], "mm")
})

test_that("eurobat and fishtraits reach the traits they calibrated against", {
  for (tr in c("body_mass", "longevity", "clutch_litter_size", "diet_guild")) {
    ti <- suppressMessages(trait_info(tr))
    expect_true("eurobat" %in% ti$source, info = tr)
  }
  for (tr in c("longevity", "age_at_maturity")) {
    ti <- suppressMessages(trait_info(tr))
    expect_true("fishtraits" %in% ti$source, info = tr)
  }
  # fishtraits' temperature columns are a climatic niche, not organismal
  # tolerance (min_temp_c runs to -22.5 deg C), so they stay out of the thermal
  # traits and ship as the climatic_temp_* family instead; its max_length_cm is
  # the same data as fishbase.
  for (tr in c("thermal_min", "thermal_max", "body_length")) {
    ti <- suppressMessages(trait_info(tr))
    expect_false("fishtraits" %in% ti$source, info = tr)
  }
  # copepod_traits is the Brun compilation that zooplankton already ingested.
  for (tr in c("body_length", "clutch_litter_size", "egg_length")) {
    ti <- suppressMessages(trait_info(tr))
    expect_false("copepod_traits" %in% ti$source, info = tr)
  }
})

test_that("eurobat diet maps onto the shared guild vocabulary", {
  reg <- taxify:::.trait_registry()
  m   <- reg$diet_guild$sources$eurobat$map
  expect_equal(m(c("Insectivorous", "Frugivorous")),
               c("invertivore", "frugivore"))
})

test_that("the climatic niche stays separate from organismal thermal tolerance", {
  # Range climate and thermal tolerance are both deg C, so nothing but the
  # quantity keeps them apart: a species' range climate sits well inside what it
  # can survive. fishtraits' warmest-month value is 0.88x the CTmax thermofresh
  # measures on the same species.
  cmean <- suppressMessages(trait_info("climatic_temp_mean"))
  expect_setequal(cmean$source,
                  c("arthropod_traits", "repttraits", "hydraulics"))
  lt <- list_traits()
  expect_equal(lt$unit[lt$trait == "climatic_temp_mean"], "deg C")

  # The family is the three range-climate traits, all deg C.
  fam <- grep("^climatic_", lt$trait, value = TRUE)
  expect_setequal(fam, c("climatic_temp_mean", "climatic_temp_min",
                         "climatic_temp_max"))
  expect_true(all(lt$unit[lt$trait %in% fam] == "deg C"))

  # No source may feed both families: that is the confusion the split prevents.
  for (tr in c("thermal_max", "thermal_min")) {
    th <- suppressMessages(trait_info(tr))
    expect_false(any(th$source %in% c("fishtraits", "arthropod_traits")), info = tr)
  }

  # arthropod_traits contributes only its annual mean. Its thermal_minimum /
  # thermal_maximum are the spatial spread of that same annual-mean surface (a
  # niche breadth), not a within-year extreme, so they join nothing.
  expect_equal(cmean$column[cmean$source == "arthropod_traits"], "thermal_mean")
  reg <- taxify:::.trait_registry()
  for (tr in names(reg)) {
    for (sn in names(reg[[tr]]$sources)) {
      s <- reg[[tr]]$sources[[sn]]
      if (identical(s$enrichment, "arthropod_traits")) {
        expect_false(
          s$col %in% c("thermal_minimum", "thermal_maximum", "thermal_range"),
          info = sprintf("trait '%s' uses arthropod col '%s'", tr, s$col)
        )
      }
    }
  }
})

test_that("fishtraits climatic temps register as the range-climate min and max", {
  for (tr in c("climatic_temp_min", "climatic_temp_max")) {
    ti <- suppressMessages(trait_info(tr))
    expect_equal(ti$source, "fishtraits", info = tr)
    lt <- list_traits()
    expect_equal(lt$unit[lt$trait == tr], "deg C", info = tr)
  }
  reg <- taxify:::.trait_registry()
  expect_equal(reg$climatic_temp_min$sources$fishtraits$col, "min_temp_c")
  expect_equal(reg$climatic_temp_max$sources$fishtraits$col, "max_temp_c")

  # Taken verbatim, in the source's own unit: the map rescales nothing.
  for (tr in c("climatic_temp_min", "climatic_temp_max")) {
    m <- reg[[tr]]$sources$fishtraits$map
    expect_equal(m(c("20.4", "-22.5", "32")), c(20.4, -22.5, 32), info = tr)
  }
  # The -1 no-range code is the parser's job, where the whole range-derived
  # block is in scope. A map sees one column and would destroy the genuine
  # -1 January minima, so it must not try.
  expect_equal(reg$climatic_temp_min$sources$fishtraits$map("-1"), -1)
})

test_that("chromosome_number ships from kew_cvalues alone (CCDB is build-only)", {
  # CCDB's counts are correct now, but it carries no licence and so has no
  # published .vtr. It reaches users through add_ccdb(), not the verb.
  ti <- suppressMessages(trait_info("chromosome_number"))
  expect_equal(ti$source, "kew_cvalues")
  expect_equal(ti$column, "chromosome_2n")
  expect_false("ccdb" %in% ti$source)
})

test_that("plant 1C genome size stays out of the prokaryote genome_size trait", {
  # 1 pg = 0.978 Gbp is a constant, but a plant 1C is the holoploid gametic
  # complement (it scales with ploidy) while a prokaryote genome size is one
  # haploid chromosome. Disjoint taxa would hide that, not expose it.
  ti <- suppressMessages(trait_info("genome_size"))
  expect_equal(ti$source, "madin")
  expect_false("kew_cvalues" %in% ti$source)
  lt <- list_traits()
  expect_equal(lt$unit[lt$trait == "genome_size"], "bp")
  # No trait may pick up kew's picogram column under a base-pair unit.
  reg <- taxify:::.trait_registry()
  for (tr in names(reg)) {
    for (sn in names(reg[[tr]]$sources)) {
      s <- reg[[tr]]$sources[[sn]]
      if (identical(s$enrichment, "kew_cvalues")) {
        expect_false(s$col == "genome_size_1c_pg",
                     info = sprintf("trait '%s' uses kew 1C picograms", tr))
      }
    }
  }
})

test_that("no build-only source feeds the cross-source trait verb", {
  # Every trait source must be a downloadable .vtr. A source reachable only
  # where taxifydb is installed would make add_trait() return a different
  # number on two machines running the same code, with no error.
  bo  <- taxify:::.build_only_enrichments()
  reg <- taxify:::.trait_registry()
  for (tr in names(reg)) {
    for (sn in names(reg[[tr]]$sources)) {
      enr <- reg[[tr]]$sources[[sn]]$enrichment
      expect_false(enr %in% bo,
                   info = sprintf("trait '%s' uses build-only source '%s'",
                                  tr, enr))
    }
  }
})

test_that("wingspan corrects the mislabelled leptraits cm column to mm", {
  lt <- list_traits()
  expect_equal(lt$unit[lt$trait == "wingspan"], "mm")
  ti <- suppressMessages(trait_info("wingspan"))
  expect_equal(ti$source, "leptraits")
  expect_match(ti$note, "values are cm")           # documents the x10 fix
  reg <- taxify:::.trait_registry()
  m <- reg$wingspan$sources$leptraits$map
  expect_equal(m(c("9.4", "4.5")), c(94, 45))       # cm -> mm
})

test_that("fungal_trophic_mode coalesces FUNGuild and FungalTraits", {
  ti <- suppressMessages(trait_info("fungal_trophic_mode"))
  expect_setequal(ti$source, c("funguild", "fungal_traits"))
  reg <- taxify:::.trait_registry()
  fg <- reg$fungal_trophic_mode$sources$funguild$map
  expect_equal(fg(c("Pathotroph", "Saprotroph", "Symbiotroph", "Pathotroph-Saprotroph")),
               c("pathotroph", "saprotroph", "symbiotroph", "mixed"))
  ft <- reg$fungal_trophic_mode$sources$fungal_traits$map
  expect_equal(ft(c("wood_saprotroph", "plant_pathogen", "ectomycorrhizal")),
               c("saprotroph", "pathotroph", "symbiotroph"))
})

test_that("leaf dimensions, fish, prokaryote and bee traits are registered", {
  lt <- list_traits()
  for (tr in c("leaf_length", "leaf_width")) expect_equal(lt$unit[lt$trait == tr], "mm")
  expect_equal(suppressMessages(trait_info("feeding_mode"))$source, "beukhof")
  expect_equal(suppressMessages(trait_info("mouth_position"))$source, "quimbayo")
  expect_equal(suppressMessages(trait_info("air_breathing"))$source, "fishbase")
  expect_setequal(suppressMessages(trait_info("motility"))$source, c("madin", "bacdive"))
  expect_equal(suppressMessages(trait_info("lecty"))$source, "eupolltrait")
  reg <- taxify:::.trait_registry()
  ab <- reg$air_breathing$sources$fishbase$map
  expect_equal(ab(c("WaterAssumed", "Facultative", "Obligate", "FacultativeObligate")),
               c("none", "facultative", "obligate", "facultative"))
})

test_that("BacDive is wired as a second prokaryote source alongside Madin", {
  for (tr in c("gram_stain", "oxygen_metabolism", "cell_shape", "motility",
               "optimal_growth_temperature", "optimal_growth_ph")) {
    expect_true("bacdive" %in% suppressMessages(trait_info(tr))$source,
                info = tr)
  }
  for (tr in c("cell_length", "cell_width"))
    expect_setequal(suppressMessages(trait_info(tr))$source, c("rimet_phyto", "bacdive"))
  reg <- taxify:::.trait_registry()
  # BacDive cell_shape tokens fold to the shared vocabulary.
  cs <- reg$cell_shape$sources$bacdive$map
  expect_equal(cs(c("rod", "ovoid", "oval", "sphere", "curved", "spiral")),
               c("bacillus", "coccobacillus", "coccobacillus", "coccus", "vibrio", "spiral"))
  # BacDive motility is pre-normalized, so it needs its own map.
  mo <- reg$motility$sources$bacdive$map
  expect_equal(mo(c("motile", "non-motile")), c("motile", "non-motile"))
})

test_that("ITALIC lichen descriptors are registered as distinct lichen traits", {
  reg <- taxify:::.trait_registry()
  for (tr in c("lichen_growth_form", "substrate", "photobiont", "reproductive_strategy"))
    expect_equal(reg[[tr]]$sources$italic$enrichment, "italic", info = tr)
  # Kept separate from the plant growth_form and animal reproductive_mode traits.
  expect_false("italic" %in% names(reg$growth_form$sources))
  expect_false("italic" %in% names(reg$reproductive_mode$sources))
  # Growth form: lichenicolous / non-lichenised are not thallus forms -> NA.
  gf <- reg$lichen_growth_form$sources$italic$map
  expect_equal(gf(c("Crustose", "Foliose, narrow lobed", "Fruticose", "Lichenicolous fungus")),
               c("crustose", "foliose", "fruticose", NA))
  # Photobiont trap: "green algae other than Trentepohlia" must not map to Trentepohlia.
  pb <- reg$photobiont$sources$italic$map
  expect_equal(pb(c("green algae other than Trentepohlia", "Trentepohlia",
                    "cyanobacteria, coccaceous (e.g. Gloeocapsa )")),
               c("green algae", "Trentepohlia", "cyanobacteria"))
  rs <- reg$reproductive_strategy$sources$italic$map
  expect_equal(rs(c("mainly sexual, or asexual by conidia", "mainly asexual, by soredia")),
               c("sexual", "asexual"))
})

test_that("trait_info() returns one row per source with harmonization notes", {
  ti <- suppressMessages(trait_info("seed_mass"))
  expect_true(all(c("source", "enrichment", "column", "note") %in% names(ti)))
  expect_setequal(ti$source, c("diaz", "gift", "austraits", "bien", "brot", "ecoflora", "kew_sid"))
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
  expect_equal(sm$seed_mass_bien, 44.47, tolerance = 1e-3)
  expect_equal(sm$seed_mass_brot, 52.63, tolerance = 1e-3)

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
  # Abies alba seed mass in the example database: Diaz 62.007, GIFT 73.9425,
  # BIEN 44.47, BROT 52.63 mg -> median (52.63 + 62.007) / 2 = 57.3185.
  d <- add_trait(mk("Abies alba"), "seed_mass", mode = "coalesce", verbose = FALSE)
  expect_true(all(c("seed_mass", "seed_mass_sources", "seed_mass_n") %in% names(d)))
  expect_equal(d$seed_mass_n, 4L)
  expect_equal(d$seed_mass, 57.3185, tolerance = 1e-6)
  expect_match(d$seed_mass_sources, "diaz")
  expect_match(d$seed_mass_sources, "gift")
})

test_that("numeric coalesce reports the spread as <trait>_min / <trait>_max", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  # No example seed-mass source stores a within-source range, so min/max are the
  # extremes across the four contributing sources: BIEN 44.47 mg up to GIFT
  # 73.9425 mg, bracketing the 57.3185 mg median headline.
  d <- add_trait(mk("Abies alba"), "seed_mass", verbose = FALSE)
  expect_true(all(c("seed_mass_min", "seed_mass_max") %in% names(d)))
  expect_equal(d$seed_mass_min, 44.47, tolerance = 1e-6)
  expect_equal(d$seed_mass_max, 73.9425, tolerance = 1e-6)
  expect_equal(d$seed_mass, 57.3185, tolerance = 1e-6)
})

test_that("categorical coalesce adds no min/max columns", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  r <- add_trait(mk("Abies alba"), "woodiness", verbose = FALSE)
  expect_false(any(c("woodiness_min", "woodiness_max") %in% names(r)))
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

test_that(".trait_join_spread surfaces a source's stored within-source min/max", {
  df <- data.frame(canonical_name = "Aaa bbb",
                   myval = 50, myval_min = 10, myval_max = 100,
                   stringsAsFactors = FALSE)
  install_mock_enrichment("mockspread", df)
  x   <- data.frame(accepted_name = "Aaa bbb", stringsAsFactors = FALSE)
  res <- .trait_join_spread(x, "mockspread", "myval")
  expect_equal(res$value, 50)
  expect_equal(res$min, 10)
  expect_equal(res$max, 100)
})

test_that(".trait_join_spread falls back to the value when no spread is stored", {
  df <- data.frame(canonical_name = "Aaa bbb", myval = 50, stringsAsFactors = FALSE)
  install_mock_enrichment("mocknospread", df)
  x   <- data.frame(accepted_name = "Aaa bbb", stringsAsFactors = FALSE)
  res <- .trait_join_spread(x, "mocknospread", "myval")
  expect_equal(res$value, 50)
  expect_equal(res$min, 50)          # min/max collapse to the point value
  expect_equal(res$max, 50)
})

test_that(".trait_join_spread applies the unit map to the value and both bounds", {
  df <- data.frame(canonical_name = "Aaa bbb",
                   myval = 5, myval_min = 1, myval_max = 10,
                   stringsAsFactors = FALSE)
  install_mock_enrichment("mockmap", df)
  x   <- data.frame(accepted_name = "Aaa bbb", stringsAsFactors = FALSE)
  res <- .trait_join_spread(x, "mockmap", "myval", map = function(v) v * 1000)
  expect_equal(res$value, 5000)
  expect_equal(res$min, 1000)
  expect_equal(res$max, 10000)
})

test_that(".coalesce_spread unions per-source lows and highs, ignoring NA", {
  per_min <- list(a = c(10, NA, NA), b = c(5, 20, NA))
  per_max <- list(a = c(30, NA, NA), b = c(8, 25, NA))
  s <- .coalesce_spread(per_min, per_max)
  expect_equal(s$min, c(5, 20, NA))
  expect_equal(s$max, c(30, 25, NA))
})

test_that("add_zanne() is the source-named woodiness door", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  r <- add_zanne(mk("Quercus robur"), verbose = FALSE)
  expect_true("woodiness" %in% names(r))
  expect_equal(r$woodiness, "woody")
})


# A source that cannot be joined leaves an all-NA column, which reads exactly
# like the source genuinely holding nothing for these taxa. Reporting it is
# therefore not a verbosity setting (#55).

test_that("a source that cannot be joined is named, despite verbose = FALSE", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "trait enrichments not available")

  w <- NULL
  r <- withCallingHandlers(
    testthat::with_mocked_bindings(
      add_trait(mk("Abies alba"), "woodiness", mode = "wide", verbose = FALSE),
      enrich_simple = function(...) stop("staged join failure"),
      .package = "taxify"
    ),
    warning = function(cond) {
      w <<- c(w, conditionMessage(cond)); invokeRestart("muffleWarning")
    }
  )
  expect_true(any(grepl("could not be joined", w, fixed = TRUE)))
  expect_true(any(grepl("'zanne'", w, fixed = TRUE)))
  expect_true(is.na(r$woodiness_zanne))
})

test_that("verbose reports what each source supplied", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "trait enrichments not available")

  expect_message(add_trait(mk("Abies alba"), "woodiness"),
                 "add_trait\\('woodiness'\\).*zanne 1.*of 1 resolved name")
})
