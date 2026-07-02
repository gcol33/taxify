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
