# Cross-source trait registry.
#
# Maps a canonical trait name to the enrichment sources that carry it, each with
# a crosswalk that harmonizes the source's raw column to one shared vocabulary
# (categorical traits) or unit (numeric traits). add_trait() reads this registry
# to attach a trait from every source at once; list_traits() and trait_info()
# describe it. Adding a trait, or a source to a trait, is an edit to this list --
# no new exported function.
#
# Numeric unit conversions and categorical vocabularies were grounded against
# the actual distinct values / value ranges in each source's .vtr, not guessed:
#   - GIFT seed mass is grams (x1000 -> mg; matches Diaz mg median); GIFT SLA is
#     cm^2/g (x0.1 -> mm^2/mg; matches LEDA mm^2/mg median).
#   - Heights are metres in every source; wood density g/cm^3 everywhere; leaf
#     N and P are mg/g; leaf area mm^2.
#   - Body mass is grams in every animal source except AnimalTraits and
#     HomeRange, which are kg (x1000 -> g).
#   - Longevity is years in AnAge/ReptTraits/Amniote/Chelonians; PanTHERIA is
#     months (/12); COMBINE is days (/365.25).
# Excluded after inspection: LEDA leda_seed_mass_mg (values 1-4, a class code,
# not mg); AmphiBIO longevity_d (values are years, not days); SeaLifeBase
# trophic_level (empty). Pelagic trophic_level carries -9999 sentinels, mapped
# to NA. EIVE (0-10 continuous) is not yet a source for the ellenberg_* traits:
# it needs a grounded rescale to the classic 1-9 scale before it can be joined.
#   - GIFT leaf thickness is cm (median x10 = 0.22 mm matches BIEN's 0.21 mm);
#     Amniote SVL is cm (its x10 max 30490 mm matches COMBINE body length).
#   - Amniote female_maturity_d and gestation_d carry negative sentinels, dropped
#     to NA before conversion. Amphibian clutch sizes reach the thousands and
#     AnAge's egg-layers the millions -- genuine, not a unit error.
# Not added (unit could not be calibrated): GIFT leaf length/width (length x10
# plausible but width did not match AusTraits); dropped rather than guessed.
# Not added (only one non-empty source): chromosome number and ploidy (FloraWeb
# column empty), leaf dry mass (LEDA column empty). Activity time deferred:
# COMBINE codes it 1/2/3 with no in-data key to verify the mapping.


# Map raw categorical values to a canonical vocabulary through a named lookup
# (names = source values, values = canonical). Case- and whitespace-insensitive;
# values with no lookup entry become NA.
.xw_cat <- function(v, lookup) {
  key <- tolower(trimws(as.character(v)))
  names(lookup) <- tolower(trimws(names(lookup)))
  out <- unname(lookup[key])
  out[is.na(match(key, names(lookup)))] <- NA_character_
  out
}


# Map raw values to a canonical vocabulary by ordered regex: the first pattern
# (case-insensitive) that matches a value wins. Used for multi-token or coded
# categorical columns (growth form, life form, dispersal syndrome) where one
# record may list several forms and the primary one is taken. `patterns` is a
# named character vector: names = regex, values = canonical term.
.xw_grep <- function(v, patterns) {
  s   <- tolower(trimws(as.character(v)))
  out <- rep(NA_character_, length(s))
  for (i in seq_along(patterns)) {
    hit <- is.na(out) & !is.na(s) & nzchar(s) & grepl(names(patterns)[i], s)
    out[hit] <- unname(patterns[i])
  }
  out
}


# The registry. Sources are listed in default coalesce-priority order.
.trait_registry <- function() {

  # Shared categorical crosswalks (built once, reused across sources).
  xw_photo <- c(
    "c3"      = "c3",    "c4"    = "c4",  "cam"    = "cam",
    "c3-c4"   = "c3-c4", "c3 c4" = "c3-c4", "c3; c4" = "c3-c4",
    "c3-cam"  = "c3-cam","c3 cam"= "c3-cam","c3; cam"= "c3-cam")

  gf_patterns <- c(
    "tree|mallee|palmoid"             = "tree",
    "subshrub"                        = "subshrub",
    "shrub"                           = "shrub",
    "climber|liana|vine"              = "climber",
    "fern|lycophyte"                  = "fern",
    "graminoid|grass|tussock|hummock" = "graminoid",
    "geophyte"                        = "geophyte",
    "epiphyte"                        = "epiphyte",
    "succulent"                       = "succulent",
    "herb|forb"                       = "herb",
    "parasite|other"                  = "other")

  lf_patterns <- c(
    "phanerophyt"                = "phanerophyte",
    "chamaephyt"                 = "chamaephyte",
    "hemikryptophyt|hemicrypto"  = "hemicryptophyte",
    "geophyt"                    = "geophyte",
    "hydrophyt"                  = "hydrophyte",
    "helophyt"                   = "helophyte",
    "therophyt"                  = "therophyte",
    "cryptophyt"                 = "cryptophyte")

  disp_patterns <- c(
    "myrmecochor"                          = "ant",
    "anemochor|meteorochor|boleochor|chamaechor" = "wind",
    "zoochor|dysochor"                     = "animal",
    "hydrochor|nautochor|ombrochor"        = "water",
    "barochor|blastochor|bythisochor"      = "gravity",
    "ballochor|ballistic|autochor|herpochor" = "ballistic",
    "agochor|hemerochor|ethelochor|speirochor" = "human",
    "unspecialized|undefined"              = "unspecialized")

  poll_patterns <- c(
    "insekt|insect"                          = "insect",
    "wind"                                   = "wind",
    "wasser|water"                           = "water",
    "selbst|selfed|self|kleistogam|geitonogam" = "self",
    "apogam"                                 = "apogamy")

  num  <- function(v) suppressWarnings(as.numeric(v))
  numk <- function(v) suppressWarnings(as.numeric(v)) * 1000        # kg -> g
  num_pos <- function(v) { x <- suppressWarnings(as.numeric(v)); x[x < 0] <- NA; x }
  cm2mm   <- function(v) suppressWarnings(as.numeric(v)) * 10       # cm -> mm
  cm2mm_p <- function(v) num_pos(v) * 10                            # cm -> mm, negatives dropped
  d2y     <- function(v) num_pos(v) / 365.25                        # days -> years, negatives dropped

  # Categorical crosswalks for the added traits (grounded on the sources'
  # distinct values). Flower colour takes the first colour word of a possibly
  # compound value; life history collapses multi-class records to "variable".
  col_lookup <- c(
    white = "white", cream = "cream", creamy = "cream", ivory = "cream",
    yellow = "yellow", gold = "yellow", golden = "yellow",
    orange = "orange", red = "red", scarlet = "red", crimson = "red",
    pink = "pink", rose = "pink", magenta = "pink",
    purple = "purple", violet = "purple", lilac = "purple",
    mauve = "purple", muave = "purple", blue = "blue",
    green = "green", greenish = "green", brown = "brown",
    browish = "brown", bronze = "brown", black = "black",
    grey = "grey", gray = "grey")
  fc_map <- function(v) {
    s  <- tolower(trimws(as.character(v)))
    ft <- sub("^[^a-z]*([a-z]+).*$", "\\1", s)
    ft[!grepl("[a-z]", s)] <- NA_character_
    .xw_cat(ft, col_lookup)
  }
  fr_lookup <- c(
    achene = "achene", capsule = "capsule", pyxid = "capsule",
    pyxidium = "capsule", caryopsis = "caryopsis", legume = "legume",
    pod = "legume", lomentum = "legume", silique = "silique",
    siliqua = "silique", drupe = "drupe", berry = "berry",
    follicle = "follicle", cone = "cone", samara = "samara",
    nut = "nut", schizocarp = "schizocarp", utricle = "utricle",
    pome = "pome")
  diet_lookup <- c(
    invertivore = "invertivore", omnivore = "omnivore",
    omnivorous = "omnivore", frugivore = "frugivore",
    `aquatic predator` = "carnivore", vertivore = "carnivore",
    carnivorous = "carnivore", granivore = "granivore",
    nectarivore = "nectarivore", `herbivore terrestrial` = "herbivore",
    `herbivore aquatic` = "herbivore", herbivorous = "herbivore",
    scavenger = "scavenger")
  lh_map <- function(v) {
    s   <- tolower(trimws(as.character(v)))
    s2  <- gsub("short_lived_perennial", "perennial", s, fixed = TRUE)
    s2  <- gsub("ephemeral", "annual", s2, fixed = TRUE)
    ha  <- grepl("annual", s2); hb <- grepl("biennial", s2); hp <- grepl("perennial", s2)
    ncl <- ha + hb + hp
    out <- rep(NA_character_, length(s))
    out[ncl == 1 & ha] <- "annual"
    out[ncl == 1 & hb] <- "biennial"
    out[ncl == 1 & hp] <- "perennial"
    out[ncl > 1 | grepl("variable", s)] <- "variable"
    out
  }

  # A numeric source that is used verbatim (already in the canonical unit).
  nsrc <- function(enr, col, cite, note, map = num) {
    list(enrichment = enr, col = col, citation = cite, note = note, map = map)
  }

  list(

    ## ---- plant functional traits (numeric) --------------------------------
    plant_height = list(
      label = "Plant height", kind = "numeric", unit = "m", vocab = NULL,
      sources = list(
        gift      = nsrc("gift", "gift_plant_height_max", "GIFT (Weigelt et al. 2020)", "Maximum height, metres."),
        diaz      = nsrc("diaz_traits", "plant_height_m", "Diaz et al. 2022", "Species-mean height, metres."),
        austraits = nsrc("austraits", "plant_height_m", "AusTraits (Falster et al. 2021)", "Metres."),
        bien      = nsrc("bien", "plant_height_m", "BIEN (Maitner et al. 2018)", "Metres."),
        brot      = nsrc("brot", "height_m", "BROT 2.0 (Tavsanoglu & Pausas 2018)", "Metres.")
      )
    ),
    seed_mass = list(
      label = "Seed mass", kind = "numeric", unit = "mg", vocab = NULL,
      sources = list(
        diaz      = nsrc("diaz_traits", "seed_mass_mg", "Diaz et al. 2022", "Milligrams."),
        gift      = nsrc("gift", "gift_seed_mass_mean", "GIFT (Weigelt et al. 2020)", "GIFT grams converted to milligrams (x1000).", map = numk),
        austraits = nsrc("austraits", "seed_dry_mass_mg", "AusTraits (Falster et al. 2021)", "Milligrams."),
        bien      = nsrc("bien", "seed_mass_mg", "BIEN (Maitner et al. 2018)", "Milligrams."),
        brot      = nsrc("brot", "seed_mass_mg", "BROT 2.0 (Tavsanoglu & Pausas 2018)", "Milligrams."),
        ecoflora  = nsrc("ecoflora", "seed_weight_mg_uk", "Ecoflora (Fitter & Peat 1994)", "Milligrams.")
      )
    ),
    sla = list(
      label = "Specific leaf area", kind = "numeric", unit = "mm2/mg", vocab = NULL,
      sources = list(
        leda = nsrc("leda", "sla_mm2_mg", "LEDA Traitbase (Kleyer et al. 2008)", "mm^2/mg."),
        gift = nsrc("gift", "gift_sla_mean", "GIFT (Weigelt et al. 2020)", "GIFT cm^2/g converted to mm^2/mg (x0.1).", map = function(v) suppressWarnings(as.numeric(v)) * 0.1),
        bien = nsrc("bien", "sla_mm2_mg", "BIEN (Maitner et al. 2018)", "mm^2/mg."),
        brot = nsrc("brot", "sla_mm2_mg", "BROT 2.0 (Tavsanoglu & Pausas 2018)", "mm^2/mg.")
      )
    ),
    wood_density = list(
      label = "Wood density", kind = "numeric", unit = "g/cm3", vocab = NULL,
      sources = list(
        gwdd      = nsrc("gwdd", "wood_density_g_cm3", "Global Wood Density Database (Chave et al. 2009)", "g/cm^3."),
        austraits = nsrc("austraits", "wood_density_g_cm3", "AusTraits (Falster et al. 2021)", "g/cm^3."),
        bien      = nsrc("bien", "wood_density_g_cm3", "BIEN (Maitner et al. 2018)", "g/cm^3.")
      )
    ),
    leaf_area = list(
      label = "Leaf area", kind = "numeric", unit = "mm2", vocab = NULL,
      sources = list(
        austraits = nsrc("austraits", "leaf_area_mm2", "AusTraits (Falster et al. 2021)", "mm^2."),
        bien      = nsrc("bien", "leaf_area_mm2", "BIEN (Maitner et al. 2018)", "mm^2."),
        brot      = nsrc("brot", "leaf_area_mm2", "BROT 2.0 (Tavsanoglu & Pausas 2018)", "mm^2.")
      )
    ),
    leaf_n = list(
      label = "Leaf nitrogen per dry mass", kind = "numeric", unit = "mg/g", vocab = NULL,
      sources = list(
        austraits = nsrc("austraits", "leaf_n_per_dry_mass", "AusTraits (Falster et al. 2021)", "mg/g."),
        bien      = nsrc("bien", "leaf_n_per_dry_mass", "BIEN (Maitner et al. 2018)", "mg/g.")
      )
    ),
    leaf_p = list(
      label = "Leaf phosphorus per dry mass", kind = "numeric", unit = "mg/g", vocab = NULL,
      sources = list(
        austraits = nsrc("austraits", "leaf_p_per_dry_mass", "AusTraits (Falster et al. 2021)", "mg/g."),
        bien      = nsrc("bien", "leaf_p_per_dry_mass", "BIEN (Maitner et al. 2018)", "mg/g.")
      )
    ),
    leaf_thickness = list(
      label = "Leaf thickness", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        bien = nsrc("bien", "leaf_thickness_mm", "BIEN (Maitner et al. 2018)", "mm."),
        gift = nsrc("gift", "gift_leaf_thickness_mean", "GIFT (Weigelt et al. 2020)", "GIFT cm converted to mm (x10; calibrated against BIEN leaf thickness median).", map = cm2mm)
      )
    ),

    ## ---- animal body size / life history (numeric) ------------------------
    body_mass = list(
      label = "Body mass", kind = "numeric", unit = "g", vocab = NULL,
      sources = list(
        combine      = nsrc("combine", "adult_mass_g", "COMBINE (Soria et al. 2021)", "Adult mass, grams."),
        amniote      = nsrc("amniote", "adult_body_mass_g", "Amniote LHD (Myhrvold et al. 2015)", "Adult mass, grams."),
        pantheria    = nsrc("pantheria", "body_mass_g", "PanTHERIA (Jones et al. 2009)", "Grams."),
        elton_traits = nsrc("elton_traits", "body_mass_g", "EltonTraits (Wilman et al. 2014)", "Grams."),
        avonet       = nsrc("avonet", "body_mass_g", "AVONET (Tobias et al. 2022)", "Grams."),
        anage        = nsrc("anage", "body_mass_g", "AnAge (Tacutu et al. 2018)", "Grams."),
        phylacine    = nsrc("phylacine", "mass_g", "PHYLACINE (Faurby et al. 2018)", "Grams."),
        repttraits   = nsrc("repttraits", "body_mass_g", "ReptTraits (Oskyrko et al. 2024)", "Grams."),
        fishbase     = nsrc("fishbase", "body_mass_g", "FishBase (Froese & Pauly)", "Grams."),
        sealifebase  = nsrc("sealifebase", "body_mass_g", "SeaLifeBase (Palomares & Pauly)", "Grams."),
        frugivoria   = nsrc("frugivoria", "body_mass_g", "Frugivoria (Gerstner et al.)", "Grams."),
        pottier      = nsrc("pottier", "body_mass_g", "Pottier et al.", "Grams."),
        animaltraits = nsrc("animaltraits", "body_mass_kg", "AnimalTraits (Herberstein et al. 2022)", "kg converted to grams (x1000).", map = numk),
        homerange    = nsrc("homerange", "body_mass_kg", "Broekman et al. HomeRange", "kg converted to grams (x1000).", map = numk)
      )
    ),
    longevity = list(
      label = "Maximum longevity", kind = "numeric", unit = "yr", vocab = NULL,
      sources = list(
        anage      = nsrc("anage", "max_longevity_yr", "AnAge (Tacutu et al. 2018)", "Years."),
        amniote    = nsrc("amniote", "maximum_longevity_y", "Amniote LHD (Myhrvold et al. 2015)", "Years."),
        combine    = nsrc("combine", "max_longevity_d", "COMBINE (Soria et al. 2021)", "Days converted to years (/365.25).", map = function(v) suppressWarnings(as.numeric(v)) / 365.25),
        pantheria  = nsrc("pantheria", "longevity_mo", "PanTHERIA (Jones et al. 2009)", "Months converted to years (/12).", map = function(v) suppressWarnings(as.numeric(v)) / 12),
        repttraits = nsrc("repttraits", "longevity_yr", "ReptTraits (Oskyrko et al. 2024)", "Years."),
        chelonians = nsrc("chelonians", "max_lifespan_y", "TurtleTraits (Chelonians)", "Years."),
        amphibio   = nsrc("amphibio", "longevity_yr", "AmphiBIO (Oliveira et al. 2017)", "Maximum longevity, years.")
      )
    ),
    trophic_level = list(
      label = "Trophic level", kind = "numeric", unit = "trophic level (~1-5)", vocab = NULL,
      sources = list(
        fishbase      = nsrc("fishbase", "trophic_level", "FishBase (Froese & Pauly)", "FishBase trophic level."),
        beukhof       = nsrc("beukhof", "trophic_level", "Beukhof et al. 2019", "Trophic level."),
        quimbayo      = nsrc("quimbayo", "trophic_level", "Quimbayo et al.", "Trophic level."),
        pelagic       = nsrc("pelagic", "trophic_level", "Pelagic fish traits", "Trophic level; -9999 sentinels mapped to NA.", map = num_pos),
        arctic_traits = nsrc("arctic_traits", "trophic_level", "Arctic Traits", "Trophic level."),
        sealifebase   = nsrc("sealifebase", "trophic_level", "SeaLifeBase (Palomares & Pauly)", "Trophic level (DietTroph, else FoodTroph).")
      )
    ),

    clutch_litter_size = list(
      label = "Clutch or litter size", kind = "numeric", unit = "offspring per clutch/litter", vocab = NULL,
      sources = list(
        amniote    = nsrc("amniote", "litter_clutch_size", "Amniote LHD (Myhrvold et al. 2015)", "Eggs/offspring per clutch or litter.", map = num_pos),
        combine    = nsrc("combine", "litter_size_n", "COMBINE (Soria et al. 2021)", "Offspring per litter."),
        pantheria  = nsrc("pantheria", "litter_size", "PanTHERIA (Jones et al. 2009)", "Offspring per litter."),
        anage      = nsrc("anage", "litter_size", "AnAge (Tacutu et al. 2018)", "Offspring per clutch/litter; egg-layers reach the hundreds to millions."),
        repttraits = nsrc("repttraits", "clutch_size", "ReptTraits (Oskyrko et al. 2024)", "Eggs per clutch."),
        amphibio   = nsrc("amphibio", "litter_size", "AmphiBIO (Oliveira et al. 2017)", "Eggs per clutch (amphibian clutches reach the thousands).")
      )
    ),
    age_at_maturity = list(
      label = "Age at female maturity", kind = "numeric", unit = "yr", vocab = NULL,
      sources = list(
        anage    = nsrc("anage", "female_maturity_d", "AnAge (Tacutu et al. 2018)", "Days converted to years (/365.25).", map = d2y),
        amniote  = nsrc("amniote", "female_maturity_d", "Amniote LHD (Myhrvold et al. 2015)", "Days converted to years (/365.25); negative sentinels dropped.", map = d2y),
        amphibio = nsrc("amphibio", "age_maturity_y", "AmphiBIO (Oliveira et al. 2017)", "Years.")
      )
    ),
    gestation_incubation = list(
      label = "Gestation or incubation length", kind = "numeric", unit = "days", vocab = NULL,
      sources = list(
        anage     = nsrc("anage", "gestation_incubation_d", "AnAge (Tacutu et al. 2018)", "Gestation or incubation, days."),
        combine   = nsrc("combine", "gestation_length_d", "COMBINE (Soria et al. 2021)", "Gestation, days."),
        pantheria = nsrc("pantheria", "gestation_d", "PanTHERIA (Jones et al. 2009)", "Gestation, days."),
        amniote   = nsrc("amniote", "gestation_d", "Amniote LHD (Myhrvold et al. 2015)", "Gestation, days; negative sentinels dropped.", map = num_pos)
      )
    ),
    body_length = list(
      label = "Body length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        combine     = nsrc("combine", "adult_body_length_mm", "COMBINE (Soria et al. 2021)", "Adult body length, mm."),
        amniote     = nsrc("amniote", "adult_svl_cm", "Amniote LHD (Myhrvold et al. 2015)", "Snout-vent length, cm converted to mm (x10; calibrated against COMBINE body length).", map = cm2mm_p),
        repttraits  = nsrc("repttraits", "svl_mm", "ReptTraits (Oskyrko et al. 2024)", "Snout-vent length, mm."),
        amphibio    = nsrc("amphibio", "body_size_mm", "AmphiBIO (Oliveira et al. 2017)", "Snout-vent length, mm."),
        fishbase    = nsrc("fishbase", "body_length_cm", "FishBase (Froese & Pauly)", "Standard/total length, cm converted to mm (x10).", map = cm2mm),
        sealifebase = nsrc("sealifebase", "body_length_cm", "SeaLifeBase (Palomares & Pauly)", "Body length, cm converted to mm (x10).", map = cm2mm)
      )
    ),
    metabolic_rate = list(
      label = "Metabolic rate", kind = "numeric", unit = "W", vocab = NULL,
      sources = list(
        anage        = nsrc("anage", "metabolic_rate_w", "AnAge (Tacutu et al. 2018)", "Watts."),
        animaltraits = nsrc("animaltraits", "metabolic_rate_w", "AnimalTraits (Herberstein et al. 2022)", "Watts.")
      )
    ),
    reproductive_frequency = list(
      label = "Litters or clutches per year", kind = "numeric", unit = "per year", vocab = NULL,
      sources = list(
        amniote = nsrc("amniote", "clutches_per_y", "Amniote LHD (Myhrvold et al. 2015)", "Clutches or litters per year.", map = num_pos),
        combine = nsrc("combine", "litters_per_year_n", "COMBINE (Soria et al. 2021)", "Litters per year.")
      )
    ),

    ## ---- plant phenology (numeric, month of year) -------------------------
    flowering_start = list(
      label = "Flowering start (month)", kind = "numeric", unit = "month (1-12)", vocab = NULL,
      sources = list(
        baseflor = nsrc("baseflor", "flower_begin_month", "Baseflor (Julve, Catminat)", "Month 1-12."),
        ecoflora = nsrc("ecoflora", "flower_begin_month_uk", "Ecoflora (Fitter & Peat 1994)", "Month 1-12.")
      )
    ),
    flowering_end = list(
      label = "Flowering end (month)", kind = "numeric", unit = "month (1-12)", vocab = NULL,
      sources = list(
        baseflor = nsrc("baseflor", "flower_end_month", "Baseflor (Julve, Catminat)", "Month 1-12."),
        ecoflora = nsrc("ecoflora", "flower_end_month_uk", "Ecoflora (Fitter & Peat 1994)", "Month 1-12.")
      )
    ),

    ## ---- Ellenberg-type indicator values (numeric, classic 1-9 scale) -----
    ## EIVE (0-10) is deliberately excluded until its rescale to this scale is
    ## grounded; ecoflora / floraweb / bet are all native classic 1-9.
    ellenberg_light = list(
      label = "Ellenberg light (L)", kind = "numeric", unit = "1-9 (classic)", vocab = NULL,
      sources = list(
        floraweb = nsrc("floraweb", "ell_light_de", "FloraWeb / BiolFlor (Klotz, Kuehn & Durka 2002)", "Classic Ellenberg L, 1-9."),
        ecoflora = nsrc("ecoflora", "ell_light_uk", "Ecoflora (Fitter & Peat 1994)", "British Ellenberg L, 1-9."),
        bet      = nsrc("bet", "ind_light", "BET bryophyte traits", "Bryophyte light indicator, 1-9.")
      )
    ),
    ellenberg_temperature = list(
      label = "Ellenberg temperature (T)", kind = "numeric", unit = "1-9 (classic)", vocab = NULL,
      sources = list(
        floraweb = nsrc("floraweb", "ell_temperature_de", "FloraWeb / BiolFlor (Klotz, Kuehn & Durka 2002)", "Classic Ellenberg T, 1-9."),
        bet      = nsrc("bet", "ind_temperature", "BET bryophyte traits", "Bryophyte temperature indicator, 1-9.")
      )
    ),
    ellenberg_moisture = list(
      label = "Ellenberg moisture (F)", kind = "numeric", unit = "1-12 (classic)", vocab = NULL,
      sources = list(
        floraweb = nsrc("floraweb", "ell_moisture_de", "FloraWeb / BiolFlor (Klotz, Kuehn & Durka 2002)", "Classic Ellenberg F, 1-12."),
        ecoflora = nsrc("ecoflora", "ell_moisture_uk", "Ecoflora (Fitter & Peat 1994)", "British Ellenberg F, 1-12."),
        bet      = nsrc("bet", "ind_moisture", "BET bryophyte traits", "Bryophyte moisture indicator, 1-9.")
      )
    ),
    ellenberg_reaction = list(
      label = "Ellenberg reaction (R)", kind = "numeric", unit = "1-9 (classic)", vocab = NULL,
      sources = list(
        floraweb = nsrc("floraweb", "ell_reaction_de", "FloraWeb / BiolFlor (Klotz, Kuehn & Durka 2002)", "Classic Ellenberg R, 1-9."),
        ecoflora = nsrc("ecoflora", "ell_reaction_uk", "Ecoflora (Fitter & Peat 1994)", "British Ellenberg R, 1-9."),
        bet      = nsrc("bet", "ind_reaction_ph", "BET bryophyte traits", "Bryophyte reaction indicator, 1-9.")
      )
    ),
    ellenberg_nitrogen = list(
      label = "Ellenberg nutrients / nitrogen (N)", kind = "numeric", unit = "1-9 (classic)", vocab = NULL,
      sources = list(
        floraweb = nsrc("floraweb", "ell_nitrogen_de", "FloraWeb / BiolFlor (Klotz, Kuehn & Durka 2002)", "Classic Ellenberg N, 1-9."),
        ecoflora = nsrc("ecoflora", "ell_nitrogen_uk", "Ecoflora (Fitter & Peat 1994)", "British Ellenberg N, 1-9."),
        bet      = nsrc("bet", "ind_nitrogen", "BET bryophyte traits", "Bryophyte nitrogen indicator, 1-9.")
      )
    ),
    ellenberg_salt = list(
      label = "Ellenberg salt (S)", kind = "numeric", unit = "0-9 (classic)", vocab = NULL,
      sources = list(
        floraweb = nsrc("floraweb", "ell_salt_de", "FloraWeb / BiolFlor (Klotz, Kuehn & Durka 2002)", "Classic Ellenberg salt tolerance."),
        ecoflora = nsrc("ecoflora", "ell_salt_uk", "Ecoflora (Fitter & Peat 1994)", "British Ellenberg salt tolerance.")
      )
    ),

    ## ---- categorical traits -----------------------------------------------
    woodiness = list(
      label = "Woodiness", kind = "categorical", unit = NA_character_,
      vocab = c("woody", "non-woody", "variable"),
      sources = list(
        zanne = list(
          enrichment = "woodiness", col = "woodiness",
          citation = "Zanne et al. 2014",
          note = "Zanne 'herbaceous' maps to canonical 'non-woody'.",
          map = function(v) .xw_cat(v, c(woody = "woody", herbaceous = "non-woody", variable = "variable"))),
        gift = list(
          enrichment = "gift", col = "gift_woodiness_1",
          citation = "GIFT (Weigelt et al. 2020)",
          note = "GIFT woodiness used verbatim.",
          map = function(v) .xw_cat(v, c(woody = "woody", `non-woody` = "non-woody", variable = "variable"))),
        austraits = list(
          enrichment = "austraits", col = "woodiness",
          citation = "AusTraits (Falster et al. 2021)",
          note = "Pure 'woody'/'herbaceous' mapped; mixed or semi-woody entries -> 'variable'.",
          map = function(v) {
            s <- tolower(trimws(as.character(v)))
            hash <- grepl("herbaceous", s); hasw <- grepl("woody", s)
            hass <- grepl("semi_woody", s)
            out <- rep(NA_character_, length(s))
            out[hash & !hasw]           <- "non-woody"
            out[hasw & !hash & !hass]   <- "woody"
            out[(hash & hasw) | hass]   <- "variable"
            out
          }),
        bien = list(
          enrichment = "bien", col = "woodiness",
          citation = "BIEN (Maitner et al. 2018)",
          note = "BIEN 'herbaceous' maps to 'non-woody'.",
          map = function(v) .xw_cat(v, c(woody = "woody", herbaceous = "non-woody", variable = "variable")))
      )
    ),
    photosynthetic_pathway = list(
      label = "Photosynthetic pathway", kind = "categorical", unit = NA_character_,
      vocab = c("c3", "c4", "cam", "c3-c4", "c3-cam"),
      sources = list(
        gift      = list(enrichment = "gift", col = "gift_photosynthetic_pathway",
                         citation = "GIFT (Weigelt et al. 2020)", note = "C3 / C4 / CAM.",
                         map = function(v) .xw_cat(v, xw_photo)),
        austraits = list(enrichment = "austraits", col = "photosynthetic_pathway",
                         citation = "AusTraits (Falster et al. 2021)", note = "C3 / C4 / CAM and intermediates; 'unknown' -> NA.",
                         map = function(v) .xw_cat(v, xw_photo)),
        ecoflora  = list(enrichment = "ecoflora", col = "photosynthetic_pathway_uk",
                         citation = "Ecoflora (Fitter & Peat 1994)", note = "C3 / C4 / CAM.",
                         map = function(v) .xw_cat(v, xw_photo))
      )
    ),
    growth_form = list(
      label = "Growth form", kind = "categorical", unit = NA_character_,
      vocab = c("tree", "shrub", "subshrub", "herb", "graminoid", "climber",
                "fern", "geophyte", "epiphyte", "succulent", "other"),
      sources = list(
        gift      = list(enrichment = "gift", col = "gift_growth_form_1",
                         citation = "GIFT (Weigelt et al. 2020)", note = "Primary growth form.",
                         map = function(v) .xw_grep(v, gf_patterns)),
        austraits = list(enrichment = "austraits", col = "plant_growth_form",
                         citation = "AusTraits (Falster et al. 2021)", note = "Primary growth form from a possibly multi-form record.",
                         map = function(v) .xw_grep(v, gf_patterns)),
        bien      = list(enrichment = "bien", col = "growth_form",
                         citation = "BIEN (Maitner et al. 2018)", note = "Primary growth form.",
                         map = function(v) .xw_grep(v, gf_patterns)),
        brot      = list(enrichment = "brot", col = "growth_form",
                         citation = "BROT 2.0 (Tavsanoglu & Pausas 2018)", note = "Primary growth form.",
                         map = function(v) .xw_grep(v, gf_patterns))
      )
    ),
    life_form = list(
      label = "Raunkiaer life form", kind = "categorical", unit = NA_character_,
      vocab = c("phanerophyte", "chamaephyte", "hemicryptophyte", "cryptophyte",
                "geophyte", "hydrophyte", "helophyte", "therophyte"),
      sources = list(
        gift     = list(enrichment = "gift", col = "gift_life_form_1",
                        citation = "GIFT (Weigelt et al. 2020)", note = "Raunkiaer life form.",
                        map = function(v) .xw_grep(v, lf_patterns)),
        ecoflora = list(enrichment = "ecoflora", col = "life_form_uk",
                        citation = "Ecoflora (Fitter & Peat 1994)", note = "Primary Raunkiaer life form; two-letter abbreviations -> NA.",
                        map = function(v) .xw_grep(v, lf_patterns)),
        floraweb = list(enrichment = "floraweb", col = "life_form_de",
                        citation = "FloraWeb / BiolFlor (Klotz, Kuehn & Durka 2002)", note = "German BiolFlor life-form term mapped to Raunkiaer class.",
                        map = function(v) .xw_grep(v, lf_patterns))
      )
    ),
    dispersal_syndrome = list(
      label = "Dispersal syndrome", kind = "categorical", unit = NA_character_,
      vocab = c("wind", "animal", "ant", "water", "gravity", "ballistic", "human", "unspecialized"),
      sources = list(
        gift      = list(enrichment = "gift", col = "gift_dispersal_syndrome_1",
                         citation = "GIFT (Weigelt et al. 2020)", note = "Primary dispersal syndrome.",
                         map = function(v) .xw_grep(v, disp_patterns)),
        austraits = list(enrichment = "austraits", col = "dispersal_syndrome",
                         citation = "AusTraits (Falster et al. 2021)", note = "Primary syndrome from a possibly multi-mode record (-chory terms).",
                         map = function(v) .xw_grep(v, disp_patterns)),
        leda      = list(enrichment = "leda", col = "dispersal_type",
                         citation = "LEDA Traitbase (Kleyer et al. 2008)", note = "LEDA -chor terms mapped to primary vector.",
                         map = function(v) .xw_grep(v, disp_patterns)),
        baseflor  = list(enrichment = "baseflor", col = "dispersal_mode",
                         citation = "Baseflor (Julve, Catminat)", note = "-chory term mapped to primary vector.",
                         map = function(v) .xw_grep(v, disp_patterns)),
        brot      = list(enrichment = "brot", col = "disp_mode",
                         citation = "BROT 2.0 (Tavsanoglu & Pausas 2018)", note = "-chory term mapped to primary vector.",
                         map = function(v) .xw_grep(v, disp_patterns))
      )
    ),
    pollination_vector = list(
      label = "Pollination vector", kind = "categorical", unit = NA_character_,
      vocab = c("insect", "wind", "water", "self", "apogamy"),
      sources = list(
        baseflor = list(enrichment = "baseflor", col = "pollination_vector",
                        citation = "Baseflor (Julve, Catminat)", note = "Primary pollination vector.",
                        map = function(v) .xw_grep(v, poll_patterns)),
        ecoflora = list(enrichment = "ecoflora", col = "pollination_vector_uk",
                        citation = "Ecoflora (Fitter & Peat 1994)", note = "Primary pollination vector; 'none' -> NA.",
                        map = function(v) .xw_grep(v, poll_patterns))
      )
    ),
    life_history = list(
      label = "Life history", kind = "categorical", unit = NA_character_,
      vocab = c("annual", "biennial", "perennial", "variable"),
      sources = list(
        gift      = list(enrichment = "gift", col = "gift_lifecycle_1",
                         citation = "GIFT (Weigelt et al. 2020)", note = "annual / biennial / perennial / variable.",
                         map = lh_map),
        austraits = list(enrichment = "austraits", col = "life_history",
                         citation = "AusTraits (Falster et al. 2021)", note = "Multi-class records (e.g. 'annual perennial') collapse to 'variable'; short-lived perennial -> perennial; ephemeral -> annual.",
                         map = lh_map)
      )
    ),
    flower_colour = list(
      label = "Flower colour", kind = "categorical", unit = NA_character_,
      vocab = c("white", "cream", "yellow", "orange", "red", "pink",
                "purple", "blue", "green", "brown", "black", "grey"),
      sources = list(
        gift     = list(enrichment = "gift", col = "gift_flower_colour",
                        citation = "GIFT (Weigelt et al. 2020)", note = "Primary flower colour.",
                        map = fc_map),
        baseflor = list(enrichment = "baseflor", col = "flower_colour",
                        citation = "Baseflor (Julve, Catminat)", note = "First colour of a possibly compound value.",
                        map = fc_map),
        bien     = list(enrichment = "bien", col = "flower_color",
                        citation = "BIEN (Maitner et al. 2018)", note = "First colour word of a possibly compound value.",
                        map = fc_map)
      )
    ),
    fruit_type = list(
      label = "Fruit type", kind = "categorical", unit = NA_character_,
      vocab = c("achene", "capsule", "caryopsis", "legume", "silique",
                "drupe", "berry", "follicle", "cone", "samara", "nut",
                "schizocarp", "utricle", "pome"),
      sources = list(
        gift     = list(enrichment = "gift", col = "gift_fruit_type_1",
                        citation = "GIFT (Weigelt et al. 2020)", note = "Morphological fruit type; pod -> legume, siliqua -> silique, 'other' -> NA.",
                        map = function(v) .xw_cat(v, fr_lookup)),
        baseflor = list(enrichment = "baseflor", col = "fruit_type",
                        citation = "Baseflor (Julve, Catminat)", note = "Morphological fruit type; pyxid -> capsule.",
                        map = function(v) .xw_cat(v, fr_lookup))
      )
    ),
    diet_guild = list(
      label = "Diet guild", kind = "categorical", unit = NA_character_,
      vocab = c("carnivore", "herbivore", "omnivore", "invertivore",
                "frugivore", "granivore", "nectarivore", "scavenger"),
      sources = list(
        avonet     = list(enrichment = "avonet", col = "trophic_niche",
                          citation = "AVONET (Tobias et al. 2022)", note = "Trophic niche; vertivore and aquatic predator -> carnivore, herbivore terrestrial/aquatic -> herbivore.",
                          map = function(v) .xw_cat(v, diet_lookup)),
        repttraits = list(enrichment = "repttraits", col = "diet",
                          citation = "ReptTraits (Oskyrko et al. 2024)", note = "Carnivorous / herbivorous / omnivorous.",
                          map = function(v) .xw_cat(v, diet_lookup))
      )
    )
  )
}


# Resolve a user-supplied trait name to a registry key, or stop with a
# did-you-mean suggestion.
.resolve_trait_name <- function(trait, known) {
  if (length(trait) != 1L || !is.character(trait) || is.na(trait)) {
    stop("add_trait(): 'trait' must be a single trait name. See list_traits().",
         call. = FALSE)
  }
  if (trait %in% known) return(trait)
  d    <- utils::adist(tolower(trait), tolower(known))[1, ]
  near <- known[order(d)]
  near <- near[sort(d)[seq_along(near)] <= 3L]
  msg  <- sprintf("add_trait(): unknown trait '%s'.", trait)
  if (length(near)) {
    msg <- paste0(msg, " Did you mean: ", paste(near, collapse = ", "), "?")
  }
  stop(paste0(msg, "\n  See list_traits() for available traits."), call. = FALSE)
}


# Resolve the `sources` argument to a vector of registered source names, in
# registry order. NULL or "all" -> every source.
.resolve_trait_sources <- function(sources, all_src, trait) {
  if (is.null(sources) ||
      (length(sources) == 1L && !is.na(sources) && sources == "all")) {
    return(all_src)
  }
  sources <- as.character(sources)
  bad <- setdiff(sources, all_src)
  if (length(bad)) {
    stop(sprintf(
      "add_trait(): unknown source(s) for '%s': %s. Available: %s.",
      trait, paste(bad, collapse = ", "), paste(all_src, collapse = ", ")),
      call. = FALSE)
  }
  intersect(all_src, sources)
}


# Join a single source column onto x by accepted_name and return the raw vector
# (before crosswalk). Reuses enrich_simple() for the aggregate-aware join. A
# source that is unavailable (not installed, no download, no build) is skipped
# with a warning and returns NULL, so add_trait() still works from the rest.
.trait_join_one <- function(x, enrichment, col, kind, verbose = TRUE) {
  tmp  <- ".__taxify_trait_raw__"
  na_t <- stats::setNames(
    list(if (kind == "numeric") NA_real_ else NA_character_), tmp)
  res <- tryCatch(
    enrich_simple(
      x, enrichment_name = enrichment,
      col_map      = stats::setNames(col, tmp),
      source_label = enrichment,
      na_types     = na_t,
      verbose      = FALSE
    ),
    error = function(e) {
      if (verbose) {
        warning(sprintf(
          "add_trait(): source '%s' unavailable (%s); skipping.",
          enrichment, conditionMessage(e)), call. = FALSE)
      }
      NULL
    }
  )
  if (is.null(res)) return(NULL)
  res[[tmp]]
}


# Resolve the coalesce reducer, defaulting by trait kind (numeric -> median,
# categorical -> first) and validating against the reducers each kind allows.
.resolve_combine <- function(combine, kind) {
  ok <- if (kind == "numeric") {
    c("median", "mean", "first", "min", "max")
  } else {
    c("first", "vote")
  }
  if (is.null(combine)) return(if (kind == "numeric") "median" else "first")
  combine <- as.character(combine)[1L]
  if (!combine %in% ok) {
    stop(sprintf(
      "add_trait(): combine = '%s' is not valid for a %s trait. Use one of: %s.",
      combine, kind, paste(ok, collapse = ", ")), call. = FALSE)
  }
  combine
}


# Reduce a list of per-source harmonized vectors (in priority order) to one
# value, source label, and count per row. `first` walks priority order; the
# numeric aggregators reduce the non-NA values; `vote` takes the categorical
# majority with priority-order tie-breaking. When an aggregator is used the
# source label is the comma-separated set of contributing sources.
.coalesce_sources <- function(per_src, ord, kind, combine) {
  n         <- length(per_src[[1L]])
  na_scalar <- if (kind == "numeric") NA_real_ else NA_character_
  present   <- vapply(per_src, function(v) !is.na(v), logical(n))
  if (is.null(dim(present))) present <- matrix(present, nrow = n)
  nsrc      <- as.integer(rowSums(present))

  if (combine == "first") {
    val <- rep(na_scalar, n)
    src <- rep(NA_character_, n)
    for (j in seq_along(ord)) {
      take <- is.na(val) & present[, j]
      val[take] <- per_src[[j]][take]
      src[take] <- ord[j]
    }
    return(list(value = val, source = src, n = nsrc))
  }

  contrib <- ifelse(nsrc > 0L,
                    apply(present, 1L, function(p) paste(ord[p], collapse = ",")),
                    NA_character_)

  if (kind == "numeric") {
    M   <- do.call(cbind, per_src)
    red <- switch(combine,
                  median = function(r) stats::median(r),
                  mean   = function(r) mean(r),
                  min    = function(r) min(r),
                  max    = function(r) max(r))
    val <- vapply(seq_len(n), function(i) {
      r <- M[i, ]; r <- r[!is.na(r)]
      if (!length(r)) NA_real_ else red(r)
    }, numeric(1L))
    return(list(value = val, source = contrib, n = nsrc))
  }

  # categorical "vote": most frequent value, ties broken by priority order.
  M   <- do.call(cbind, per_src)
  val <- vapply(seq_len(n), function(i) {
    r <- M[i, ]
    keep <- !is.na(r)
    if (!any(keep)) return(NA_character_)
    r <- r[keep]
    tb <- table(r)
    top <- names(tb)[tb == max(tb)]
    if (length(top) == 1L) return(top)
    r[r %in% top][1L]            # priority order preserved in r
  }, character(1L))
  list(value = val, source = contrib, n = nsrc)
}
