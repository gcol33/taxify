# Cross-source trait registry.
#
# Maps a canonical trait name to the enrichment sources that carry it, each with
# a crosswalk that harmonizes the source's raw column to one shared vocabulary
# (categorical traits) or unit (numeric traits). add_trait() reads this registry
# to attach a trait from every source at once; list_traits() and trait_info()
# describe it. Adding a trait, or a source to a trait, is an edit to this list --
# no new exported function.
#
#
# ---- How a crosswalk is grounded ------------------------------------------
#
# A unit factor or a value mapping is never taken from a column name alone. The
# evidence runs strongest to weakest, and the strongest rung available decides:
#
#   1. Shared-species calibration. Compare the candidate against a source
#      already registered for the trait, per species, and read the median ratio.
#      This is the only rung that shows two sources agree in practice rather
#      than on paper, and it is the tiebreaker wherever the overlap is thick
#      enough to compute.
#   2. Single-source distribution sanity. With no second source, the median and
#      range must be physically plausible in the claimed unit, and the extremes
#      must be identifiable.
#   3. The source's data dictionary or publication. Pins down the unit AND the
#      definition -- fine-root versus whole-root, index versus concentration --
#      which a value range alone cannot settle.
#   4. The column header. A hint, never proof.
#
# Metadata fixes units and definitions but cannot catch odd encodings (class
# codes, negative sentinels), so rungs 3 and 4 are always paired with a look at
# the raw .vtr values. When the rungs cannot separate a unit factor from a
# definitional difference, the source is not registered.
#
# Two traps this ladder exists to catch, both seen repeatedly:
#
#   - The same-data trap. A candidate that looks like an independent second
#      source but IS the incumbent's data, which a ratio of exactly 1.000 gives
#      away: FISHMORPH max_body_length and fishtraits max_length_cm are both the
#      FishBase max length; AusTraits' specific root area is Mokany & Ash 2008;
#      lizard_traits is the Oskyrko data already registered as repttraits;
#      copepod_traits is the Brun et al. 2017 compilation the zooplankton
#      database ingested. Registering one would double-count a single lineage.
#   - The name-match trap. A column whose name matches a registered trait but
#      whose values are a different quantity. See the rejections at the end.
#
#
# ---- Numeric units ---------------------------------------------------------
#
# Conventions that hold across sources: heights are metres; wood density
# g/cm^3; leaf N and P mg/g; leaf area mm^2; seed and bee ITD lengths mm; depth
# and elevation metres; home range and range size km^2; habitat and diet
# breadth a count; FishBase vulnerability an index 0-100.
#
# Conversions, each with the calibration that fixed it:
#
#   - GIFT seed mass is grams (x1000 -> mg, matches the Diaz mg median); GIFT
#     SLA is cm^2/g (x0.1 -> mm^2/mg, matches LEDA); GIFT leaf thickness is cm
#     (x10 -> 0.22 mm, matches BIEN's 0.21).
#   - Body mass is grams in every animal source except AnimalTraits and
#     HomeRange, which are kg (x1000).
#   - Longevity is years in AnAge, ReptTraits, Amniote and Chelonians;
#     PanTHERIA is months (/12); COMBINE is days (/365.25).
#   - Amniote SVL is cm (x10; the resulting 30490 mm maximum matches COMBINE
#     body length).
#   - LDMC is mg/g in LEDA, GIFT and BROT; Diaz ldmc_g_g is g/g (x1000 -> 195,
#     matches LEDA's 194). Stem specific density feeds wood_density: GIFT
#     gift_ssd and LEDA ssd are mg/cm^3 (/1000 -> 0.63 and 0.70 against GWDD's
#     0.57 g/cm^3).
#   - generation_length: BET is years, COMBINE days (/365.25 -> 6.0 against
#     BET's 6.7). Weaning is days in Amniote, AnAge and PanTHERIA.
#   - Days -> years for the maturity and interval traits: male_maturity_d
#     (AnAge, Amniote, COMBINE), interbirth_interval (COMBINE, AnAge),
#     age_at_first_reproduction (COMBINE).
#   - AusTraits root dry matter content is mg/g (/1000 -> 0.199 g/g against
#     GRooT's 0.227).
#   - leptraits wingspan_mm is MISLABELLED: its values are cm, so it is
#     multiplied by 10. Monarch stores 9.4 against a true ~94 mm wingspan,
#     cabbage white 4.5 against ~45, swallowtail 7.7 against ~77 -- all exactly
#     one tenth. The header is wrong; the known-species check fixes the unit.
#   - kew_sid ships a thousand-seed weight in grams, which equals the per-seed
#     mass in milligrams, so the map is identity. Grounded on shared species
#     against every incumbent mg source: median ratio 1.00 versus diaz
#     (n=23,277), bien (n=10,384), austraits (n=7,738, IQR exactly [1, 1]) and
#     ecoflora (n=2,398). It roughly doubles seed_mass coverage.
#
# Sources joined at ratio 1.00 against an incumbent, so no conversion applies:
# neonate_mass (amniote / combine / pantheria / anage, grams); egg_length and
# egg_width (amniote / repttraits / chelonians, mm); brain_mass (COMBINE grams
# with AnimalTraits kg x1000, 522 shared species); teat_number and
# population_density (pantheria / combine); tongue_length (bee_ostwald /
# eupolltrait proboscis, 162 shared); aspect_ratio (beukhof / quimbayo
# caudal-fin, 406 shared); forearm_length (combine / pantheria / eurobat, 972
# shared -- the standard bat measurement, carried by two incumbents and never
# claimed by a trait); thermal_max and thermal_min from thermofresh against
# globtherm (135 and 16 shared); longevity and clutch_litter_size from eurobat,
# fishtraits and chelonians; incubation_period (amniote / chelonians, 1.05).
#
# Categorical sources joined on agreement across shared species rather than a
# ratio: AusTraits sex_type against tree_of_sex sexual_system, 87% of 572 shared
# (hermaphrodite 250, dioecious 141, monoecious 105), which roughly doubles that
# trait's plant coverage; AusTraits resprouting_capacity against BROT resp_fire,
# 86% of 113; BIRDBASE primary_diet against AVONET trophic_niche, 77% of 12,294,
# where the residual is a scheme difference (aquatic predator against
# invertebrate) rather than the near-exact match a shared lineage would produce.
#
# Two sources of one trait registered with no shared species at all, where the
# quantity is pinned by definition and the medians are the only cross-check:
# p50 (AusTraits -3.41 MPa over 77 species, BROT -3.46 over 46; Australian
# against Mediterranean floras). This is the climatic_temp_mean situation, not
# the salinity one -- water potential at 50% loss of stem conductivity is a
# standardized measurement, so an empty overlap leaves the unit unambiguous.
#
# Sources joined at a ratio that is a real offset rather than a unit error:
# von_bertalanffy_k (beukhof / sharkipedia, 0.88); von_bertalanffy_linf
# (beukhof / sharkipedia, 1.13, thin overlap because sharks skew large);
# specific_root_length and root_mass_fraction (GRooT / AusTraits, 1.12 and
# 0.97); plant_lifespan (bien against gift 1.1, against austraits text-range
# midpoints 0.83); TetraDensity's per-locality population densities run ~1.3x
# below the species-level compilations in the same n/km2 unit, so the median
# reducer absorbs it; chelonians' reproductive_frequency runs 0.6x on a thin
# overlap in the same per-year unit.
#
# Missing-data encodings, stripped to NA:
#
#   - Pelagic trophic_level and several conservation_status columns carry -9999;
#     conservation_status also lets NE and EP fall through to NA.
#   - Amniote female_maturity_d and gestation_d carry negative sentinels,
#     dropped before conversion. huang_amph forelimb_length carries a few
#     near-zero negatives, dropped with num_pos.
#   - fishtraits marks "no mapped native range in the conterminous US" with -1
#     across its whole range-derived block -- area, perimeter, patches,
#     latitudinal and longitudinal range, and both PRISM temperatures -- on the
#     same introduced species, none of which has a centroid to sample. It cannot
#     be stripped per column, because -1 is also a genuine January minimum for 6
#     native species on a continuous 0.1-degree grid running through it; only
#     the pair identifies the sentinel, so the parser strips the block where all
#     of it is in scope.
#
# Extremes that are genuine, not unit errors: amphibian clutch sizes reach the
# thousands and AnAge's egg-layers the millions; beukhof age_max reaches ~390
# years (the Greenland shark) and mussel max_age ~190 (Margaritifera); the
# age_at_maturity tail at 156 years is five deep-sea species.
#
#
# ---- Categorical vocabularies ----------------------------------------------
#
# Value mappers are .xw_cat() for an exact lookup and .xw_grep() for ordered
# regex, which returns the first pattern that matches. Order is load-bearing
# wherever one label contains another:
#
#   - photobiont: ITALIC's dominant value is "green algae other than
#     Trentepohlia", which CONTAINS "Trentepohlia", so a bare match would
#     mislabel all ~185 green-algae species. The green-algae and cyanobacteria
#     classes are tested first.
#   - cell_shape: coccobacillus before its parts. oxygen_metabolism:
#     microaerophilic and anaerobic before aerobic, since both contain "aero".
#     reproductive_mode: ovoviviparous before viviparous and oviparous, whose
#     labels it contains.
#   - diet_guild: compound text diets resolve to their primary token
#     ("omnivorous to carnivorous" -> omnivore), and an ant "predator" ->
#     carnivore.
#
# Codes decoded against data rather than a legend: Parravicini's reef-fish diet
# ships no legend for H/I/O/P/PK, so the ambiguous pair was settled against
# known species -- Chromis, Dascyllus and Pseudanthias are all PK (planktivore),
# Cephalopholis, Epinephelus and Sphyraena all P (piscivore). A first web lookup
# guessed the reverse; the species check corrected it. The COMBINE/PanTHERIA
# activity 1/2/3 code was calibrated against EltonTraits period flags on 5026
# shared species: 1 -> 100% nocturnal, 3 -> 100% diurnal, 2 -> cathemeral.
#
# Derived at build time, so the runtime map is identity: EltonTraits diet_guild
# (one guild per species from the ten diet fractions, summed within guild,
# dominant >=50% wins, else omnivore -- it agrees 93% with EltonTraits' own
# diet_5cat and 83% with AVONET's independent trophic_niche); birdbase
# clutch_mean; NestTrait's nest_structure / nest_site / nest_attachment, kept as
# pipe-delimited multi-modal sets ("cup|dome") since a species genuinely uses
# several; disperse's _mid numeric midpoints.
#
# ellenberg_salt takes Baseflor's salinity column directly: it is the same 0-9
# Ellenberg scale (r = 0.88, mean absolute difference 0.10 against FloraWeb
# ell_salt_de on 2369 shared species).
#
#
# ---- Cautions ---------------------------------------------------------------
#
# A source's `caution` says the unit is right but the definition differs from
# the trait's other sources. Cautioned sources are kept, not dropped: the
# default coalesce switches to "complete" (report the single most-populated
# source verbatim, never a cross-method blend) and emits <trait>_caution.
#
#   - root_diameter: AusTraits is maximum root diameter (APD trait_0012111,
#     including coarse roots, ~0.3x GRooT); GRooT is fine-root.
#   - root_n_concentration: AusTraits root_N_per_dry_mass is whole-root N (APD
#     trait_0000838, ~2x lower); GRooT is fine-root.
#   - rooting_depth: BROT rootdepth runs ~2x GRooT (maximum versus typical).
#
# A per-record caution flags individual rows instead of the whole source, via
# nsrc(caution_col=, caution_fn=). PHYLACINE body mass uses it: parse_phylacine
# keeps the source's Mass.Method as mass_method_class, and a phylogenetically
# imputed or allometrically estimated mass is flagged for that species alone --
# never dropped, never served as a measurement -- while PHYLACINE's measured
# rows carry no caution.
#
# specific_root_area is GRooT-only, in cm^2/g. Three of its source papers
# (Quanquan 2011, an unpublished MSc thesis; Mokany & Ash 2008; Chanteloup &
# Bonis 2013) sit ~1000x below GRooT's standard (data-paper median 385.8) from a
# compilation unit error upstream of GRooT's own conversion. The x1000
# correction is grounded rather than guessed: Mokany & Ash's own SRA-SLA
# regression (Fig 1B, log10 SRA = 1.019 + 0.024*(SLA - 18.208), SRA in m2/kg)
# puts the real magnitude at ~10 m2/kg = ~100 cm2/g, and the stored values x1000
# land in that range (22-538 cm2/g against the regression's 70-260). taxifydb's
# parse_groot rescales those three papers, with standardized sources winning per
# species: a species with any clean record keeps its clean median -- Mokany's
# paper itself cautions that its pot-grown values differ from the field -- and
# the rescaled papers fill only species no clean source covers. The result is
# 529 species, median 386, none below 1. AusTraits is not a second source here
# because it IS Mokany 2008.
#
#
# ---- Traits kept apart -----------------------------------------------------
#
# Pairs that a column name would merge but a definition separates:
#
#   - age_at_maturity / age_at_first_reproduction / male_maturity: first
#     reproduction runs ~1.2x later than female sexual maturity on shared
#     species, and male maturity is a different quantity again.
#   - incubation_period / gestation_incubation: 134 amniote species carry both
#     an external egg phase and a retained phase, so they cannot be one column.
#   - interbirth_interval / reproductive_frequency: an interval, not a rate.
#   - thermal_max, thermal_min / climatic_temp_mean, climatic_temp_min,
#     climatic_temp_max: see the climatic-niche family below.
#   - lichen_growth_form / growth_form: thallus morphology, not tree/shrub/herb.
#   - reproductive_strategy (lichen sexual/asexual) / reproductive_mode (animal
#     oviparous/viviparous).
#   - diel_vertical_migration (daily, zooplankton) / migration (seasonal, birds).
#   - wing_morph / flightless: wing morphology is three-state, and its middle
#     state is the informative one -- a wing-dimorphic carabid produces both a
#     long-winged and a short-winged form, so it is neither flighted nor
#     flightless. flightless asks a bird whether it can fly at all, which
#     admits a yes/no/partial answer to a different question.
#   - eive_* / ellenberg_*: EIVE is a statistical consensus (Dengler et al.
#     2023) built from ~30 regional indicator systems, including the Ellenberg
#     (FloraWeb) and Hill (Ecoflora) values that ellenberg_* already coalesces,
#     so averaging it in would double-count. It stays a continuous 0-10 family
#     of its own; ellenberg_* stays the classic ordinal regional family. EIVE
#     is likewise not rescaled onto the 1-9 scale, which would need a grounded
#     conversion that does not exist.
#
# The climatic-niche family (climatic_temp_mean, climatic_temp_min,
# climatic_temp_max, all deg C) is the home for range-climate columns, kept
# strictly apart from the organismal thermal_max / thermal_min. Both are deg C,
# so the separation is by quantity: a range climate is bounded by dispersal,
# competition and history and sits well inside what the animal survives --
# fishtraits' warmest-month value is 0.88x the CTmax thermofresh measures on the
# same species. Every source is pinned by its own documentation, because
# range-climate columns are unusually easy to mistake for tolerance:
#
#   - climatic_temp_mean: arthropod_traits thermal_mean (WorldClim BIO1 averaged
#     over 0.2-degree buffers around occurrences; Logghe et al. 2025 warn "these
#     data should not be used as precise thermal limits ... this method
#     calculates realised thermal niche") and repttraits mean_annual_temp_c
#     (CHELSA, Karger et al. 2017, over the GARD ranges of Roll et al. 2017, per
#     ReptTraits' own trait-source sheet). The taxa are disjoint, so the
#     coalesce never blends two rasters for one species, and the medians are
#     regionally right: 9.55 for NW European arthropods, 21.01 for global
#     reptiles.
#   - climatic_temp_min / climatic_temp_max: fishtraits min_temp_c and
#     max_temp_c, the coldest-month (January) minimum and warmest-month (July)
#     maximum at the range centroid, from PRISM 400-m grids per the source's
#     FGDC definitions. Single-source, so distribution sanity carries them:
#     min_temp_c median -2.7 with a -22.5 floor, max_temp_c median 32.0 with a
#     20.4 floor, right for a US range climate.
#
# Two things deliberately DO coalesce across disjoint taxa, and the test is
# whether the sources measure the identical quantity: climatic_temp_mean (both
# an annual-mean surface, differing only in raster) and cell_length /
# cell_width, where BacDive's prokaryote cells (median 2 x 0.6 um, a textbook
# rod) join rimet_phyto's microalgae in the same um. Where the quantity differs,
# disjoint taxa are a reason to refuse rather than to allow, because nothing
# would ever surface the mismatch.
#
#
# ---- Sources not registered ------------------------------------------------
#
# Kept here so the decisions are not silently relitigated.
#
# Wrong quantity behind a matching column name:
#
#   - arthropod_traits thermal_maximum / thermal_minimum are not thermal_max /
#     thermal_min. Median 14.5 and maximum 28.7 deg C is a climatic niche edge,
#     not an organismal CTmax (insect CTmax is 40-50); globtherm ran 2.6x apart
#     on the 18 shared species. Nor are they climatic_temp_min / max: they are
#     the spatial minimum and maximum of the ANNUAL MEAN surface across a
#     species' occurrences, a niche breadth on the BIO1 axis, whereas the
#     fishtraits pair is a within-year seasonal extreme at one point. The two
#     differ by roughly 10 deg C for the same place (arthropod thermal_maximum
#     medians 14.46, a NW European annual mean, where a July maximum is ~22).
#     Only thermal_mean joins, because that one IS an annual mean; the rest
#     stay with add_arthropod_traits().
#   - fishtraits min_temp_c / max_temp_c are not thermal limits, for the reason
#     above; the source files them under a "Temperature Tolerances" heading,
#     which is what invites the misreading. min_temp_c reaches -22.5 deg C,
#     impossible for a fish whose water freezes at 0.
#   - eurobat aspectratioindex is not aspect_ratio: a bat's WING aspect ratio is
#     a different measurement from the beukhof/quimbayo fish CAUDAL-FIN one.
#   - FungalRoot elevation_* is the elevation of a genus-grain mycorrhizal
#     sampling record (one number per genus: Acer 85 m, Acanthus 2 m), not a
#     species elevational range limit as in birdbase/repttraits/globtherm; and
#     elevation_max has 7 non-NA values, all degenerate at ~3300 m.
#   - copepod_traits feeder_type is not foraging_mode: only "Ambush feeder" (27)
#     and "Cruise feeder" (30) map to the active/ambush vocabulary, while the
#     majority value "Feeding current" (94) is a third mode with no counterpart.
#   - kew_cvalues genome_size_1c_pg does not join genome_size (madin, bp), even
#     though 1 pg = 0.978 Gbp is a constant. A prokaryote genome size is one
#     haploid chromosome; a plant 1C is the holoploid gametic complement and so
#     scales with ploidy. Kew's own Triticum series shows it -- 6.20 pg at 2x
#     (T. monococcum), 12.00 at 4x (T. turgidum), 17.30 at 6x (T. aestivum) --
#     so T. aestivum's 1C spans three subgenomes where E. coli's spans one. The
#     conversion does not calibrate either, scattering 0.80x (Vitis) to 2.17x
#     (Arabidopsis) against published assemblies. Plant genome size stays behind
#     add_kew_cvalues() as cval_genome_size_1c_pg, in its own unit.
#
# Unit or period that cannot be pinned:
#
#   - fecundity. The zooplankton database carries `fecundity` (median 458) AND a
#     separate `clutchsize` (median 11.7), a 40x gap proving fecundity is a
#     per-year or lifetime aggregate rather than the per-clutch count already
#     shipped as clutch_litter_size. Fish fecundity (Beukhof, from FishBase) is
#     unstandardized between annual and batch fecundity, so it has no pinnable
#     period even single-source. Across the disjoint taxa the values span six
#     orders of magnitude -- spider ~18 eggs/sac, zooplankton ~460, mussel
#     ~89,000 glochidia/brood, maximum 8.3M -- with no shared species to
#     calibrate. disperse_fecundity is out for the same reason.
#   - offspring_size: egg diameter versus hatchling length is ambiguous between
#     amphibio and beukhof, and neonate_mass / egg_mass already cover it.
#     copepod_traits egg_diameter_um is out on the same gap, egg diameter not
#     being the egg_length the amniote/repttraits/chelonians slots measure.
#   - growth_rate: von Bertalanffy K is the one harmonizable slice and already
#     ships as von_bertalanffy_k. Coral linear extension mm/yr, zooplankton
#     per-day, and AnAge's Gompertz constant are physically different rates.
#   - salinity as a marine trait: coral and octocoral seawater ppt ~32-35
#     (n=2-3), pottier's 0-4 tolerance index, and madin's halophily categories
#     are not one quantity. Baseflor's 0-9 soil indicator is the salvageable
#     piece and feeds ellenberg_salt, its true scale.
#   - ploidy: GIFT is "n"/"2"/"2, n" (ambiguous), austraits almost entirely "2",
#     and tree_of_sex's predicted_ploidy is modeled rather than measured,
#     vertebrate-only (n=104, no plants or invertebrates) and mixes clean 2/3/4
#     with junk codes (23, 234, 12.5, 34) -- read off the .vtr, not the header.
#   - GIFT leaf length and width: length x10 is plausible but width did not
#     match AusTraits, so neither was guessed in.
#   - A cross-order forewing_length: leptraits stores cm, odonata mm, bee_ostwald
#     has n=2, and the taxa are disjoint.
#   - octocoral colony_height / colony_width: the column names carry no unit and
#     measure a different dimension from coral colony_diameter.
#   - oral_gape_position was not binned into the categorical mouth_position: the
#     two share only 40 species and the index does not separate quimbayo's
#     classes (terminal spans 0.12-0.69, overlapping superior's 0.30-0.80), so
#     the cutoffs cannot be grounded. The continuous index stays its own trait.
#   - GIFT and BIEN carry only biotic/abiotic pollination, a coarser granularity
#     than pollination_vector: "biotic" is not "insect" (a hummingbird-
#     pollinated plant is biotic), so folding them in would assert a false
#     vector. AusTraits' named insect taxa do map; its coarse biotic/abiotic and
#     its vertebrate records stay NA.
#   - fishtraits repro_guild (Balon codes A_1_1, A_1_2, ...) ships no legend, so
#     decoding it would be a column-header guess.
#   - chowdhury red_list_iucn is not conservation_status. It restates the German
#     national Red List in IUCN letters rather than reporting a global
#     assessment: crossed against red_list_germany over all 382 species it is
#     perfectly diagonal, * to LC (222), 1 to CR (12), 2 to EN (35), 3 to VU
#     (56), V to NT (49), with no off-diagonal cell and two values (R to "rare",
#     G to "Threatened to an unknown extend") that are not IUCN categories at
#     all. National and global extinction risk are different quantities -- a
#     species can be critically endangered at its German range edge and of least
#     concern across its range -- so both columns stay with add_chowdhury().
#   - arthropod_traits body_size_mm is not body_length, because the column
#     changes definition by taxon and nothing in the .vtr says which. For
#     spiders it is a true body length (ratio 1.000 against spider_traits over
#     437 shared species) and for carabids likewise (1.014 against chowdhury
#     over 333), but for Lepidoptera it is forewing length: across 50 species
#     shared with leptraits it is 0.515 of the wingspan (IQR 0.47-0.54), where a
#     butterfly's body is nearer a third of its span. Vanessa atalanta reads
#     29.0 mm against a 55 mm span, its forewing. A registry map sees one column
#     and cannot separate the taxa, and the .vtr carries no order or class, so
#     splitting or per-record cautioning the Lepidoptera rows is a taxifydb
#     build-time change (gcol33/taxifydb#40). Until then the column stays with
#     add_arthropod_traits(). Its feeding_guild, which is taxon-independent, is
#     registered.
#
# Too thin, empty, or an uncatchable error:
#
#   - LEDA leda_seed_mass_mg (values 1-4, a class code, not mg); AmphiBIO
#     longevity_d (values are years); SeaLifeBase trophic_level, FloraWeb
#     chromosome and ploidy, and LEDA leaf dry mass (all empty).
#   - huang_amph eye_diameter: median 3.7 mm is plausible but the maximum is
#     747 mm, a magnitude error with no second source to catch it.
#   - bee_ostwald morphology: forewing_length has n=2, and thorax and hair
#     length are thin (n~90) with itd_mm already covering bee body size.
#
# Better served by a door than by the verb. The cross-source verb exists to
# harmonize; with one source there is nothing to harmonize, and a lossy collapse
# would duplicate a working door:
#
#   - nest_type. Its codebook IS decodable -- BIRDBASE's own Legend and Nest
#     Details sheets define all 14 architecture codes (BU burrow, CP cup, CR
#     crevice, CV tree cavity, DM dome, HC half-cup, NO no nest, O other bird's
#     nest, PL platform, PN pendant, SA saucer, SC scrape, SP sphere, M mound),
#     and the 170 comma-combinations are multi-type nesters. But nest
#     architecture is inherently multi-label and already served at full fidelity
#     by add_birdbase() (the whole comma string) and add_nesttrait() (one-hot
#     neststr_* flags). The registry stores one categorical per species.
#   - economic_use / useful_plants: a single-source 0/1 use matrix (animal_food,
#     human_food, medicines, ...) fully surfaced by add_useful_plants().
#   - economic_cost: InvaCost's cumulative 2017-USD cost, one source, surfaced
#     by add_invacost().
#   - disperse (Sarremejane et al. 2020, 462 European freshwater-invert genera):
#     single-source coarse genus-level ordinal-bin midpoints, surfaced by
#     add_disperse().
#   - edwards_phyto (Edwards et al. 2015, ~130 phytoplankton species): Droop and
#     Monod nutrient uptake and growth parameters (mu, k, vmax, qmin, qmax for
#     ammonium, nitrate and phosphorus), plus cell_volume and carbon_per_cell.
#     No other source carries uptake kinetics, and cell_volume is not the
#     quantity the body-size traits measure.
#   - odonata habitat_openness: an odonate-jargon habitat descriptor, not a
#     distinct behavioural axis.
#   - octocoral tentacles_per_polyp: constant. Its minimum, median and maximum
#     are all 8 across 3,606 species, because eight tentacles is the defining
#     character of Octocorallia. A column with one value carries no information.
#   - octocoral feeding_mechanism: effectively constant, 3,603 of 3,604 records
#     "suspension feeder".
#   - octocoral type_of_skeleton: 21 free-text morphological descriptions ("No
#     axis, unconsolidated sclerites embedded in tissue"), not a vocabulary.
#     Collapsing them is curation that belongs upstream, in the parser.
#   - octocoral colony_height / colony_width: unlabelled unit, and a different
#     dimension from the coral colony_diameter already registered.
#   - bet life_strategy: single-letter codes (c, p, l, s, a, f) with no legend
#     in the .vtr. During's bryophyte life strategies are a known scheme, but
#     decoding the letters from domain memory is the column-header rung of the
#     evidence ladder, which is never enough on its own. Same call as nest_type
#     before its codebook was found.
#   - bet substrate_soil / substrate_rock / substrate_bark / substrate_deadwood:
#     four one-hot flags over the same vocabulary the substrate trait already
#     uses. A registry map sees one column at a time, so collapsing them to a
#     primary substrate is a build-time change in taxifydb, the way NestTrait's
#     one-hot nest flags were collapsed.
#   - coral_traits skeletal_density_g_cm3: 55 species, and not comparable to the
#     wood_density it superficially resembles.
#   - brot barkthick: mixes a thin/thick call with numeric ranges written as
#     "10.0|19.3" in one column over 91 species; the encodings cannot be
#     separated by unit, so AusTraits carries bark_thickness alone.
#
# Build-only sources feed no trait, and the reason is reproducibility rather
# than quality. Every source in this registry is a downloadable .vtr; a source
# reachable only where taxifydb happens to be installed would make add_trait()
# return a different number on two machines running the same code, silently.
# chromosome_number therefore ships from kew_cvalues (9,375 species) alone even
# though CCDB reaches 65,051 and its counts are now correct (taxifydb doubles
# the gametic number CCDB's service reports; ratio against kew 1.0000, IQR
# [1, 1] across 6140 shared species, 83.3% exact). The divergence a silent swap
# would introduce is real, not cosmetic: the two compilations disagree on which
# cytotype is typical for 6.1% of shared species -- Duchesnea indica 84 against
# 14. CCDB is reached through add_ccdb(), as gmpd, plantatt, bryoatt and clopla
# are through theirs.
#
#
# ---- Engine notes ----------------------------------------------------------
#
# A source may set join_col = "genus", which add_trait() threads through
# .trait_join_one() to enrich_simple(join_col=). Without it a genus-keyed source
# joins on accepted_name and silently returns all-NA, so every genus-keyed
# enrichment must set it: fungal_traits (fungal_trophic_mode), fungalroot
# (mycorrhizal_type), blanchard (diet_guild). A guard test enumerates the
# genus-keyed enrichments and asserts the flag.
#
# `caution` (the definition or method differs, unit correct) is distinct from
# `note` (how the value was harmonized); both show in trait_info(), only
# `caution` reaches the output.


# Per-record caution text for a PHYLACINE body mass, keyed on the mass provenance
# class (parse_phylacine's mass_method_class). Measured (`reported`) masses get
# no caution; model-derived masses are flagged for that species only.
.phylacine_mass_caution <- function(v) {
  cls <- tolower(trimws(as.character(v)))
  out <- rep(NA_character_, length(cls))
  out[cls == "imputed"]   <- paste(
    "PHYLACINE body mass is phylogenetically imputed for this species",
    "(a model estimate, not a measurement).")
  out[cls == "estimated"] <- paste(
    "PHYLACINE body mass is estimated by allometric scaling for this species",
    "(not a direct measurement).")
  out
}


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


# AusTraits records flowering as a 12-character y/n string, one character per
# month starting at January ("nnnnnnnnyyyn" is September to November). A
# southern-hemisphere season wraps the year boundary, so "yynnnnnnnnny" is
# December to February, not January to December: the flowering window is the
# longest CIRCULAR run of "y", read off two concatenated years. Returns a
# two-column matrix of start and end month; the trait slots take one column
# each. Computed over distinct values and matched back, because a handful of
# strings cover tens of thousands of rows.
.austraits_flower_window <- function(v) {
  s <- tolower(trimws(as.character(v)))
  s[!is.na(s) & !nzchar(s)] <- NA_character_
  u <- unique(s[!is.na(s)])
  lut <- matrix(NA_real_, nrow = length(u), ncol = 2L)
  for (k in seq_along(u)) {
    if (!grepl("^[yn]{12}$", u[k])) next
    m <- strsplit(u[k], "", fixed = TRUE)[[1]] == "y"
    if (!any(m)) next
    if (all(m)) { lut[k, ] <- c(1, 12); next }
    r   <- rle(rep(m, 2L))
    idx <- which(r$values)
    len <- pmin(r$lengths[idx], 12L)
    b   <- idx[which.max(len)]
    run <- min(r$lengths[b], 12L)
    st0 <- if (b == 1L) 1L else sum(r$lengths[seq_len(b - 1L)]) + 1L
    lut[k, ] <- c(((st0 - 1L) %% 12L) + 1L, ((st0 + run - 2L) %% 12L) + 1L)
  }
  i <- match(s, u)
  cbind(lut[i, 1L], lut[i, 2L])
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
    "insekt|insect|bee|beetle|fly|flies|butterfly|moth|wasp|thrip|hymenopt|lepidopt|dipter|coleopt|hoverfly|midge" = "insect",
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
  mgcm2g  <- function(v) num(v) / 1000       # mg/cm^3 -> g/cm^3 (stem specific density)
  # A categorical source used verbatim: trim, empty string -> NA. Used for the
  # NestTrait columns, whose values are already pipe-delimited multi-modal tokens
  # (e.g. "tree|cliff_bank") that must be preserved, not collapsed to one token.
  chr_verbatim <- function(v) { s <- trimws(as.character(v)); s[!nzchar(s)] <- NA_character_; s }

  # AusTraits flowering window, one column of .austraits_flower_window() each.
  aus_flr_start <- function(v) .austraits_flower_window(v)[, 1L]
  aus_flr_end   <- function(v) .austraits_flower_window(v)[, 2L]

  # Resprouting after fire. AusTraits is a clean token set; a record listing
  # both states ("fire_killed resprouts") is a species observed either way, so
  # it reads as partial and the combined patterns are tested first. BROT's
  # resp_fire mixes three encodings in one column -- yes/no, an ordinal
  # high/low/variable, and the percentage of individuals resprouting -- so the
  # numeric arm is handled before the regex arm rather than through it.
  resprout_patterns <- c(
    "partial"                                   = "partial",
    "fire_killed.*resprouts|resprouts.*fire_killed" = "partial",
    "resprout"                                  = "resprouter",
    "fire_killed"                               = "non_resprouter")
  brot_resprout <- function(v) {
    s   <- tolower(trimws(as.character(v)))
    n   <- suppressWarnings(as.numeric(s))
    out <- rep(NA_character_, length(s))
    # The percentage arm: 0 is no resprouting, anything above it resprouts.
    out[!is.na(n) & n <= 0] <- "non_resprouter"
    out[!is.na(n) & n >  0] <- "resprouter"
    out[is.na(n)] <- .xw_grep(s[is.na(n)], c(
      "^no$"             = "non_resprouter",
      "variable|^low$"   = "partial",
      "^yes$|^high$"     = "resprouter"))
    out
  }

  # Soil seed-bank persistence. BROT stores "persistence|method", so only the
  # first token is the class; AusTraits' "widely_dispersed" is a dispersal
  # statement rather than a persistence class and falls through to NA.
  seedbank_patterns <- c(
    "long.?persistent"  = "long_persistent",
    "short.?persistent" = "short_persistent",
    "mid.?persistent"   = "persistent",
    "persistent"        = "persistent",
    "transient"         = "transient")

  # Bryophyte growth architecture (During's life-form scheme). Kept apart from
  # the vascular-plant life_form and growth_form traits for the same reason
  # lichen_growth_form is: it is a different scheme over a different structure,
  # and merging the vocabularies would make "turf" and "hemicryptophyte"
  # comparable terms.
  # The seven values BET actually carries. During's published scheme has more
  # (fan, pendant, tail), but a vocabulary term the source never emits is a
  # guess about the data rather than a reading of it.
  bryoform_patterns <- c(
    "turf" = "turf", "cushion" = "cushion", "weft" = "weft",
    "dendroid" = "dendroid", "rosette" = "rosette", "annual" = "annual",
    "mat" = "mat")

  # Bird primary habitat (BIRDBASE's own 14-term vocabulary, taken verbatim
  # in lower case).
  # All fourteen values BIRDBASE carries, lower-cased and otherwise untouched --
  # including "artificial", its own term for human-modified habitat, which is
  # kept rather than renamed to a tidier "urban" the source never says.
  birdhab_patterns <- c(
    "forest" = "forest", "woodland" = "woodland", "shrub" = "shrub",
    "grassland" = "grassland", "savanna" = "savanna", "wetland" = "wetland",
    "riparian" = "riparian", "coastal" = "coastal", "sea" = "sea",
    "rocky" = "rocky", "plains" = "plains", "artificial" = "artificial",
    "desert" = "desert", "bamboo" = "bamboo")

  # BIRDBASE primary diet onto the shared diet_guild vocabulary. Fish maps to
  # carnivore because the vocabulary has no piscivore term, the same call the
  # parravicini P code already takes.
  birddiet_lookup <- c(
    "invertebrate" = "invertivore", "fruit" = "frugivore", "seed" = "granivore",
    "nectar" = "nectarivore", "omnivore" = "omnivore", "herbivore" = "herbivore",
    "plant" = "herbivore", "vertebrate" = "carnivore", "fish" = "carnivore",
    "carnivore" = "carnivore", "scavenger" = "scavenger")

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
    mericarp = "schizocarp", nutlet = "nut", pome = "pome")
  diet_lookup <- c(
    invertivore = "invertivore", omnivore = "omnivore",
    omnivorous = "omnivore", frugivore = "frugivore",
    `aquatic predator` = "carnivore", vertivore = "carnivore",
    carnivorous = "carnivore", granivore = "granivore",
    nectarivore = "nectarivore", `herbivore terrestrial` = "herbivore",
    `herbivore aquatic` = "herbivore", herbivorous = "herbivore",
    scavenger = "scavenger")
  # Ordered-regex diet mapper for text sources with compound labels: the primary
  # guild is taken by pattern order, so "omnivorous to carnivorous" -> omnivore
  # (omnivore is tested before carnivore) while bare "carnivorous" -> carnivore.
  diet_patterns <- c(
    "omnivor"                     = "omnivore",
    "carnivor|predator|piscivor"  = "carnivore",
    "herbivor"                    = "herbivore",
    "detritivor"                  = "detritivore",
    "planktivor"                  = "planktivore",
    "insectivor|invertivor"       = "invertivore",
    "frugivor"                    = "frugivore",
    "granivor"                    = "granivore",
    "nectarivor"                  = "nectarivore",
    "scaveng"                     = "scavenger",
    "fungivor"                    = "fungivore")
  # Wing morphology, three-state. Dimorphic species produce both a long-winged
  # and a short-winged form, and which form dominates is the question carabid
  # dispersal ecology asks, so it is a class of its own rather than a midpoint
  # or a missing value. Kept in the source's plain terms; macropterous and
  # brachypterous are the entomological synonyms.
  wing_lookup <- c("long-winged" = "long-winged", "macropterous" = "long-winged",
                   "short-winged" = "short-winged", "brachypterous" = "short-winged",
                   "dimorphic" = "dimorphic", "wing-dimorphic" = "dimorphic")
  # Chowdhury's seven German carabid habitat classes onto primary_habitat. Five
  # are the vocabulary's own terms. "open" is added to it: open habitat
  # (Offenland -- arable, grassland, heath, sand) is the modal class at 142 of
  # 382 species, and narrowing it to "grassland" would assert a vegetation type
  # the source does not. Eurytopic states niche breadth rather than a habitat,
  # and "Special habitats" is a residual bin, so both stay NA.
  carabhab_lookup <- c("coastal" = "coastal", "forest" = "forest",
                       "open" = "open", "riparian" = "riparian",
                       "wetland" = "wetland")
  # Parravicini reef-fish trophic guild codes. The source ships no legend, so
  # the P/PK pair was disambiguated empirically against known species (Chromis /
  # Dascyllus / Pseudanthias all PK = planktivores; Cephalopholis / Epinephelus /
  # Sphyraena all P = piscivores): H herbivore, I invertivore, O omnivore,
  # P piscivore (-> carnivore), PK planktivore.
  parra_guild <- c(H = "herbivore", I = "invertivore", O = "omnivore",
                   P = "carnivore", PK = "planktivore")
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

  # IUCN Red List categories: short codes and full names to the standard set;
  # NE / EP / -9999 / blank fall through to NA.
  iucn_lookup <- c(
    lc = "LC", nt = "NT", vu = "VU", en = "EN", cr = "CR",
    ew = "EW", ex = "EX", dd = "DD",
    "least concern" = "LC", "near threatened" = "NT", "vulnerable" = "VU",
    "endangered" = "EN", "critically endangered" = "CR",
    "extinct in the wild" = "EW", "extinct" = "EX", "data deficient" = "DD",
    "conservation dependent" = "NT")

  # Fish body shape (ordered regex; -9999 and unmatched -> NA).
  bodyshape_patterns <- c(
    "fusiform|torpedo"          = "fusiform",
    "elongat|eel"               = "elongated",
    "compress|laterally|short"  = "compressed",
    "depress|flat|dorso"        = "depressed",
    "globiform|globe|spher|box" = "globiform")

  # Sexual system across plants and animals (separate vs combined sexes).
  sexsys_patterns <- c(
    "hermaphrodit"          = "hermaphrodite",
    "monoec"                = "monoecious",
    "gonochor"              = "gonochoric",
    "dioec"                 = "dioecious",
    "parthenogen"           = "parthenogenetic")

  leaftype_patterns <- c(
    "broadlea|broad lea" = "broadleaf",
    "needle"             = "needle",
    "scale"              = "scale",
    "leafless|photosynthetic stem" = "leafless")

  decid_patterns <- c(
    "evergreen"          = "evergreen",
    "semi.?decid"        = "semi-deciduous",
    "decid"              = "deciduous",
    "variable|facultative" = "variable")

  # 0/1 habitat-realm flags to yes/no.
  binary_yn <- c("1" = "yes", "0" = "no", "true" = "yes", "false" = "no",
                 "yes" = "yes", "no" = "no", "y" = "yes", "n" = "no")

  # Diel activity. Text vocabularies (repttraits, chelonians, quimbayo) map
  # directly; the ordered patterns take the primary period of a compound value
  # ("diurnal but nests at night" -> diurnal) and fold mixed/both records into
  # cathemeral. The 1/2/3 PanTHERIA code (COMBINE, PanTHERIA) is grounded
  # against EltonTraits period flags on 5026 shared species: code 1 is 100%
  # nocturnal, code 3 is 100% diurnal, code 2 is crepuscular / mixed -> mapped
  # to cathemeral (the coarse mixed class the code cannot resolve further).
  act_patterns <- c(
    "cathemeral|diurnal and nocturnal|day and night|both" = "cathemeral",
    "crepuscular"                                         = "crepuscular",
    "diurnal|day"                                         = "diurnal",
    "nocturnal|night"                                     = "nocturnal")
  act_code <- c("1" = "nocturnal", "2" = "cathemeral", "3" = "diurnal")

  # Foraging mode: active (widely foraging) vs ambush (sit-and-wait) vs mixed.
  forage_patterns <- c(
    "act|active|wide|cruise" = "active",
    "amb|ambush|sit"         = "ambush",
    "mixed|both|inter"       = "mixed")

  # Parity mode: ovoviviparous must be tested before viviparous and oviparous
  # (its label contains both substrings). Shark reproductive strategies
  # (matrotrophy, placentotrophy, aplacental/histotrophic/lecithotrophic
  # viviparity) all collapse to viviparous.
  parity_patterns <- c(
    "ovovivip|ovo.?vivip" = "ovoviviparous",
    "vivip|matrotroph|placentotroph|histotroph|lecithotroph|trophonemata|aplacental" = "viviparous",
    "ovip"                = "oviparous")

  # Coral habitat preferences (coral_traits + octocoral share these vocabularies).
  coloniality_lookup <- c(colonial = "colonial", solitary = "solitary", both = "both")
  wave_lookup    <- c(protected = "protected", exposed = "exposed",
                      broad = "intermediate", both = "intermediate")
  clarity_lookup <- c(clear = "clear", turbid = "turbid", both = "both")
  zoox_lookup    <- c(zooxanthellate = "zooxanthellate",
                      azooxanthellate = "azooxanthellate", both = "both")

  # Algae (algae_traits): calcification state, gamete type, life-cycle ploidy
  # phase (compound "haplodiplontic > isomorphic" -> primary phase), and the
  # substrate the thallus attaches to.
  calc_lookup <- c(`non-calcified` = "non-calcified",
                   `calcified articulated` = "calcified-articulated",
                   `calcified non-articulated` = "calcified-non-articulated")
  gamete_lookup <- c(oogamous = "oogamous", isogamous = "isogamous",
                     anisogamous = "anisogamous")
  algcyc_patterns <- c(haplodiplontic = "haplodiplontic",
                       diplontic = "diplontic", haplontic = "haplontic")
  algsub_lookup <- c(epilithic = "epilithic", epiphytic = "epiphytic",
                     endophytic = "endophytic", endolithic = "endolithic",
                     endozoic = "endozoic", epizoic = "epizoic",
                     unattached = "unattached")

  # Marine benthic invertebrate functional guilds. arctic_traits and nztd carry
  # the same three axes under different wording; harmonized to standard groups
  # (Solan/Queiros bioturbation functional groups; standard living-habit and
  # feeding-guild vocabularies).
  bioturb_patterns <- c(
    "no bioturbation|^none$" = "none",
    "biodiffus|diffusive"    = "biodiffusor",
    "conveyor"               = "conveyor",
    "bioirrig"               = "bioirrigator",
    "surface"                = "surface-modifier")
  livhabit_patterns <- c(
    "free living|crawler" = "free-living",
    "burrow"              = "burrowing",
    "tube"                = "tube-dwelling",
    "crevice"             = "crevice-dwelling",
    "parasit|commensal"   = "parasitic",
    "attach|zoic|phytic"  = "attached")
  feedguild_patterns <- c(
    "deposit"             = "deposit-feeder",
    "filter|suspension"   = "suspension-feeder",
    "predator"            = "predator",
    "graz|scrap"          = "grazer",
    "scaveng|opportunist" = "scavenger")

  # Octocoral colony growth form (type_of_growth).
  ocgrow_lookup <- c(`erect branched` = "erect-branched",
                     `erect unbranched` = "erect-unbranched",
                     `horizontal unbranched` = "horizontal-unbranched",
                     `horizontal branched` = "horizontal-branched",
                     massive = "massive", encrusting = "encrusting",
                     `solitary/pseudosolitary` = "solitary")

  # Caudal fin shape (beukhof + quimbayo share these fish fin categories).
  fin_patterns <- c(
    "round"     = "rounded",
    "fork"      = "forked",
    "trunc"     = "truncate",
    "lanceolat" = "lanceolate",
    "point"     = "pointed",
    "lunate"    = "lunate",
    "heteroc"   = "heterocercal")

  # Bacterial oxygen metabolism (madin); "microaerophilic" and "anaerobic" both
  # contain the "aero" substring, so they are tested before "aerobic".
  oxymet_patterns <- c(
    "microaero" = "microaerophilic",
    "facultat"  = "facultative",
    "anaerob"   = "anaerobic",
    "aerob"     = "aerobic")

  # Bacterial cell shape (madin + bacdive); "coccobacillus" tested before its two
  # parts. bacdive adds ovoid/oval/ellipsoidal (short ovoid rods -> coccobacillus),
  # sphere (-> coccus) and curved (-> vibrio); none collide with madin's tokens.
  cellshape_patterns <- c(
    "coccobac|ovoid|oval|ellips"      = "coccobacillus",
    "bacill|rod"                      = "bacillus",
    "cocc|sphere"                     = "coccus",
    "spiral|helic"                    = "spiral",
    "vibrio|comma|curved"             = "vibrio",
    "filament"                        = "filament",
    "star|pleo|tail|disc|flask|ring|box|triangular" = "other")

  # Spider hunting guild (World Spider Trait DB; Cardoso et al. 2011 guilds).
  # Web-builders and hunters fold to the standard guild set; "active hunter"
  # and bare "hunter" fall to other-hunter.
  spider_guild_patterns <- c(
    "orb"         = "orb weaver",
    "sheet"       = "sheet-web weaver",
    "space"       = "space-web weaver",
    "ambush"      = "ambush hunter",
    "ground"      = "ground hunter",
    "specialist"  = "specialist",
    "sensing"     = "sensing",
    "hunter|hunt" = "other hunter")

  # Spider web building (World Spider Trait DB): builds a web or not; "burrow"
  # is a retreat, not a web, and falls through to NA.
  webbuild_lookup <- c(yes = "yes", no = "no", present = "yes", absent = "no")

  # Zooplankton presence flags (bioluminescence, diel vertical migration): the
  # ordered regex on "present"/"absent" folds "likely present" and
  # "present; weak/strong/reverse" to yes and leaves "maybe" as NA.
  presence_yn <- c("present" = "yes", "absent" = "no")

  # Freshwater-mussel sexual system (sheld): hermaphrodite flag true/false.
  mussel_sexsys <- c(`true` = "hermaphrodite", `false` = "gonochoric")

  # Bee sociality (eupolltrait); brood parasites and inquilines -> cleptoparasite.
  sociality_patterns <- c(
    "eusocial"                        = "eusocial",
    "parasocial|primitively|subsocial" = "parasocial",
    "brood_parasite|inquiline|clepto" = "cleptoparasite",
    "solitary"                        = "solitary")

  # Lichen thallus growth form (italic); lichenicolous / non-lichenised entries
  # are lifestyle categories, not thallus forms, so they fall through to NA.
  lichen_gf_patterns <- c(
    "crustose"   = "crustose",
    "foliose"    = "foliose",
    "fruticose"  = "fruticose",
    "squamulose" = "squamulose",
    "leprose"    = "leprose")

  # Lichen substrate (italic); a multi-substrate record is reduced to one primary
  # class by priority (rock > bark > wood > soil > leaves); the rare "bark and
  # rocks"-type compounds take the higher-priority class.
  lichen_substrate_patterns <- c(
    "rock"                 = "rock",
    "bark"                 = "bark",
    "lignum|wood"          = "wood",
    "soil|terricol|debris" = "soil",
    "leaf|leaves|foliicol" = "leaves")

  # Lichen photobiont (italic). Trap: the dominant value "green algae other than
  # Trentepohlia" CONTAINS the substring "Trentepohlia", so the green-algae and
  # cyanobacteria classes must be tested before the bare Trentepohlia class.
  photobiont_patterns <- c(
    "other than trentepohlia|green alga" = "green algae",
    "cyanobacteria"                      = "cyanobacteria",
    "trentepohlia"                       = "Trentepohlia")

  # Lichen reproductive strategy (italic); "mainly sexual, or asexual ..." keeps
  # the primary (sexual), "mainly asexual, by soredia/isidia/fragmentation" -> asexual.
  lichen_repro_patterns <- c(
    "mainly sexual"  = "sexual",
    "mainly asexual" = "asexual")

  # Fungal trophic mode. funguild's compound hyphenated values (a fungus with
  # several modes) become "mixed"; fungal_traits' primary_lifestyle vocabulary
  # (wood_saprotroph, plant_pathogen, ectomycorrhizal, ...) maps to the same
  # three modes by ordered regex.
  fungtroph_funguild <- function(v) {
    s <- tolower(trimws(as.character(v)))
    out <- .xw_cat(s, c(pathotroph = "pathotroph", saprotroph = "saprotroph",
                        symbiotroph = "symbiotroph"))
    out[grepl("-", s)] <- "mixed"
    out
  }
  fungtroph_patterns <- c(
    "pathogen|parasit"                              = "pathotroph",
    "saprotroph|saprobe|decay|rot"                  = "saprotroph",
    "mycorrhiz|lichen|symbio|endophyt|epiphyt"      = "symbiotroph")

  # Fish air breathing (fishbase); "Water"/"WaterAssumed" -> none.
  airbreath_patterns <- c(
    "facultat" = "facultative",
    "obligat"  = "obligate",
    "water|assumed" = "none")

  # Leaf lifespan is in months in all three sources: on shared species the
  # austraits / brot / bien medians agree 1:1 (ratio ~1.0), so they are used
  # verbatim. austraits whole-plant lifespan is a text range in years
  # ("10--50"); its midpoint agrees with bien numeric years (ratio 0.83).
  range_mid <- function(v) {
    s <- gsub("--", "-", trimws(as.character(v)))
    parts <- strsplit(s, "-", fixed = TRUE)
    vapply(parts, function(z) {
      z <- suppressWarnings(as.numeric(z)); z <- z[!is.na(z)]
      if (!length(z)) NA_real_ else mean(z)
    }, numeric(1))
  }

  # A numeric source that is used verbatim (already in the canonical unit).
  # `caution` (default NA) flags a source whose unit is correct but whose
  # method/definition differs from the trait's reference source (e.g. maximum
  # vs fine-root diameter). It drives the method-aware coalesce in add_trait().
  # `caution_col` + `caution_fn` flag INDIVIDUAL rows instead of the whole
  # source: `caution_col` names a companion column in the same enrichment and
  # `caution_fn` maps its per-species value to caution text (NA where none), so
  # e.g. a PHYLACINE body mass that is model-imputed for one species is flagged
  # for that species only, without cautioning the source's measured values. A
  # per-record caution annotates provenance; it does not make the trait
  # method-discordant (it stays out of the coalesce's complete/median switch).
  # `group` pins the grain a source is read at, as a named length-1 vector
  # (c(<group column> = <value>)). A .vtr that carries several rows per species
  # -- one per group plus a species-level aggregate, e.g. gidias's
  # affected_taxon -- is otherwise read by whichever row sorts first, which is
  # not a contract. Sources on a single-grain .vtr leave it NULL.
  nsrc <- function(enr, col, cite, note, map = num, caution = NA_character_,
                   join_col = "accepted_name", group = NULL,
                   caution_col = NA_character_, caution_fn = NULL) {
    list(enrichment = enr, col = col, citation = cite, note = note,
         map = map, caution = caution, join_col = join_col, group = group,
         caution_col = caution_col, caution_fn = caution_fn)
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
        ecoflora  = nsrc("ecoflora", "seed_weight_mg_uk", "Ecoflora (Fitter & Peat 1994)", "Milligrams."),
        kew_sid   = nsrc("kew_sid", "thousand_seed_weight", "Kew SID (RBG Kew)", "Thousand-seed weight in grams equals per-seed mass in milligrams (x1).")
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
        bien      = nsrc("bien", "wood_density_g_cm3", "BIEN (Maitner et al. 2018)", "g/cm^3."),
        gift      = nsrc("gift", "gift_ssd_mean", "GIFT (Weigelt et al. 2020)", "Stem specific density, mg/cm^3 converted to g/cm^3 (/1000; 630 -> 0.63).", map = mgcm2g),
        leda      = nsrc("leda", "ssd_g_cm3", "LEDA (Kleyer et al. 2008)", "Stem specific density, mg/cm^3 converted to g/cm^3 (/1000).", map = mgcm2g)
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
    leaf_length = list(
      label = "Leaf length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        austraits = nsrc("austraits", "leaf_length_mm", "AusTraits (Falster et al. 2021)", "Leaf length, mm.")
      )
    ),
    leaf_width = list(
      label = "Leaf width", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        austraits = nsrc("austraits", "leaf_width_mm", "AusTraits (Falster et al. 2021)", "Leaf width, mm.")
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
    leaf_lifespan = list(
      label = "Leaf lifespan", kind = "numeric", unit = "months", vocab = NULL,
      sources = list(
        austraits = nsrc("austraits", "leaf_lifespan", "AusTraits (Falster et al. 2021)", "Months."),
        brot      = nsrc("brot", "leaflifespan", "BROT 2.0 (Tavsanoglu & Pausas 2018)", "Months (agrees 1:1 with bien on shared species)."),
        bien      = nsrc("bien", "leaf_lifespan", "BIEN (Maitner et al. 2018)", "Months.")
      )
    ),
    plant_lifespan = list(
      label = "Whole-plant lifespan", kind = "numeric", unit = "yr", vocab = NULL,
      sources = list(
        bien      = nsrc("bien", "maximum_whole_plant_longevity", "BIEN (Maitner et al. 2018)", "Maximum whole-plant longevity, years."),
        gift      = nsrc("gift", "gift_lifespan_1", "GIFT (Weigelt et al. 2020)", "Years (agrees with bien, ratio 1.1 on shared species)."),
        austraits = nsrc("austraits", "lifespan", "AusTraits (Falster et al. 2021)", "Text year-range (e.g. '10--50') taken at its midpoint; agrees with bien years (ratio 0.83).", map = range_mid)
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
        phylacine    = nsrc("phylacine", "mass_g", "PHYLACINE (Faurby et al. 2018)", "Grams.",
                            caution_col = "mass_method_class",
                            caution_fn  = .phylacine_mass_caution),
        repttraits   = nsrc("repttraits", "body_mass_g", "ReptTraits (Oskyrko et al. 2024)", "Grams."),
        fishbase     = nsrc("fishbase", "body_mass_g", "FishBase (Froese & Pauly)", "Grams.",
                            caution = "FishBase Weight is the maximum published weight, not an adult mean."),
        sealifebase  = nsrc("sealifebase", "body_mass_g", "SeaLifeBase (Palomares & Pauly)", "Grams.",
                            caution = "SeaLifeBase Weight is the maximum published weight, not an adult mean."),
        frugivoria   = nsrc("frugivoria", "body_mass_g", "Frugivoria (Gerstner et al.)", "Grams."),
        pottier      = nsrc("pottier", "body_mass_g", "Pottier et al.", "Grams."),
        animaltraits = nsrc("animaltraits", "body_mass_kg", "AnimalTraits (Herberstein et al. 2022)", "kg converted to grams (x1000).", map = numk),
        homerange    = nsrc("homerange", "body_mass_kg", "Broekman et al. HomeRange", "kg converted to grams (x1000).", map = numk),
        eurobat      = nsrc("eurobat", "body_mass_g", "EuroBaT (European bat traits)", "Grams (ratio 0.99 vs combine and 1.03 vs pantheria on shared species).")
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
        amphibio   = nsrc("amphibio", "longevity_yr", "AmphiBIO (Oliveira et al. 2017)", "Maximum longevity, years."),
        beukhof    = nsrc("beukhof", "age_max", "Beukhof et al. 2019", "Maximum observed age, years (ratio 1.00 vs anage on shared species; the ~390 yr maximum is the Greenland shark, not a unit error)."),
        fishtraits = nsrc("fishtraits", "longevity_yr", "FishTraits v14.3 (Frimpong & Angermeier 2009)", "Maximum age of US freshwater fish, years (ratio 1.00 vs anage on 295 shared species)."),
        eurobat    = nsrc("eurobat", "max_longevity_yr", "EuroBaT (European bat traits)", "Maximum longevity, years (ratio 1.00 vs anage on 28 shared species)."),
        sheld      = nsrc("sheld", "max_age", "Freshwater Mussel Traits (Hopper et al. 2023)", "Maximum age, years (freshwater mussels; the ~190 yr maximum is Margaritifera, genuine).")
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
        amphibio   = nsrc("amphibio", "litter_size", "AmphiBIO (Oliveira et al. 2017)", "Eggs per clutch (amphibian clutches reach the thousands)."),
        chelonians = nsrc("chelonians", "clutch_size_mean", "TurtleTraits (Chelonians)", "Mean eggs per clutch (ratio 1.00 vs amniote on shared species)."),
        birdbase   = nsrc("birdbase", "clutch_mean", "Birdbase", "Mean of the reported clutch min/max (ratio 1.00 vs amniote on 6781 shared species)."),
        eurobat    = nsrc("eurobat", "litter_size", "EuroBaT (European bat traits)", "Offspring per litter (ratio 1.00 vs combine and pantheria on shared species)."),
        zooplankton = nsrc("zooplankton", "clutchsize", "Global Zooplankton Trait DB (Pata & Hunt 2025)", "Eggs per clutch of marine zooplankton. Distinct from the source's fecundity column, which is a per-year/lifetime aggregate and stays unregistered.")
      )
    ),
    age_at_maturity = list(
      label = "Age at female maturity", kind = "numeric", unit = "yr", vocab = NULL,
      sources = list(
        anage      = nsrc("anage", "female_maturity_d", "AnAge (Tacutu et al. 2018)", "Days converted to years (/365.25).", map = d2y),
        amniote    = nsrc("amniote", "female_maturity_d", "Amniote LHD (Myhrvold et al. 2015)", "Days converted to years (/365.25); negative sentinels dropped.", map = d2y),
        amphibio   = nsrc("amphibio", "age_maturity_y", "AmphiBIO (Oliveira et al. 2017)", "Years."),
        chelonians = nsrc("chelonians", "age_maturity_y", "TurtleTraits (Chelonians)", "Years (ratio 1.00 vs anage on shared species)."),
        beukhof    = nsrc("beukhof", "age_maturity", "Beukhof et al. 2019", "Age at maturity, years (ratio 1.00 vs anage on 198 shared species; a handful of deep-sea species exceed 50 yr)."),
        fishtraits = nsrc("fishtraits", "maturity_age_yr", "FishTraits v14.3 (Frimpong & Angermeier 2009)", "Age at maturity of US freshwater fish, years (the years unit is confirmed against anage, whose days column runs 365x higher on 70 shared species; medians agree at 3 yr vs beukhof)."),
        sheld      = nsrc("sheld", "mature_age", "Freshwater Mussel Traits (Hopper et al. 2023)", "Age at maturity, years (freshwater mussels).")
      )
    ),
    male_maturity = list(
      label = "Age at male maturity", kind = "numeric", unit = "yr", vocab = NULL,
      sources = list(
        anage   = nsrc("anage", "male_maturity_d", "AnAge (Tacutu et al. 2018)", "Days converted to years (/365.25).", map = d2y),
        amniote = nsrc("amniote", "male_maturity_d", "Amniote LHD (Myhrvold et al. 2015)", "Days converted to years (/365.25); negative sentinels dropped.", map = d2y),
        combine = nsrc("combine", "male_maturity_d", "COMBINE (Soria et al. 2021)", "Days converted to years (/365.25; ratio 1.00 vs anage on 708 shared species). Male analogue of age_at_maturity.", map = d2y)
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
    incubation_period = list(
      label = "Egg incubation period", kind = "numeric", unit = "days", vocab = NULL,
      sources = list(
        amniote    = nsrc("amniote", "incubation_d", "Amniote LHD (Myhrvold et al. 2015)", "External egg incubation, days; negative sentinels dropped. Distinct from gestation_d (134 amniote species carry both).", map = num_pos),
        chelonians = nsrc("chelonians", "incubation_d", "TurtleTraits (Chelonians)", "Egg incubation, days (ratio 1.05 vs amniote on 122 shared species).")
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
        sealifebase = nsrc("sealifebase", "body_length_cm", "SeaLifeBase (Palomares & Pauly)", "Body length, cm converted to mm (x10).", map = cm2mm),
        huang_amph  = nsrc("huang_amph", "svl_mm", "Huang et al. amphibian morphology", "Snout-vent length, mm."),
        pottier     = nsrc("pottier", "svl_mm", "Pottier et al. 2022", "Snout-vent length, mm."),
        spider_traits = nsrc("spider_traits", "body_length_mm", "World Spider Trait DB (Pekar et al. 2021)", "Total body length, mm (across-record median, not split by sex; distribution-sanity grounded, disjoint taxon)."),
        zooplankton = nsrc("zooplankton", "body_length_max_mm", "Global Zooplankton Trait DB (Pata & Hunt 2025)", "Maximum body length, mm (gelatinous colonial chains reach ~1 m)."),
        sheld       = nsrc("sheld", "max_length_mm", "Freshwater Mussel Traits (Hopper et al. 2023)", "Maximum shell length, mm (freshwater mussels)."),
        chowdhury   = nsrc("chowdhury", "body_length_mm", "Chowdhury et al. 2025 (German carabids)",
                           paste("Mean body length of 382 German ground beetles, the only",
                                 "beetle source the verb carries. Grounded transitively: it",
                                 "runs 1.014 against arthropod_traits' beetle values over 333",
                                 "shared species, and those are themselves 1.000 against",
                                 "spider_traits' measured body lengths over 437. Recorded on a",
                                 "0.5 mm grid, so it is coarser than the sources around it --",
                                 "a precision limit, not a different measurement."))
      )
    ),
    metabolic_rate = list(
      label = "Metabolic rate", kind = "numeric", unit = "W", vocab = NULL,
      sources = list(
        anage        = nsrc("anage", "metabolic_rate_w", "AnAge (Tacutu et al. 2018)", "Watts."),
        animaltraits = nsrc("animaltraits", "metabolic_rate_w", "AnimalTraits (Herberstein et al. 2022)", "Watts.")
      )
    ),
    brain_mass = list(
      label = "Brain mass", kind = "numeric", unit = "g", vocab = NULL,
      sources = list(
        combine      = nsrc("combine", "adult_brain_mass_g", "COMBINE (Soria et al. 2021)", "Adult brain mass, grams."),
        animaltraits = nsrc("animaltraits", "brain_size", "AnimalTraits (Herberstein et al. 2022)", "kg converted to grams (x1000; ratio 1.00 vs COMBINE on 522 shared species).", map = numk)
      )
    ),
    reproductive_frequency = list(
      label = "Litters or clutches per year", kind = "numeric", unit = "per year", vocab = NULL,
      sources = list(
        amniote    = nsrc("amniote", "clutches_per_y", "Amniote LHD (Myhrvold et al. 2015)", "Clutches or litters per year.", map = num_pos),
        combine    = nsrc("combine", "litters_per_year_n", "COMBINE (Soria et al. 2021)", "Litters per year."),
        anage      = nsrc("anage", "litters_clutches_per_year", "AnAge (Tacutu et al. 2018)", "Litters or clutches per year (ratio 1.00 vs combine on shared species)."),
        pantheria  = nsrc("pantheria", "x16_1_littersperyear", "PanTHERIA (Jones et al. 2009)", "Litters per year (ratio 1.00 vs combine on shared species)."),
        repttraits = nsrc("repttraits", "number_of_litters_or_clutches_produced_per_year", "ReptTraits (Oskyrko et al. 2024)", "Clutches per year (ratio 1.00 vs amniote on shared species)."),
        chelonians = nsrc("chelonians", "clutches_per_year", "TurtleTraits (Chelonians)", "Clutches per year; turtle counts run ~0.6x amniote on the thin shared overlap, same unit, coalesced by median.")
      )
    ),
    interbirth_interval = list(
      label = "Interbirth or inter-litter interval", kind = "numeric", unit = "yr", vocab = NULL,
      sources = list(
        pantheria = nsrc("pantheria", "x14_1_interbirthinterval_d", "PanTHERIA (Jones et al. 2009)", "Days converted to years (/365.25).", map = d2y),
        combine   = nsrc("combine", "interbirth_interval_d", "COMBINE (Soria et al. 2021)", "Days converted to years (/365.25; ratio 1.00 vs pantheria on 750 shared species).", map = d2y),
        amniote   = nsrc("amniote", "inter_litter_or_interbirth_interval_y", "Amniote LHD (Myhrvold et al. 2015)", "Years (ratio 1.00 vs combine on 1301 shared species); negative sentinels dropped.", map = num_pos),
        anage     = nsrc("anage", "inter_litter_interbirth_interval", "AnAge (Tacutu et al. 2018)", "Days converted to years (/365.25; median 1.0 yr matches the day-scale sources).", map = d2y)
      )
    ),
    teat_number = list(
      label = "Teat or nipple number", kind = "numeric", unit = "count", vocab = NULL,
      sources = list(
        pantheria = nsrc("pantheria", "x24_1_teatnumber", "PanTHERIA (Jones et al. 2009)", "Teat count.", map = num_pos),
        combine   = nsrc("combine", "teat_number_n", "COMBINE (Soria et al. 2021)", "Teat count (ratio 1.00 vs pantheria on 682 shared species).", map = num_pos)
      )
    ),
    population_density = list(
      label = "Population density", kind = "numeric", unit = "individuals/km2", vocab = NULL,
      sources = list(
        pantheria    = nsrc("pantheria", "x21_1_populationdensity_n_km2", "PanTHERIA (Jones et al. 2009)", "Individuals per square kilometre.", map = num_pos),
        combine      = nsrc("combine", "density_n_km2", "COMBINE (Soria et al. 2021)", "Individuals per square kilometre (ratio 1.00 vs pantheria on 1026 shared species).", map = num_pos),
        tetradensity = nsrc("tetradensity", "density_ind_km2", "TetraDensity (Santini et al. 2018)", "Individuals per square kilometre; per-locality records run ~1.3x below the species-level compilations (same unit, biological/dataset offset), coalesced by median.", map = num_pos)
      )
    ),
    neonate_mass = list(
      label = "Neonate body mass", kind = "numeric", unit = "g", vocab = NULL,
      sources = list(
        amniote   = nsrc("amniote", "birth_hatching_wt_g", "Amniote LHD (Myhrvold et al. 2015)", "Birth or hatching weight, grams."),
        combine   = nsrc("combine", "neonate_mass_g", "COMBINE (Soria et al. 2021)", "Neonate mass, grams (agrees 1:1 with amniote on shared species)."),
        pantheria = nsrc("pantheria", "x5_3_neonatebodymass_g", "PanTHERIA (Jones et al. 2009)", "Neonate body mass, grams."),
        anage     = nsrc("anage", "birth_mass_g", "AnAge (Tacutu et al. 2018)", "Birth mass, grams.")
      )
    ),
    egg_mass = list(
      label = "Egg mass", kind = "numeric", unit = "g", vocab = NULL,
      sources = list(
        amniote = nsrc("amniote", "egg_mass_g", "Amniote LHD (Myhrvold et al. 2015)", "Egg mass, grams.")
      )
    ),
    egg_length = list(
      label = "Egg length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        amniote    = nsrc("amniote", "egg_length_mm", "Amniote LHD (Myhrvold et al. 2015)", "Egg length, mm."),
        repttraits = nsrc("repttraits", "egg_length_mm", "ReptTraits (Oskyrko et al. 2024)", "Egg length, mm (ratio 1.00 vs amniote on shared species)."),
        chelonians = nsrc("chelonians", "egg_size_length_mm", "TurtleTraits (Chelonians)", "Egg length, mm (ratio 1.00 vs amniote and repttraits on shared species).")
      )
    ),
    egg_width = list(
      label = "Egg width", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        amniote    = nsrc("amniote", "egg_width_mm", "Amniote LHD (Myhrvold et al. 2015)", "Egg width, mm."),
        repttraits = nsrc("repttraits", "egg_width_mm", "ReptTraits (Oskyrko et al. 2024)", "Egg width, mm (ratio 1.00 vs amniote on shared species)."),
        chelonians = nsrc("chelonians", "egg_size_width_mm", "TurtleTraits (Chelonians)", "Egg width, mm (ratio 1.00 vs amniote on shared species).")
      )
    ),

    ## ---- plant phenology (numeric, month of year) -------------------------
    flowering_start = list(
      label = "Flowering start (month)", kind = "numeric", unit = "month (1-12)", vocab = NULL,
      sources = list(
        baseflor  = nsrc("baseflor", "flower_begin_month", "Baseflor (Julve, Catminat)", "Month 1-12."),
        ecoflora  = nsrc("ecoflora", "flower_begin_month_uk", "Ecoflora (Fitter & Peat 1994)", "Month 1-12."),
        austraits = nsrc("austraits", "flowering_time", "AusTraits (Falster et al. 2021)",
                         "First month of the longest circular run of flowering months in AusTraits' 12-character y/n string. Circular because a southern-hemisphere season wraps December to February.",
                         map = aus_flr_start)
      )
    ),
    flowering_end = list(
      label = "Flowering end (month)", kind = "numeric", unit = "month (1-12)", vocab = NULL,
      sources = list(
        baseflor  = nsrc("baseflor", "flower_end_month", "Baseflor (Julve, Catminat)", "Month 1-12."),
        ecoflora  = nsrc("ecoflora", "flower_end_month_uk", "Ecoflora (Fitter & Peat 1994)", "Month 1-12."),
        austraits = nsrc("austraits", "flowering_time", "AusTraits (Falster et al. 2021)",
                         "Last month of the longest circular run of flowering months in AusTraits' 12-character y/n string.",
                         map = aus_flr_end)
      )
    ),

    ## ---- fire response and regeneration -----------------------------------
    resprouting = list(
      label = "Resprouting after fire", kind = "categorical", unit = NA_character_,
      vocab = c("resprouter", "partial", "non_resprouter"),
      sources = list(
        austraits = list(enrichment = "austraits", col = "resprouting_capacity",
                     citation = "AusTraits (Falster et al. 2021)",
                     note = "resprouts / fire_killed / partial_resprouting; a record listing both states is read as partial.",
                     map = function(v) .xw_grep(v, resprout_patterns)),
        brot      = list(enrichment = "brot", col = "resp_fire",
                     citation = "BROT 2.0 (Tavsanoglu & Pausas 2018)",
                     note = paste("Three encodings in one column: yes/no, an ordinal high/low/variable,",
                                  "and the percentage of individuals resprouting. The numeric arm is",
                                  "read first (0 non-resprouter, above 0 resprouter). Agrees with",
                                  "AusTraits on 86% of 113 shared species."),
                     map = brot_resprout)
      )
    ),
    serotiny = list(
      label = "Serotiny", kind = "categorical", unit = NA_character_,
      vocab = c("serotinous", "non_serotinous"),
      sources = list(
        austraits = list(enrichment = "austraits", col = "serotiny",
                     citation = "AusTraits (Falster et al. 2021)",
                     note = "Canopy seed storage; the graded serotiny_low/moderate/high records all read as serotinous.",
                     map = function(v) .xw_grep(v, c(
                       "not_serotinous"        = "non_serotinous",
                       "serotin"               = "serotinous")))
        # BROT serotinylevel (8 species) and canopyseedbank (11) are too thin to
        # register, and BROT's own values are a 0-49 percentage rather than the
        # presence call AusTraits makes.
      )
    ),
    soil_seed_bank = list(
      label = "Soil seed-bank persistence", kind = "categorical", unit = NA_character_,
      vocab = c("transient", "short_persistent", "persistent", "long_persistent"),
      sources = list(
        austraits = list(enrichment = "austraits", col = "seedbank_longevity_class",
                     citation = "AusTraits (Falster et al. 2021)",
                     note = "Persistence class; widely_dispersed is a dispersal statement rather than a persistence class and falls through to NA.",
                     map = function(v) .xw_grep(v, seedbank_patterns)),
        brot      = list(enrichment = "brot", col = "soil_seed_bank",
                     citation = "BROT 2.0 (Tavsanoglu & Pausas 2018)",
                     note = "Stored as persistence|method; only the first token is the class, and BROT's mid-persistent folds into persistent.",
                     caution = paste("BROT and AusTraits classify seed-bank persistence by different",
                                     "operational definitions -- burial depth and trial duration differ",
                                     "between the compilations -- and agree on only 67% of 48 shared",
                                     "species once both are collapsed to persistent against transient.",
                                     "The two are reported separately rather than blended."),
                     map = function(v) .xw_grep(v, seedbank_patterns))
      )
    ),

    ## ---- plant hydraulics --------------------------------------------------
    ## The drought-mortality axis. Both P50 sources are megapascals by
    ## definition (water potential at 50% loss of stem conductivity) and the
    ## overlap is empty -- BROT is Mediterranean, AusTraits Australian -- so the
    ## unit rests on the definition plus the two medians landing together at
    ## -3.4 MPa, the way the disjoint climatic_temp_mean sources do. Coverage is
    ## thin (123 species across both) and the trait is registered on that basis.
    p50 = list(
      label = "Xylem embolism resistance (P50)", kind = "numeric", unit = "MPa", vocab = NULL,
      sources = list(
        austraits = nsrc("austraits", "stem_water_potential_50percent_lost_conductivity",
                     "AusTraits (Falster et al. 2021)",
                     "Stem water potential at 50% loss of hydraulic conductivity, MPa (negative). Median -3.41 over 77 species."),
        brot      = nsrc("brot", "p50", "BROT 2.0 (Tavsanoglu & Pausas 2018)",
                     "MPa (negative). Median -3.46 over 46 species; no species shared with AusTraits, so the two medians are the only cross-check.")
      )
    ),
    turgor_loss_point = list(
      label = "Leaf turgor loss point", kind = "numeric", unit = "MPa", vocab = NULL,
      sources = list(
        austraits = nsrc("austraits", "leaf_turgor_loss_point", "AusTraits (Falster et al. 2021)",
                     "Leaf water potential at turgor loss, MPa (negative).")
      )
    ),
    sapwood_conductivity = list(
      label = "Sapwood specific hydraulic conductivity", kind = "numeric",
      unit = "kg m-1 s-1 MPa-1", vocab = NULL,
      sources = list(
        austraits = nsrc("austraits", "sapwood_specific_hydraulic_conductivity",
                     "AusTraits (Falster et al. 2021)", "Sapwood-area-specific conductivity.")
      )
    ),
    huber_value = list(
      label = "Huber value", kind = "numeric", unit = "index (m2/m2)", vocab = NULL,
      sources = list(
        austraits = nsrc("austraits", "huber_value", "AusTraits (Falster et al. 2021)",
                     "Sapwood area per unit leaf area, dimensionless.")
      )
    ),
    bark_thickness = list(
      label = "Bark thickness", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        austraits = nsrc("austraits", "bark_thickness", "AusTraits (Falster et al. 2021)", "Millimetres.")
        # BROT barkthick is not a second source: it mixes a thin/thick call with
        # numeric ranges written as "10.0|19.3" in the same column, over 91
        # species, and the two encodings cannot be separated by unit.
      )
    ),
    self_compatibility = list(
      label = "Self-compatibility", kind = "categorical", unit = NA_character_,
      vocab = c("self_compatible", "self_incompatible"),
      sources = list(
        tree_of_sex = list(enrichment = "tree_of_sex", col = "selfing",
                       citation = "Tree of Sex Consortium 2014",
                       note = "Breeding-system compatibility, distinct from the sexual_system trait; records carrying both states fall through to NA.",
                       map = function(v) .xw_cat(v, c(
                         "self compatible"   = "self_compatible",
                         "self incompatible" = "self_incompatible")))
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
        ecoflora = nsrc("ecoflora", "ell_salt_uk", "Ecoflora (Fitter & Peat 1994)", "British Ellenberg salt tolerance."),
        baseflor = nsrc("baseflor", "salinity", "Baseflor (Julve, Programme Catminat)", "Ellenberg-style salinity, same 0-9 scale (Pearson r = 0.88 vs FloraWeb on shared species).")
      )
    ),

    ## ---- EIVE continuous indicator values (numeric, 0-10 scale) -----------
    ## A separate family from ellenberg_* on purpose: EIVE is a statistical
    ## consensus of ~30 regional systems (Ellenberg and Hill among them), so it
    ## is single-source here and never coalesced with the ordinal values it is
    ## partly derived from. Same gradients, different framework and scale.
    eive_light = list(
      label = "EIVE light (L)", kind = "numeric", unit = "0-10 (EIVE)", vocab = NULL,
      sources = list(
        eive = nsrc("eive", "light", "EIVE 1.0 (Dengler et al. 2023)", "Continuous light indicator, 0-10.")
      )
    ),
    eive_temperature = list(
      label = "EIVE temperature (T)", kind = "numeric", unit = "0-10 (EIVE)", vocab = NULL,
      sources = list(
        eive = nsrc("eive", "temperature", "EIVE 1.0 (Dengler et al. 2023)", "Continuous temperature indicator, 0-10.")
      )
    ),
    eive_moisture = list(
      label = "EIVE moisture (M)", kind = "numeric", unit = "0-10 (EIVE)", vocab = NULL,
      sources = list(
        eive = nsrc("eive", "moisture", "EIVE 1.0 (Dengler et al. 2023)", "Continuous moisture indicator, 0-10.")
      )
    ),
    eive_reaction = list(
      label = "EIVE reaction (R)", kind = "numeric", unit = "0-10 (EIVE)", vocab = NULL,
      sources = list(
        eive = nsrc("eive", "reaction", "EIVE 1.0 (Dengler et al. 2023)", "Continuous soil reaction (pH) indicator, 0-10.")
      )
    ),
    eive_nutrients = list(
      label = "EIVE nutrients (N)", kind = "numeric", unit = "0-10 (EIVE)", vocab = NULL,
      sources = list(
        eive = nsrc("eive", "nutrients", "EIVE 1.0 (Dengler et al. 2023)", "Continuous nutrient indicator, 0-10.")
      )
    ),

    ## ---- categorical traits -----------------------------------------------
    woodiness = list(
      label = "Woodiness", kind = "categorical", unit = NA_character_,
      vocab = c("woody", "non-woody", "variable"),
      sources = list(
        zanne = list(
          enrichment = "zanne", col = "woodiness",
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
    # Invasive-species impact (IUCN EICAT / SEICAT). GIDIAS already stores the
    # canonical category, so the map only validates the token; single-source for
    # now but kept in the verb because further EICAT sources (an IUCN registry,
    # taxon-specific assessments) coalesce onto the same ordinal categories.
    environmental_impact = list(
      label = "Environmental impact (EICAT)", kind = "categorical", unit = NA_character_,
      vocab = c("MC", "MN", "MO", "MR", "MV", "DD"),
      sources = list(
        gidias = nsrc("gidias", "gidias_eicat_category", "Bacher et al. 2025 (GIDIAS)",
                      "IUCN EICAT category: most severe magnitude among the species' negative environmental impacts (MC/MN/MO/MR/MV), or DD.",
                      group = c(affected_taxon = "Any"),
                      map = function(v) {
                        u <- toupper(trimws(as.character(v)))
                        u[!(u %in% c("MC", "MN", "MO", "MR", "MV", "DD"))] <- NA_character_
                        u
                      })
      )
    ),
    socioeconomic_impact = list(
      label = "Socio-economic impact (SEICAT)", kind = "categorical", unit = NA_character_,
      vocab = c("MC", "MN", "MO", "MR", "DD"),
      sources = list(
        gidias = nsrc("gidias", "gidias_seicat_category", "Bacher et al. 2025 (GIDIAS)",
                      "IUCN SEICAT category: most severe magnitude among the species' negative socio-economic impacts (MC/MN/MO/MR), or DD.",
                      group = c(affected_taxon = "Any"),
                      map = function(v) {
                        u <- toupper(trimws(as.character(v)))
                        u[!(u %in% c("MC", "MN", "MO", "MR", "DD"))] <- NA_character_
                        u
                      })
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
                        map = function(v) .xw_grep(v, poll_patterns)),
        floraweb = list(enrichment = "floraweb", col = "pollination_vector_de",
                        citation = "FloraWeb / BiolFlor (Klotz et al. 2002)", note = "German compound vector taken at its primary token (agrees 82-91% with baseflor/ecoflora on shared species).",
                        map = function(v) .xw_grep(v, poll_patterns)),
        austraits = list(enrichment = "austraits", col = "pollination_syndrome",
                         citation = "AusTraits (Falster et al. 2021)", note = "Named insect taxa (bee, beetle, fly, moth, ...) map to insect; the coarse 'biotic'/'abiotic' and animal (bird, bat, vertebrate) records have no single vector in this vocabulary and stay NA.",
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
                        map = function(v) .xw_cat(v, fr_lookup)),
        austraits = list(enrichment = "austraits", col = "fruit_type",
                        citation = "AusTraits (Falster et al. 2021)", note = "Morphological fruit type; mericarp -> schizocarp, nutlet -> nut, unmatched long-tail types -> NA.",
                        map = function(v) .xw_cat(v, fr_lookup))
      )
    ),
    diet_guild = list(
      label = "Diet guild", kind = "categorical", unit = NA_character_,
      vocab = c("carnivore", "herbivore", "omnivore", "invertivore",
                "planktivore", "detritivore", "frugivore", "granivore",
                "nectarivore", "scavenger", "fungivore"),
      sources = list(
        avonet       = list(enrichment = "avonet", col = "trophic_niche",
                          citation = "AVONET (Tobias et al. 2022)", note = "Trophic niche; vertivore and aquatic predator -> carnivore, herbivore terrestrial/aquatic -> herbivore.",
                          map = function(v) .xw_cat(v, diet_lookup)),
        elton_traits = list(enrichment = "elton_traits", col = "diet_guild",
                          citation = "EltonTraits 1.0 (Wilman et al. 2014)", note = "Dominant guild from the ten diet-fraction columns (summed within guild, >=50% wins, else omnivore); birds and mammals. Agrees 93% with EltonTraits' own diet_5cat, 83% with AVONET.",
                          map = function(v) v),
        repttraits   = list(enrichment = "repttraits", col = "diet",
                          citation = "ReptTraits (Oskyrko et al. 2024)", note = "Carnivorous / herbivorous / omnivorous.",
                          map = function(v) .xw_cat(v, diet_lookup)),
        chelonians   = list(enrichment = "chelonians", col = "diet",
                          citation = "TurtleTraits (Chelonians)", note = "Turtle diet; compound labels ('omnivorous to carnivorous') take the primary guild by pattern order.",
                          map = function(v) .xw_grep(v, diet_patterns)),
        blanchard    = list(enrichment = "blanchard", col = "diet", join_col = "genus",
                          citation = "Blanchard et al. (ant traits)", note = "Ant diet (genus-keyed); predator -> carnivore.",
                          map = function(v) .xw_grep(v, diet_patterns)),
        parravicini  = list(enrichment = "parravicini", col = "trophic_guild",
                          citation = "Parravicini et al. 2020", note = "Reef-fish guild codes (legend verified empirically): H herbivore, I invertivore, O omnivore, P piscivore -> carnivore, PK planktivore.",
                          map = function(v) .xw_cat(v, parra_guild)),
        eurobat      = list(enrichment = "eurobat", col = "diet_type",
                          citation = "EuroBaT (European bat traits)", note = "European bats; insectivorous -> invertivore, frugivorous -> frugivore.",
                          map = function(v) .xw_grep(v, diet_patterns)),
        zooplankton  = list(enrichment = "zooplankton", col = "trophic_group",
                          citation = "Global Zooplankton Trait DB (Pata & Hunt 2025)", note = "Marine zooplankton; primary token of a compound value (carnivore/omnivore/herbivore/detritivore/planktivore); suspension-feeder and parasite -> NA.",
                          map = function(v) .xw_grep(v, diet_patterns)),
        birdbase     = list(enrichment = "birdbase", col = "primary_diet",
                          citation = "Sekercioglu et al. 2025 (BIRDBASE)",
                          note = paste("An independent bird diet classification, not a copy of an",
                                       "incumbent: it agrees with AVONET's trophic niche on 77% of",
                                       "12,294 shared species, and the disagreements are scheme",
                                       "differences (aquatic predator against invertebrate) rather",
                                       "than the exact match a shared lineage would give. Listed last,",
                                       "so it fills the birds AVONET and EltonTraits miss."),
                          map = function(v) .xw_cat(v, birddiet_lookup)),
        arthropod_traits = list(enrichment = "arthropod_traits", col = "feeding_guild",
                          citation = "Logghe et al. 2025 (NW European arthropod traits)",
                          note = paste("3,800 NW European arthropods, the guild vocabulary",
                                       "mapping straight across (herbivore, carnivore,",
                                       "omnivore, detritivore, fungivore). Its 'pollinator'",
                                       "names a function rather than a diet and has no",
                                       "counterpart in the vocabulary, and 'non-eating'",
                                       "marks adults that do not feed; both stay NA."),
                          map = function(v) .xw_grep(v, diet_patterns)),
        chowdhury    = list(enrichment = "chowdhury", col = "trophic_level",
                          citation = "Chowdhury et al. 2025 (German carabids)",
                          note = paste("Predator, herbivore and omnivore for 382 German ground",
                                       "beetles. It agrees with arthropod_traits' independent",
                                       "guild on 86.6% of 292 shared species -- a second",
                                       "classification rather than a copy, which would agree",
                                       "near-exactly. Listed after it, so it fills the carabids",
                                       "that compilation misses."),
                          map = function(v) .xw_grep(v, diet_patterns))
      )
    ),
    wing_morph = list(
      label = "Wing morphology", kind = "categorical", unit = NA_character_,
      vocab = c("long-winged", "short-winged", "dimorphic"),
      sources = list(
        chowdhury = list(enrichment = "chowdhury", col = "wing_morph",
                          citation = "Chowdhury et al. 2025 (German carabids)",
                          note = paste("Long-winged (257), short-winged (42) and wing-dimorphic",
                                       "(83) German ground beetles. Dimorphism is a third",
                                       "state, not a missing value: a dimorphic species",
                                       "produces both forms, and the balance between them is",
                                       "what carabid dispersal ecology measures. Distinct from",
                                       "the bird trait flightless, which asks whether a species",
                                       "can fly at all."),
                          map = function(v) .xw_cat(v, wing_lookup))
      )
    ),
    activity_time = list(
      label = "Diel activity time", kind = "categorical", unit = NA_character_,
      vocab = c("diurnal", "nocturnal", "crepuscular", "cathemeral"),
      sources = list(
        repttraits = list(enrichment = "repttraits", col = "active_time",
                          citation = "ReptTraits (Oskyrko et al. 2024)", note = "Diurnal / Nocturnal / Cathemeral / Crepuscular.",
                          map = function(v) .xw_grep(v, act_patterns)),
        chelonians = list(enrichment = "chelonians", col = "activity_time",
                          citation = "TurtleTraits (Chelonians)", note = "Primary period of a possibly compound text value.",
                          map = function(v) .xw_grep(v, act_patterns)),
        quimbayo   = list(enrichment = "quimbayo", col = "diel_activity",
                          citation = "Quimbayo et al. 2021", note = "day / night / both -> diurnal / nocturnal / cathemeral.",
                          map = function(v) .xw_grep(v, act_patterns)),
        combine    = list(enrichment = "combine", col = "activity_cycle",
                          citation = "COMBINE (Soria et al. 2021)", note = "PanTHERIA 1/2/3 code, grounded on EltonTraits flags: 1 nocturnal, 2 cathemeral, 3 diurnal.",
                          map = function(v) .xw_cat(v, act_code)),
        pantheria  = list(enrichment = "pantheria", col = "x1_1_activitycycle",
                          citation = "PanTHERIA (Jones et al. 2009)", note = "PanTHERIA 1/2/3 activity-cycle code: 1 nocturnal, 2 cathemeral, 3 diurnal.",
                          map = function(v) .xw_cat(v, act_code)),
        spider_traits = list(enrichment = "spider_traits", col = "circadian_activity",
                          citation = "World Spider Trait DB (Pekar et al. 2021)", note = "Clean text tokens (diurnal / nocturnal / crepuscular) mapped; the source's numeric fuzzy-affinity codes fall through to NA.",
                          map = function(v) .xw_grep(v, act_patterns))
      )
    ),
    foraging_mode = list(
      label = "Foraging mode", kind = "categorical", unit = NA_character_,
      vocab = c("active", "ambush", "mixed"),
      sources = list(
        repttraits = list(enrichment = "repttraits", col = "foraging_mode",
                          citation = "ReptTraits (Oskyrko et al. 2024)", note = "ACT -> active, AMB -> ambush (sit-and-wait), Mixed -> mixed.",
                          map = function(v) .xw_grep(v, forage_patterns)),
        chelonians = list(enrichment = "chelonians", col = "foraging_mode",
                          citation = "TurtleTraits (Chelonians)", note = "ACT -> active, AMB -> ambush.",
                          map = function(v) .xw_grep(v, forage_patterns))
      )
    ),
    migration = list(
      label = "Migratory behaviour (bird)", kind = "categorical", unit = NA_character_,
      vocab = c("sedentary", "partial", "full"),
      sources = list(
        avonet = list(enrichment = "avonet", col = "migration",
                      citation = "AVONET (Tobias et al. 2022)", note = "sedentary / partial / full migrant.",
                      map = function(v) .xw_cat(v, c(sedentary = "sedentary", partial = "partial",
                                                     full = "full", migratory = "full")))
      )
    ),
    flightless = list(
      label = "Flightlessness (bird)", kind = "categorical", unit = NA_character_,
      vocab = c("no", "yes", "partial"),
      sources = list(
        birdbase = list(enrichment = "birdbase", col = "flightlessness",
                        citation = "Sekercioglu et al. 2025 (BIRDBASE)", note = "Flightless: no / yes / partial.",
                        map = function(v) .xw_cat(v, c(no = "no", yes = "yes", partial = "partial")))
      )
    ),
    venomous = list(
      label = "Venomous (reptile)", kind = "categorical", unit = NA_character_,
      vocab = c("yes", "no"),
      sources = list(
        repttraits = list(enrichment = "repttraits", col = "venomous_yes_or_no",
                          citation = "ReptTraits (Oskyrko et al. 2024)", note = "Venomous flag.",
                          map = function(v) .xw_cat(v, binary_yn))
      )
    ),
    sociality = list(
      label = "Sociality (bee)", kind = "categorical", unit = NA_character_,
      vocab = c("solitary", "parasocial", "eusocial", "cleptoparasite"),
      sources = list(
        eupolltrait = list(enrichment = "eupolltrait", col = "sociality",
                           citation = "EuPollTrait (Milicic et al. 2025)", note = "solitary / parasocial / eusocial; brood parasites and inquilines -> cleptoparasite.",
                           map = function(v) .xw_grep(v, sociality_patterns))
      )
    ),
    lecty = list(
      label = "Pollen host breadth (bee lecty)", kind = "categorical", unit = NA_character_,
      vocab = c("polylectic", "oligolectic", "monolectic"),
      sources = list(
        eupolltrait = list(enrichment = "eupolltrait", col = "larval_diet_breadth",
                           citation = "EuPollTrait (Milicic et al. 2025)", note = "Pollen host breadth: polylectic (many hosts) / oligolectic (few) / monolectic (one).",
                           map = function(v) .xw_cat(v, c(polylectic = "polylectic",
                              oligolectic = "oligolectic", monolectic = "monolectic")))
      )
    ),
    nesting_strategy = list(
      label = "Nesting strategy (bee)", kind = "categorical", unit = NA_character_,
      vocab = c("excavator", "renter", "mason"),
      sources = list(
        eupolltrait = list(enrichment = "eupolltrait", col = "nesting_behavior",
                           citation = "EuPollTrait (Milicic et al. 2025)", note = "excavator (digs its own nest) / renter (occupies existing cavities) / mason (builds with collected material).",
                           map = function(v) .xw_cat(v, c(excavator = "excavator", renter = "renter", mason = "mason")))
      )
    ),
    territoriality = list(
      label = "Territoriality (odonate)", kind = "categorical", unit = NA_character_,
      vocab = c("territorial", "non-territorial"),
      sources = list(
        odonata = list(enrichment = "odonata", col = "territoriality",
                       citation = "Odonate Phenotypic Database (Waller et al.)", note = "territorial / non-territorial mating behaviour.",
                       map = function(v) .xw_cat(v, c(territorial = "territorial", `non-territorial` = "non-territorial")))
      )
    ),
    mate_guarding = list(
      label = "Mate guarding (odonate)", kind = "categorical", unit = NA_character_,
      vocab = c("contact", "noncontact", "none"),
      sources = list(
        odonata = list(enrichment = "odonata", col = "mate_guarding",
                       citation = "Odonate Phenotypic Database (Waller et al.)", note = "contact (tandem) / noncontact (sentinel) / none.",
                       map = function(v) .xw_cat(v, c(contact = "contact", noncontact = "noncontact", none = "none")))
      )
    ),
    flight_mode = list(
      label = "Flight mode (odonate)", kind = "categorical", unit = NA_character_,
      vocab = c("percher", "flier"),
      sources = list(
        odonata = list(enrichment = "odonata", col = "flight_mode",
                       citation = "Odonate Phenotypic Database (Waller et al.)", note = "percher (sit-and-wait) / flier (continuous patrolling).",
                       map = function(v) .xw_cat(v, c(percher = "percher", flier = "flier")))
      )
    ),
    gram_stain = list(
      label = "Gram stain (prokaryote)", kind = "categorical", unit = NA_character_,
      vocab = c("positive", "negative"),
      sources = list(
        madin = list(enrichment = "madin", col = "gram_stain",
                     citation = "Madin et al. 2020 (prokaryote traits)", note = "Gram-positive / Gram-negative.",
                     map = function(v) .xw_cat(v, c(positive = "positive", negative = "negative"))),
        bacdive = list(enrichment = "bacdive", col = "gram_stain",
                     citation = "BacDive (DSMZ; Reimer et al. 2022)", note = "positive / negative ('variable' strains dropped).",
                     map = function(v) .xw_cat(v, c(positive = "positive", negative = "negative")))
      )
    ),
    oxygen_metabolism = list(
      label = "Oxygen metabolism (prokaryote)", kind = "categorical", unit = NA_character_,
      vocab = c("aerobic", "anaerobic", "facultative", "microaerophilic"),
      sources = list(
        madin = list(enrichment = "madin", col = "metabolism",
                     citation = "Madin et al. 2020 (prokaryote traits)", note = "aerobic / anaerobic / facultative / microaerophilic (obligate variants folded in).",
                     map = function(v) .xw_grep(v, oxymet_patterns)),
        bacdive = list(enrichment = "bacdive", col = "oxygen_metabolism",
                     citation = "BacDive (DSMZ; Reimer et al. 2022)", note = "aerobe/anaerobe/facultative anaerobe/microaerophile folded to the same four classes.",
                     map = function(v) .xw_grep(v, oxymet_patterns))
      )
    ),
    cell_shape = list(
      label = "Cell shape (prokaryote)", kind = "categorical", unit = NA_character_,
      vocab = c("bacillus", "coccus", "coccobacillus", "spiral", "vibrio", "filament", "other"),
      sources = list(
        madin = list(enrichment = "madin", col = "cell_shape",
                     citation = "Madin et al. 2020 (prokaryote traits)", note = "bacillus (rod) / coccus / coccobacillus / spiral / vibrio / filament.",
                     map = function(v) .xw_grep(v, cellshape_patterns)),
        bacdive = list(enrichment = "bacdive", col = "cell_shape",
                     citation = "BacDive (DSMZ; Reimer et al. 2022)", note = "rod -> bacillus; ovoid/oval -> coccobacillus; sphere -> coccus; curved -> vibrio.",
                     map = function(v) .xw_grep(v, cellshape_patterns))
      )
    ),
    motility = list(
      label = "Motility (prokaryote)", kind = "categorical", unit = NA_character_,
      vocab = c("motile", "non-motile"),
      sources = list(
        madin = list(enrichment = "madin", col = "motility",
                     citation = "Madin et al. 2020 (prokaryote traits)", note = "flagella / gliding / axial filament -> motile; 'no' -> non-motile.",
                     map = function(v) .xw_cat(v, c(no = "non-motile", yes = "motile",
                        flagella = "motile", gliding = "motile", `axial filament` = "motile"))),
        bacdive = list(enrichment = "bacdive", col = "motility",
                     citation = "BacDive (DSMZ; Reimer et al. 2022)", note = "motile / non-motile.",
                     map = function(v) .xw_cat(v, c(motile = "motile", `non-motile` = "non-motile")))
      )
    ),
    sporulation = list(
      label = "Sporulation (prokaryote)", kind = "categorical", unit = NA_character_,
      vocab = c("yes", "no"),
      sources = list(
        madin = list(enrichment = "madin", col = "sporulation",
                     citation = "Madin et al. 2020 (prokaryote traits)", note = "Endospore formation: yes / no.",
                     map = function(v) .xw_cat(v, c(yes = "yes", no = "no")))
      )
    ),
    fungal_trophic_mode = list(
      label = "Fungal trophic mode", kind = "categorical", unit = NA_character_,
      vocab = c("pathotroph", "saprotroph", "symbiotroph", "mixed"),
      sources = list(
        funguild      = list(enrichment = "funguild", col = "trophic_mode",
                          citation = "FUNGuild (Nguyen et al. 2016)", note = "pathotroph / saprotroph / symbiotroph; hyphenated multi-mode entries -> mixed.",
                          map = fungtroph_funguild),
        fungal_traits = list(enrichment = "fungal_traits", col = "primary_lifestyle", join_col = "genus",
                          citation = "FungalTraits (Polme et al. 2020)", note = "Primary lifestyle mapped to trophic mode: *_saprotroph -> saprotroph, pathogen/parasite -> pathotroph, mycorrhizal/lichen/endophyte -> symbiotroph.",
                          map = function(v) .xw_grep(v, fungtroph_patterns))
      )
    ),
    larval_nutrition = list(
      label = "Larval nutrition (bee)", kind = "categorical", unit = NA_character_,
      vocab = c("pollen/nectar", "pollen/nectar/oil", "zoophagous",
                "phytophagous_(bulbs)", "phytophagous_(roots)", "saprophagous", "saproxylic"),
      sources = list(
        eupolltrait = list(enrichment = "eupolltrait", col = "larval_nutrition",
                          citation = "EuPollTrait (Milicic et al. 2025)", note = "Larval food source, verbatim.",
                          map = function(v) v)
      )
    ),

    ## ---- algae and marine-benthic functional traits -----------------------
    calcification = list(
      label = "Calcification (algae)", kind = "categorical", unit = NA_character_,
      vocab = c("non-calcified", "calcified-articulated", "calcified-non-articulated"),
      sources = list(
        algae_traits = list(enrichment = "algae_traits", col = "calcification",
                          citation = "AlgaeTraits", note = "Calcification state; 'unreported' -> NA.",
                          map = function(v) .xw_cat(v, calc_lookup))
      )
    ),
    gamete_type = list(
      label = "Gamete type (algae)", kind = "categorical", unit = NA_character_,
      vocab = c("oogamous", "isogamous", "anisogamous"),
      sources = list(
        algae_traits = list(enrichment = "algae_traits", col = "gamete_type",
                          citation = "AlgaeTraits", note = "oogamous / isogamous / anisogamous; unknown and 'not applicable' -> NA.",
                          map = function(v) .xw_cat(v, gamete_lookup))
      )
    ),
    algal_life_cycle = list(
      label = "Life-cycle ploidy phase (algae)", kind = "categorical", unit = NA_character_,
      vocab = c("haplodiplontic", "diplontic", "haplontic"),
      sources = list(
        algae_traits = list(enrichment = "algae_traits", col = "life_cycle",
                          citation = "AlgaeTraits", note = "Dominant ploidy phase; compound labels ('haplodiplontic > isomorphic') take the primary phase (haplodiplontic tested first, since it contains the other two as substrings).",
                          map = function(v) .xw_grep(v, algcyc_patterns))
      )
    ),
    algal_substrate = list(
      label = "Attachment substrate (algae)", kind = "categorical", unit = NA_character_,
      vocab = c("epilithic", "epiphytic", "endophytic", "endolithic",
                "endozoic", "epizoic", "unattached"),
      sources = list(
        algae_traits = list(enrichment = "algae_traits", col = "substrate",
                          citation = "AlgaeTraits", note = "Substrate the thallus attaches to, verbatim.",
                          map = function(v) .xw_cat(v, algsub_lookup))
      )
    ),
    bioturbation = list(
      label = "Bioturbation mode (benthic invertebrate)", kind = "categorical", unit = NA_character_,
      vocab = c("biodiffusor", "surface-modifier", "conveyor", "bioirrigator", "none"),
      sources = list(
        arctic_traits = list(enrichment = "arctic_traits", col = "bioturbation",
                          citation = "Arctic Traits (Degen & Faulwetter 2019)", note = "Sediment-reworking functional group; 'surface deposition' -> surface-modifier, 'diffusive mixing' -> biodiffusor.",
                          map = function(v) .xw_grep(v, bioturb_patterns)),
        nztd          = list(enrichment = "nztd", col = "bioturbation",
                          citation = "New Zealand Trait Database", note = "Solan/Queiros functional group, verbatim wording harmonized.",
                          map = function(v) .xw_grep(v, bioturb_patterns))
      )
    ),
    living_habit = list(
      label = "Living habit (benthic invertebrate)", kind = "categorical", unit = NA_character_,
      vocab = c("free-living", "burrowing", "tube-dwelling", "crevice-dwelling",
                "parasitic", "attached"),
      sources = list(
        arctic_traits = list(enrichment = "arctic_traits", col = "living_habit",
                          citation = "Arctic Traits (Degen & Faulwetter 2019)", note = "Life habit relative to the substrate.",
                          map = function(v) .xw_grep(v, livhabit_patterns)),
        nztd          = list(enrichment = "nztd", col = "living_habit",
                          citation = "New Zealand Trait Database", note = "Life habit relative to the substrate.",
                          map = function(v) .xw_grep(v, livhabit_patterns))
      )
    ),
    feeding_guild = list(
      label = "Feeding guild (benthic invertebrate)", kind = "categorical", unit = NA_character_,
      vocab = c("deposit-feeder", "suspension-feeder", "predator", "grazer", "scavenger"),
      sources = list(
        arctic_traits = list(enrichment = "arctic_traits", col = "feeding_habit",
                          citation = "Arctic Traits (Degen & Faulwetter 2019)", note = "Functional feeding guild; surface/subsurface deposit -> deposit-feeder.",
                          map = function(v) .xw_grep(v, feedguild_patterns)),
        nztd          = list(enrichment = "nztd", col = "feeding_mode",
                          citation = "New Zealand Trait Database", note = "Functional feeding guild.",
                          map = function(v) .xw_grep(v, feedguild_patterns))
      )
    ),
    skeletal_rigidity = list(
      label = "Skeletal rigidity (octocoral)", kind = "categorical", unit = NA_character_,
      vocab = c("soft", "semi-rigid", "rigid"),
      sources = list(
        octocoral = list(enrichment = "octocoral", col = "skeletal_rigidity",
                          citation = "Gomez-Gras et al. 2024", note = "soft / semi-rigid / rigid.",
                          map = function(v) .xw_cat(v, c(soft = "soft", `semi-rigid` = "semi-rigid", rigid = "rigid")))
      )
    ),
    colony_growth_form = list(
      label = "Colony growth form (octocoral)", kind = "categorical", unit = NA_character_,
      vocab = c("erect-branched", "erect-unbranched", "horizontal-branched",
                "horizontal-unbranched", "massive", "encrusting", "solitary"),
      sources = list(
        octocoral = list(enrichment = "octocoral", col = "type_of_growth",
                          citation = "Gomez-Gras et al. 2024", note = "Colony architecture.",
                          map = function(v) .xw_cat(v, ocgrow_lookup))
      )
    ),

    ## ---- additional numeric traits (units grounded on the .vtr values) -----
    depth_min = list(
      label = "Minimum depth", kind = "numeric", unit = "m", vocab = NULL,
      sources = list(
        fishbase    = nsrc("fishbase", "depth_min_m", "FishBase (Froese & Pauly)", "Metres."),
        sealifebase = nsrc("sealifebase", "depth_min_m", "SeaLifeBase (Palomares & Pauly)", "Metres."),
        quimbayo    = nsrc("quimbayo", "depth_min_m", "Quimbayo et al. 2021", "Metres."),
        pelagic     = nsrc("pelagic", "depth_min_m", "Gleiber et al. 2022", "Metres; -9999 sentinels mapped to NA.", map = num_pos),
        coral_traits = nsrc("coral_traits", "depth_upper_m", "Coral Trait DB (Madin et al. 2016)", "Shallowest occurrence depth (upper limit), metres."),
        octocoral    = nsrc("octocoral", "depth_upper", "Gomez-Gras et al. 2024", "Shallowest occurrence depth (upper limit), metres.")
      )
    ),
    depth_max = list(
      label = "Maximum depth", kind = "numeric", unit = "m", vocab = NULL,
      sources = list(
        fishbase    = nsrc("fishbase", "depth_max_m", "FishBase (Froese & Pauly)", "Metres."),
        sealifebase = nsrc("sealifebase", "depth_max_m", "SeaLifeBase (Palomares & Pauly)", "Metres."),
        quimbayo    = nsrc("quimbayo", "depth_max_m", "Quimbayo et al. 2021", "Metres."),
        pelagic     = nsrc("pelagic", "depth_max_m", "Gleiber et al. 2022", "Metres; -9999 sentinels mapped to NA.", map = num_pos),
        coral_traits = nsrc("coral_traits", "depth_lower_m", "Coral Trait DB (Madin et al. 2016)", "Deepest occurrence depth (lower limit), metres."),
        octocoral    = nsrc("octocoral", "depth_lower", "Gomez-Gras et al. 2024", "Deepest occurrence depth (lower limit), metres.")
      )
    ),
    elevation_min = list(
      label = "Minimum elevation", kind = "numeric", unit = "m", vocab = NULL,
      sources = list(
        birdbase   = nsrc("birdbase", "elevation_min_m", "Sekercioglu et al. 2025 (BIRDBASE)", "Metres."),
        repttraits = nsrc("repttraits", "elevation_min_m", "ReptTraits (Oskyrko et al. 2024)", "Metres."),
        globtherm  = nsrc("globtherm", "elevation_min", "GlobTherm (Bennett et al. 2018)", "Metres.")
        # FungalRoot's elevation_* is the elevation of a genus-grain mycorrhizal
        # sampling record, not a species elevational range limit (and its
        # elevation_max has 7 non-NA values, all degenerate at ~3300 m), so it is
        # a different quantity from the species-level ranges above and excluded.
      )
    ),
    elevation_max = list(
      label = "Maximum elevation", kind = "numeric", unit = "m", vocab = NULL,
      sources = list(
        birdbase   = nsrc("birdbase", "elevation_max_m", "Sekercioglu et al. 2025 (BIRDBASE)", "Metres."),
        repttraits = nsrc("repttraits", "elevation_max_m", "ReptTraits (Oskyrko et al. 2024)", "Metres."),
        globtherm  = nsrc("globtherm", "elevation_max", "GlobTherm (Bennett et al. 2018)", "Metres.")
        # FungalRoot elevation_max excluded (see elevation_min): sampling-record
        # elevation at genus grain, degenerate max column.
      )
    ),
    home_range = list(
      label = "Home range", kind = "numeric", unit = "km2", vocab = NULL,
      sources = list(
        combine   = nsrc("combine", "home_range_km2", "COMBINE (Soria et al. 2021)", "Square kilometres."),
        homerange = nsrc("homerange", "home_range_km2", "HomeRange (Broekman et al. 2023)", "Square kilometres."),
        pantheria = nsrc("pantheria", "home_range_km2", "PanTHERIA (Jones et al. 2009)", "Square kilometres.")
      )
    ),
    range_size = list(
      label = "Geographic range size", kind = "numeric", unit = "km2", vocab = NULL,
      sources = list(
        avonet       = nsrc("avonet", "range_size", "AVONET (Tobias et al. 2022)", "Square kilometres."),
        chelonians   = nsrc("chelonians", "range_size_km2", "TurtleTraits (Wang et al. 2025)", "Square kilometres."),
        coral_traits = nsrc("coral_traits", "range_size", "Coral Trait DB (Madin et al. 2016)", "Square kilometres.")
      )
    ),
    habitat_breadth = list(
      label = "Habitat breadth", kind = "numeric", unit = "count", vocab = NULL,
      sources = list(
        birdbase   = nsrc("birdbase", "habitat_breadth", "Sekercioglu et al. 2025 (BIRDBASE)", "Number of habitats used."),
        combine    = nsrc("combine", "habitat_breadth_n", "COMBINE (Soria et al. 2021)", "Number of habitats used."),
        frugivoria = nsrc("frugivoria", "habitat_breadth", "Frugivoria (Gerstner et al.)", "Number of habitats used."),
        pantheria  = nsrc("pantheria", "habitat_breadth", "PanTHERIA (Jones et al. 2009)", "Number of habitats used.")
      )
    ),
    generation_length = list(
      label = "Generation length", kind = "numeric", unit = "yr", vocab = NULL,
      sources = list(
        bet        = nsrc("bet", "generation_length_y", "BET (Van Zuijlen et al. 2023)", "Years."),
        frugivoria = nsrc("frugivoria", "generation_time", "Frugivoria (Gerstner et al.)", "Years."),
        combine    = nsrc("combine", "generation_length_d", "COMBINE (Soria et al. 2021)", "Days converted to years (/365.25; 2190 -> 6.0, matches BET 6.7).", map = d2y)
      )
    ),
    weaning_age = list(
      label = "Weaning age", kind = "numeric", unit = "days", vocab = NULL,
      sources = list(
        amniote   = nsrc("amniote", "weaning_d", "Amniote LHD (Myhrvold et al. 2015)", "Days."),
        anage     = nsrc("anage", "weaning_days", "AnAge (Tacutu et al. 2018)", "Days."),
        pantheria = nsrc("pantheria", "weaning_d", "PanTHERIA (Jones et al. 2009)", "Days.")
      )
    ),
    ldmc = list(
      label = "Leaf dry matter content", kind = "numeric", unit = "mg/g", vocab = NULL,
      sources = list(
        leda        = nsrc("leda", "ldmc_mg_g", "LEDA Traitbase (Kleyer et al. 2008)", "mg/g."),
        gift        = nsrc("gift", "gift_ldmc_mean", "GIFT (Weigelt et al. 2020)", "mg/g."),
        brot        = nsrc("brot", "ldmc", "BROT 2.0 (Tavsanoglu & Pausas 2018)", "mg/g."),
        diaz_traits = nsrc("diaz_traits", "ldmc_g_g", "Diaz et al. 2022", "g/g converted to mg/g (x1000; 0.195 -> 195, matches LEDA 194).", map = numk)
      )
    ),
    seed_length = list(
      label = "Seed length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        austraits = nsrc("austraits", "seed_length", "AusTraits (Falster et al. 2021)", "mm."),
        leda      = nsrc("leda", "seed_length_mm", "LEDA Traitbase (Kleyer et al. 2008)", "mm."),
        gift      = nsrc("gift", "gift_seed_length_mean", "GIFT (Weigelt et al. 2020)", "mm."),
        bien      = nsrc("bien", "seed_length", "BIEN (Maitner et al. 2018)", "mm.")
      )
    ),
    vulnerability = list(
      label = "Vulnerability to fishing", kind = "numeric", unit = "0-100 index", vocab = NULL,
      sources = list(
        fishbase    = nsrc("fishbase", "vulnerability", "FishBase (Froese & Pauly)", "FishBase vulnerability index, 0-100."),
        sealifebase = nsrc("sealifebase", "vulnerability", "SeaLifeBase (Palomares & Pauly)", "Vulnerability index, 0-100."),
        quimbayo    = nsrc("quimbayo", "vulnerability", "Quimbayo et al. 2021", "Vulnerability index, 0-100.")
      )
    ),
    itd = list(
      label = "Inter-tegular distance (bee body size)", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        bee_ostwald = nsrc("bee_ostwald", "itd_mm", "Ostwald 2024", "Inter-tegular distance, mm."),
        eupolltrait = nsrc("eupolltrait", "itd_mm", "EuPollTrait (Milicic et al. 2025)", "Inter-tegular distance, mm.")
      )
    ),
    tongue_length = list(
      label = "Tongue length (bee)", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        bee_ostwald = nsrc("bee_ostwald", "tongue_length_mm", "Ostwald 2024", "Bee tongue (proboscis) length, mm."),
        eupolltrait = nsrc("eupolltrait", "tongue_length_mm", "EuPollTrait (Milicic et al. 2025)", "Tongue length, mm (ratio 1.00 vs Ostwald on 162 shared species).")
      )
    ),
    diet_breadth = list(
      label = "Diet breadth", kind = "numeric", unit = "count", vocab = NULL,
      sources = list(
        combine    = nsrc("combine", "diet_breadth_n", "COMBINE (Soria et al. 2021)", "Number of dietary categories used (ratio 1.00 vs PanTHERIA on 2162 shared species)."),
        pantheria  = nsrc("pantheria", "diet_breadth", "PanTHERIA (Jones et al. 2009)", "Number of dietary categories used."),
        birdbase   = nsrc("birdbase", "diet_breadth", "Sekercioglu et al. 2025 (BIRDBASE)", "Number of dietary categories used; birds, disjoint from the mammal sources, same 0-7 integer-count scale.")
      )
    ),
    aspect_ratio = list(
      label = "Caudal fin aspect ratio", kind = "numeric", unit = "index", vocab = NULL,
      sources = list(
        beukhof  = nsrc("beukhof", "aspect_ratio", "Beukhof et al. 2019", "Caudal-fin aspect ratio (height^2 / area), unitless."),
        quimbayo = nsrc("quimbayo", "aspect_ratio", "Quimbayo et al. 2021", "Caudal-fin aspect ratio, unitless (ratio 1.00 vs Beukhof on 406 shared species).")
      )
    ),
    body_elongation = list(
      label = "Body elongation (fish)", kind = "numeric", unit = "index", vocab = NULL,
      sources = list(
        fishmorph = nsrc("fishmorph", "body_elongation", "FISHMORPH (Brosse et al. 2021)", "Body length / maximum body depth; dimensionless, median 4.0 (range 1.0-44), distribution-sanity grounded.")
      )
    ),
    vertical_eye_position = list(
      label = "Vertical eye position (fish)", kind = "numeric", unit = "index", vocab = NULL,
      sources = list(
        fishmorph = nsrc("fishmorph", "vertical_eye_position", "FISHMORPH (Brosse et al. 2021)", "Eye midline height / head depth; 0-1 index, median 0.55.")
      )
    ),
    relative_eye_size = list(
      label = "Relative eye size (fish)", kind = "numeric", unit = "index", vocab = NULL,
      sources = list(
        fishmorph = nsrc("fishmorph", "relative_eye_size", "FISHMORPH (Brosse et al. 2021)", "Eye diameter / head length; 0-1 index, median 0.39.")
      )
    ),
    oral_gape_position = list(
      label = "Oral gape position (fish)", kind = "numeric", unit = "index", vocab = NULL,
      sources = list(
        fishmorph = nsrc("fishmorph", "oral_gape_position", "FISHMORPH (Brosse et al. 2021)", "Mouth position, 0 = inferior, 0.5 = terminal, 1 = superior; 0-1 index, median 0.41. Kept as its own continuous index rather than binned into the categorical mouth_position: the two share only 40 species and the index does not separate quimbayo's classes (terminal spans 0.12-0.69, overlapping superior 0.30-0.80).")
      )
    ),
    relative_maxillary_length = list(
      label = "Relative maxillary length (fish)", kind = "numeric", unit = "index", vocab = NULL,
      sources = list(
        fishmorph = nsrc("fishmorph", "relative_maxillary_length", "FISHMORPH (Brosse et al. 2021)", "Maxillary length / head length; index, median 0.37.")
      )
    ),
    body_lateral_shape = list(
      label = "Body lateral shape (fish)", kind = "numeric", unit = "index", vocab = NULL,
      sources = list(
        fishmorph = nsrc("fishmorph", "body_lateral_shape", "FISHMORPH (Brosse et al. 2021)", "Body depth / caudal peduncle depth; index, median 0.57.")
      )
    ),
    pectoral_fin_position = list(
      label = "Pectoral fin position (fish)", kind = "numeric", unit = "index", vocab = NULL,
      sources = list(
        fishmorph = nsrc("fishmorph", "pectoral_fin_position", "FISHMORPH (Brosse et al. 2021)", "Pectoral fin insertion height / body depth; 0-1 index, median 0.27.")
      )
    ),
    pectoral_fin_size = list(
      label = "Pectoral fin size (fish)", kind = "numeric", unit = "index", vocab = NULL,
      sources = list(
        fishmorph = nsrc("fishmorph", "pectoral_fin_size", "FISHMORPH (Brosse et al. 2021)", "Pectoral fin length / body length; index, median 0.18.")
      )
    ),
    caudal_peduncle_throttling = list(
      label = "Caudal peduncle throttling (fish)", kind = "numeric", unit = "index", vocab = NULL,
      sources = list(
        fishmorph = nsrc("fishmorph", "caudal_peduncle_throttling", "FISHMORPH (Brosse et al. 2021)", "Caudal peduncle depth / caudal fin depth; index, median 2.4.")
      )
    ),
    head_length = list(
      label = "Head length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        huang_amph = nsrc("huang_amph", "head_length_mm", "Huang et al. amphibian morphology", "Head length, mm."),
        saproxylic = nsrc("saproxylic", "head_length_mm", "Saproxylic beetle traits", "Head length, mm (disjoint taxa from huang_amph; unit mm verbatim, as with body_length).")
      )
    ),
    head_width = list(
      label = "Head width", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        huang_amph = nsrc("huang_amph", "head_width_mm", "Huang et al. amphibian morphology", "Head width, mm."),
        saproxylic = nsrc("saproxylic", "head_width", "Saproxylic beetle traits", "Head width, mm (disjoint taxa from huang_amph; unit mm verbatim).")
      )
    ),
    forelimb_length = list(
      label = "Forelimb length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        huang_amph = nsrc("huang_amph", "forelimb_length_mm", "Huang et al. amphibian morphology", "Amphibian forelimb length, mm; a few near-zero negative records dropped.", map = num_pos)
      )
    ),
    hindlimb_length = list(
      label = "Hindlimb length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        huang_amph = nsrc("huang_amph", "hindlimb_length_mm", "Huang et al. amphibian morphology", "Amphibian hindlimb length, mm.", map = num_pos)
      )
    ),
    forearm_length = list(
      label = "Forearm length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        combine   = nsrc("combine", "adult_forearm_length_mm", "COMBINE (Soria et al. 2021)", "Adult forearm length, mm (the standard bat body measurement)."),
        pantheria = nsrc("pantheria", "x8_1_adultforearmlen_mm", "PanTHERIA (Jones et al. 2009)", "Adult forearm length, mm (ratio 1.00 vs combine on 972 shared species)."),
        eurobat   = nsrc("eurobat", "forearm_length_mm", "EuroBaT (European bat traits)", "Forearm length, mm (ratio 1.01 vs combine and 1.00 vs pantheria on shared species).")
      )
    ),
    elytra_length = list(
      label = "Elytra length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        saproxylic = nsrc("saproxylic", "elytra_length_mm", "Saproxylic beetle traits", "Beetle elytra length, mm.")
      )
    ),
    antenna_length = list(
      label = "Antenna length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        saproxylic = nsrc("saproxylic", "antenna_length_mm", "Saproxylic beetle traits", "Beetle antenna length, mm.")
      )
    ),
    pronotum_length = list(
      label = "Pronotum length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        saproxylic = nsrc("saproxylic", "pronotum_length_mm", "Saproxylic beetle traits", "Beetle pronotum length, mm.")
      )
    ),
    cell_length = list(
      label = "Cell length", kind = "numeric", unit = "um", vocab = NULL,
      sources = list(
        rimet_phyto = nsrc("rimet_phyto", "cell_length_um", "Rimet et al. phytoplankton morphology", "Micrometres (microalgae)."),
        bacdive     = nsrc("bacdive", "cell_length_um", "BacDive (DSMZ; Reimer et al. 2022)", "Micrometres (prokaryote strains; disjoint taxa from rimet_phyto).")
      )
    ),
    cell_width = list(
      label = "Cell width", kind = "numeric", unit = "um", vocab = NULL,
      sources = list(
        rimet_phyto = nsrc("rimet_phyto", "cell_width_um", "Rimet et al. phytoplankton morphology", "Micrometres (microalgae)."),
        bacdive     = nsrc("bacdive", "cell_width_um", "BacDive (DSMZ; Reimer et al. 2022)", "Micrometres (prokaryote strains; disjoint taxa from rimet_phyto).")
      )
    ),
    cell_biovolume = list(
      label = "Cell biovolume (microalgae)", kind = "numeric", unit = "um3", vocab = NULL,
      sources = list(
        rimet_phyto = nsrc("rimet_phyto", "cell_biovolume_um3", "Rimet et al. phytoplankton morphology", "Cubic micrometres.")
      )
    ),
    cell_thickness = list(
      label = "Cell thickness (microalgae)", kind = "numeric", unit = "um", vocab = NULL,
      sources = list(
        rimet_phyto = nsrc("rimet_phyto", "cell_thickness_um", "Rimet et al. phytoplankton morphology", "Micrometres.")
      )
    ),
    cell_surface_area = list(
      label = "Cell surface area (microalgae)", kind = "numeric", unit = "um2", vocab = NULL,
      sources = list(
        rimet_phyto = nsrc("rimet_phyto", "cell_surface_area_um2", "Rimet et al. phytoplankton morphology", "Square micrometres.")
      )
    ),
    colony_diameter = list(
      label = "Colony maximum diameter (coral)", kind = "numeric", unit = "cm", vocab = NULL,
      sources = list(
        coral_traits = nsrc("coral_traits", "colony_max_diameter_cm", "Coral Trait Database (Madin et al. 2016)", "Maximum colony diameter, cm.")
      )
    ),
    corallite_width = list(
      label = "Corallite width (coral)", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        coral_traits = nsrc("coral_traits", "corallite_width_max_mm", "Coral Trait Database (Madin et al. 2016)", "Maximum corallite width, mm.")
      )
    ),
    carapace_length = list(
      label = "Carapace length (turtle)", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        chelonians = nsrc("chelonians", "carapace_length_mm", "TurtleTraits (Chelonians)", "Straight carapace length, mm.")
      )
    ),
    colour_lightness = list(
      label = "Body colour lightness (beetle)", kind = "numeric", unit = "index", vocab = NULL,
      sources = list(
        saproxylic = nsrc("saproxylic", "colour_lightness", "Saproxylic beetle traits (Hagge et al. 2021)", "Mean grey value of the body, 0 (black) to 255 (white).")
      )
    ),
    voltinism = list(
      label = "Voltinism (generations per year)", kind = "numeric", unit = "per year", vocab = NULL,
      sources = list(
        arthropod_traits = nsrc("arthropod_traits", "voltinism", "Arthropod Traits (Gossner et al. 2015)", "Generations per year."),
        eupolltrait      = nsrc("eupolltrait", "number_of_generations", "EuPollTrait (Milicic et al. 2025)", "Number of generations per year.")
      )
    ),
    optimal_growth_temperature = list(
      label = "Optimal growth temperature (prokaryote)", kind = "numeric", unit = "deg C", vocab = NULL,
      sources = list(
        madin   = nsrc("madin", "growth_temp_c", "Madin et al. 2020 (prokaryote traits)", "Optimal growth temperature, degrees C."),
        bacdive = nsrc("bacdive", "optimal_growth_temp_c", "BacDive (DSMZ; Reimer et al. 2022)", "Optimal growth temperature, degrees C (ratio 1.00 vs madin on 11,117 shared species).")
      )
    ),
    genome_size = list(
      label = "Genome size (prokaryote)", kind = "numeric", unit = "bp", vocab = NULL,
      sources = list(
        madin = nsrc("madin", "genome_size_bp", "Madin et al. 2020 (prokaryote traits)", "Genome size, base pairs.")
      )
    ),
    chromosome_number = list(
      label = "Chromosome number (2n)", kind = "numeric", unit = "count", vocab = NULL,
      sources = list(
        kew_cvalues = nsrc("kew_cvalues", "chromosome_2n", "Kew Plant DNA C-values 7.1 (Pellicer & Leitch 2020)", "Somatic chromosome number (2n) of vascular plants, verified against textbook counts (Zea mays 20, Oryza sativa 24, Pisum sativum 14, Triticum aestivum 42).")
      )
    ),
    optimal_growth_ph = list(
      label = "Optimal growth pH (prokaryote)", kind = "numeric", unit = "pH", vocab = NULL,
      sources = list(
        madin   = nsrc("madin", "optimum_ph", "Madin et al. 2020 (prokaryote traits)", "Optimal growth pH."),
        bacdive = nsrc("bacdive", "optimal_growth_ph", "BacDive (DSMZ; Reimer et al. 2022)", "Optimal growth pH (ratio 1.00 vs madin on 3,371 shared species).")
      )
    ),
    gc_content = list(
      label = "Genome GC content (prokaryote)", kind = "numeric", unit = "%", vocab = NULL,
      sources = list(
        madin = nsrc("madin", "gc_content_pct", "Madin et al. 2020 (prokaryote traits)", "Guanine-cytosine content of the genome, percent.")
      )
    ),

    ## ---- additional categorical traits ------------------------------------
    conservation_status = list(
      label = "IUCN Red List status", kind = "categorical", unit = NA_character_,
      vocab = c("LC", "NT", "VU", "EN", "CR", "EW", "EX", "DD"),
      sources = list(
        conservation_status = list(enrichment = "iucn", col = "conservation_status",
                          citation = "IUCN Red List", note = "IUCN category.",
                          map = function(v) .xw_cat(v, iucn_lookup)),
        birdbase  = list(enrichment = "birdbase", col = "iucn_status",
                          citation = "Sekercioglu et al. 2025 (BIRDBASE)", note = "IUCN category.",
                          map = function(v) .xw_cat(v, iucn_lookup)),
        phylacine = list(enrichment = "phylacine", col = "iucn_status",
                          citation = "PHYLACINE (Faurby et al. 2018)", note = "IUCN category; EP / -9999 -> NA.",
                          map = function(v) .xw_cat(v, iucn_lookup)),
        quimbayo  = list(enrichment = "quimbayo", col = "iucn_status",
                          citation = "Quimbayo et al. 2021", note = "IUCN category.",
                          map = function(v) .xw_cat(v, iucn_lookup)),
        pelagic   = list(enrichment = "pelagic", col = "iucn_status",
                          citation = "Gleiber et al. 2022", note = "IUCN category; NE / -9999 -> NA.",
                          map = function(v) .xw_cat(v, iucn_lookup)),
        pottier   = list(enrichment = "pottier", col = "iucn_status",
                          citation = "Pottier et al. 2022", note = "IUCN category.",
                          map = function(v) .xw_cat(v, iucn_lookup))
      )
    ),
    body_shape = list(
      label = "Body shape (fish)", kind = "categorical", unit = NA_character_,
      vocab = c("fusiform", "elongated", "compressed", "depressed", "globiform"),
      sources = list(
        beukhof  = list(enrichment = "beukhof", col = "body_shape",
                        citation = "Beukhof et al. 2019", note = "Fish body shape.",
                        map = function(v) .xw_grep(v, bodyshape_patterns)),
        quimbayo = list(enrichment = "quimbayo", col = "body_shape",
                        citation = "Quimbayo et al. 2021", note = "Fish body shape.",
                        map = function(v) .xw_grep(v, bodyshape_patterns)),
        pelagic  = list(enrichment = "pelagic", col = "body_shape",
                        citation = "Gleiber et al. 2022", note = "Fish body shape; -9999 -> NA.",
                        map = function(v) .xw_grep(v, bodyshape_patterns))
      )
    ),
    caudal_fin_shape = list(
      label = "Caudal fin shape (fish)", kind = "categorical", unit = NA_character_,
      vocab = c("rounded", "truncate", "forked", "pointed", "lanceolate", "lunate", "heterocercal"),
      sources = list(
        beukhof  = list(enrichment = "beukhof", col = "fin_shape",
                        citation = "Beukhof et al. 2019", note = "Caudal fin shape.",
                        map = function(v) .xw_grep(v, fin_patterns)),
        quimbayo = list(enrichment = "quimbayo", col = "caudal_fin",
                        citation = "Quimbayo et al. 2021", note = "Caudal fin shape ('truncated'/'lanceolated' folded in).",
                        map = function(v) .xw_grep(v, fin_patterns))
      )
    ),
    feeding_mode = list(
      label = "Feeding mode (fish)", kind = "categorical", unit = NA_character_,
      vocab = c("generalist", "benthivorous", "planktivorous", "piscivorous", "herbivorous"),
      sources = list(
        beukhof = list(enrichment = "beukhof", col = "feeding_mode",
                       citation = "Beukhof et al. 2019", note = "Fish feeding mode.",
                       map = function(v) .xw_cat(v, c(generalist = "generalist",
                          benthivorous = "benthivorous", planktivorous = "planktivorous",
                          piscivorous = "piscivorous", herbivorous = "herbivorous")))
      )
    ),
    mouth_position = list(
      label = "Mouth position (fish)", kind = "categorical", unit = NA_character_,
      vocab = c("terminal", "subterminal", "superior", "inferior", "tubular", "elongated"),
      sources = list(
        quimbayo = list(enrichment = "quimbayo", col = "mouth_position",
                        citation = "Quimbayo et al. 2021", note = "Fish mouth position.",
                        map = function(v) .xw_cat(v, c(terminal = "terminal",
                           subterminal = "subterminal", superior = "superior",
                           inferior = "inferior", tubular = "tubular", elongated = "elongated")))
      )
    ),
    air_breathing = list(
      label = "Air breathing (fish)", kind = "categorical", unit = NA_character_,
      vocab = c("none", "facultative", "obligate"),
      sources = list(
        fishbase = list(enrichment = "fishbase", col = "airbreathing",
                        citation = "FishBase (Froese & Pauly)", note = "Water/WaterAssumed -> none; facultative and obligate (incl. genus-inferred) kept.",
                        map = function(v) .xw_grep(v, airbreath_patterns))
      )
    ),
    parental_care = list(
      label = "Parental care (fish)", kind = "categorical", unit = NA_character_,
      vocab = c("guarder", "non-guarder", "bearer"),
      sources = list(
        beukhof = list(enrichment = "beukhof", col = "spawning_type",
                       citation = "Beukhof et al. 2019", note = "Balon reproductive guild: guarder / non-guarder / bearer.",
                       map = function(v) .xw_cat(v, c(guarder = "guarder",
                          `non-guarder` = "non-guarder", bearer = "bearer")))
      )
    ),
    sexual_system = list(
      label = "Sexual system", kind = "categorical", unit = NA_character_,
      vocab = c("hermaphrodite", "gonochoric", "dioecious", "monoecious", "parthenogenetic"),
      sources = list(
        tree_of_sex  = list(enrichment = "tree_of_sex", col = "sexual_system",
                        citation = "Tree of Sex Consortium 2014", note = "Plant and animal sexual systems.",
                        map = function(v) .xw_grep(v, sexsys_patterns)),
        austraits    = list(enrichment = "austraits", col = "sex_type",
                        citation = "AusTraits (Falster et al. 2021)",
                        note = paste("Plant sexual system through the shared crosswalk. Agrees with",
                                     "tree_of_sex on 87% of 572 shared species (hermaphrodite 250,",
                                     "dioecious 141, monoecious 105), and roughly doubles the trait's",
                                     "plant coverage."),
                        map = function(v) .xw_grep(v, sexsys_patterns)),
        bet          = list(enrichment = "bet", col = "sexual_condition",
                        citation = "Bryophytes of Europe Traits (Hodgetts et al. 2020)",
                        note = paste("Bryophyte sexual condition, D and M read as dioicous and",
                                     "monoicous, the standard coding for the group; M/D records carry",
                                     "both and fall through to NA. Read off the column's three distinct",
                                     "values, not confirmed against a BET data dictionary."),
                        map = function(v) .xw_cat(v, c("d" = "dioecious", "m" = "monoecious"))),
        coral_traits = list(enrichment = "coral_traits", col = "sexual_system",
                        citation = "Coral Trait DB (Madin et al. 2016)", note = "Coral sexual system.",
                        map = function(v) .xw_grep(v, sexsys_patterns)),
        octocoral    = list(enrichment = "octocoral", col = "sexual_system",
                        citation = "Gomez-Gras et al. 2024", note = "Octocoral sexual system.",
                        map = function(v) .xw_grep(v, sexsys_patterns)),
        sheld        = list(enrichment = "sheld", col = "hermaphrodite",
                        citation = "Freshwater Mussel Traits (Hopper et al. 2023)", note = "Freshwater mussels; true -> hermaphrodite, false -> gonochoric.",
                        map = function(v) .xw_cat(v, mussel_sexsys))
      )
    ),
    reproductive_mode = list(
      label = "Reproductive (parity) mode", kind = "categorical", unit = NA_character_,
      vocab = c("oviparous", "ovoviviparous", "viviparous"),
      sources = list(
        repttraits  = list(enrichment = "repttraits", col = "reproductive_mode",
                        citation = "ReptTraits (Oskyrko et al. 2024)", note = "oviparous / ovoviviparous / viviparous.",
                        map = function(v) .xw_grep(v, parity_patterns)),
        sharkipedia = list(enrichment = "sharkipedia", col = "reproductive_mode",
                        citation = "Sharkipedia (sharkipedia.org)", note = "Shark strategies (matrotrophy, placentotrophy, aplacental/histotrophic/lecithotrophic viviparity) collapse to viviparous; oviparous kept.",
                        map = function(v) .xw_grep(v, parity_patterns))
      )
    ),

    ## ---- lichen descriptors (ITALIC) --------------------------------------
    lichen_growth_form = list(
      label = "Lichen growth form (thallus)", kind = "categorical", unit = NA_character_,
      vocab = c("crustose", "foliose", "fruticose", "squamulose", "leprose"),
      sources = list(
        italic = list(enrichment = "italic", col = "growth_form",
                      citation = "ITALIC 8.0 (Nimis; Italian lichens)", note = "Thallus growth form; lichenicolous and non-lichenised entries are lifestyle categories, not thallus forms, and map to NA.",
                      map = function(v) .xw_grep(v, lichen_gf_patterns))
      )
    ),
    substrate = list(
      label = "Substrate", kind = "categorical", unit = NA_character_,
      vocab = c("rock", "bark", "wood", "soil", "leaves"),
      sources = list(
        italic = list(enrichment = "italic", col = "substrata",
                      citation = "ITALIC 8.0 (Nimis; Italian lichens)", note = "Primary substrate of a possibly multi-substrate record (priority rock > bark > wood > soil > leaves).",
                      map = function(v) .xw_grep(v, lichen_substrate_patterns))
      )
    ),
    photobiont = list(
      label = "Lichen photobiont", kind = "categorical", unit = NA_character_,
      vocab = c("green algae", "Trentepohlia", "cyanobacteria"),
      sources = list(
        italic = list(enrichment = "italic", col = "photobiont",
                      citation = "ITALIC 8.0 (Nimis; Italian lichens)", note = "Photosynthetic partner; 'green algae other than Trentepohlia' maps to green algae (the substring Trentepohlia is not matched first).",
                      map = function(v) .xw_grep(v, photobiont_patterns))
      )
    ),
    reproductive_strategy = list(
      label = "Reproductive strategy (sexual / asexual)", kind = "categorical", unit = NA_character_,
      vocab = c("sexual", "asexual"),
      sources = list(
        italic = list(enrichment = "italic", col = "reproductive_strategy",
                      citation = "ITALIC 8.0 (Nimis; Italian lichens)", note = "Primary strategy; 'mainly sexual, or asexual ...' keeps sexual, 'mainly asexual, by soredia/isidia/fragmentation' maps to asexual.",
                      map = function(v) .xw_grep(v, lichen_repro_patterns))
      )
    ),
    leaf_type = list(
      label = "Leaf type", kind = "categorical", unit = NA_character_,
      vocab = c("broadleaf", "needle", "scale", "leafless"),
      sources = list(
        austraits   = list(enrichment = "austraits", col = "leaf_type",
                           citation = "AusTraits (Falster et al. 2021)", note = "broadleaf / needle / scale / leafless.",
                           map = function(v) .xw_grep(v, leaftype_patterns)),
        diaz_traits = list(enrichment = "diaz_traits", col = "leaf_type",
                           citation = "Diaz et al. 2022", note = "broadleaved / needleleaved / scale / photosynthetic stem (-> leafless).",
                           map = function(v) .xw_grep(v, leaftype_patterns))
      )
    ),
    deciduousness = list(
      label = "Leaf deciduousness", kind = "categorical", unit = NA_character_,
      vocab = c("evergreen", "deciduous", "semi-deciduous", "variable"),
      sources = list(
        gift      = list(enrichment = "gift", col = "gift_deciduousness_1",
                         citation = "GIFT (Weigelt et al. 2020)", note = "evergreen / deciduous / variable.",
                         map = function(v) .xw_grep(v, decid_patterns)),
        austraits = list(enrichment = "austraits", col = "leaf_phenology",
                         citation = "AusTraits (Falster et al. 2021)", note = "Leaf phenology; drought/semi-deciduous variants folded in.",
                         map = function(v) .xw_grep(v, decid_patterns))
      )
    ),
    marine = list(
      label = "Marine habitat", kind = "categorical", unit = NA_character_,
      vocab = c("yes", "no"),
      sources = list(
        sealifebase = list(enrichment = "sealifebase", col = "marine",
                           citation = "SeaLifeBase (Palomares & Pauly)", note = "Marine flag.",
                           map = function(v) .xw_cat(v, binary_yn)),
        combine     = list(enrichment = "combine", col = "marine",
                           citation = "COMBINE (Soria et al. 2021)", note = "Marine flag.",
                           map = function(v) .xw_cat(v, binary_yn)),
        phylacine   = list(enrichment = "phylacine", col = "marine",
                           citation = "PHYLACINE (Faurby et al. 2018)", note = "Marine flag.",
                           map = function(v) .xw_cat(v, binary_yn))
      )
    ),
    freshwater = list(
      label = "Freshwater habitat", kind = "categorical", unit = NA_character_,
      vocab = c("yes", "no"),
      sources = list(
        sealifebase = list(enrichment = "sealifebase", col = "freshwater",
                           citation = "SeaLifeBase (Palomares & Pauly)", note = "Freshwater flag.",
                           map = function(v) .xw_cat(v, binary_yn)),
        combine     = list(enrichment = "combine", col = "freshwater",
                           citation = "COMBINE (Soria et al. 2021)", note = "Freshwater flag.",
                           map = function(v) .xw_cat(v, binary_yn)),
        phylacine   = list(enrichment = "phylacine", col = "freshwater",
                           citation = "PHYLACINE (Faurby et al. 2018)", note = "Freshwater flag.",
                           map = function(v) .xw_cat(v, binary_yn))
      )
    ),
    coloniality = list(
      label = "Coloniality", kind = "categorical", unit = NA_character_,
      vocab = c("colonial", "solitary", "both"),
      sources = list(
        coral_traits = list(enrichment = "coral_traits", col = "coloniality",
                           citation = "Coral Trait DB (Madin et al. 2016)", note = "colonial / solitary / both.",
                           map = function(v) .xw_cat(v, coloniality_lookup)),
        octocoral    = list(enrichment = "octocoral", col = "coloniality",
                           citation = "Gomez-Gras et al. 2024", note = "colonial / solitary.",
                           map = function(v) .xw_cat(v, coloniality_lookup))
      )
    ),
    wave_exposure = list(
      label = "Wave exposure preference", kind = "categorical", unit = NA_character_,
      vocab = c("protected", "exposed", "intermediate"),
      sources = list(
        coral_traits = list(enrichment = "coral_traits", col = "wave_exposure_preference",
                           citation = "Coral Trait DB (Madin et al. 2016)", note = "protected / exposed; 'broad' -> intermediate.",
                           map = function(v) .xw_cat(v, wave_lookup)),
        octocoral    = list(enrichment = "octocoral", col = "wave_exposure_preference",
                           citation = "Gomez-Gras et al. 2024", note = "protected / exposed; 'both' -> intermediate.",
                           map = function(v) .xw_cat(v, wave_lookup))
      )
    ),
    water_clarity = list(
      label = "Water clarity preference", kind = "categorical", unit = NA_character_,
      vocab = c("clear", "turbid", "both"),
      sources = list(
        coral_traits = list(enrichment = "coral_traits", col = "water_clarity_preference",
                           citation = "Coral Trait DB (Madin et al. 2016)", note = "clear / turbid / both.",
                           map = function(v) .xw_cat(v, clarity_lookup)),
        octocoral    = list(enrichment = "octocoral", col = "water_clarity_preference",
                           citation = "Gomez-Gras et al. 2024", note = "clear / turbid / both.",
                           map = function(v) .xw_cat(v, clarity_lookup))
      )
    ),
    zooxanthellate = list(
      label = "Zooxanthellate symbiosis (coral)", kind = "categorical", unit = NA_character_,
      vocab = c("zooxanthellate", "azooxanthellate", "both"),
      sources = list(
        coral_traits = list(enrichment = "coral_traits", col = "symbiotic_state",
                           citation = "Coral Trait DB (Madin et al. 2016)", note = "zooxanthellate / azooxanthellate / both.",
                           map = function(v) .xw_cat(v, zoox_lookup)),
        octocoral    = list(enrichment = "octocoral", col = "zooxanthellate",
                           citation = "Gomez-Gras et al. 2024", note = "zooxanthellate / azooxanthellate.",
                           map = function(v) .xw_cat(v, zoox_lookup))
      )
    ),
    wing_length = list(
      label = "Wing length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        avonet     = nsrc("avonet", "wing_length", "AVONET (Tobias et al. 2022)", "Bird wing length, mm."),
        saproxylic = nsrc("saproxylic", "wing_length_mm", "Saproxylic beetle traits", "Beetle wing length, mm.")
      )
    ),
    wingspan = list(
      label = "Wingspan (butterfly)", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        leptraits = nsrc("leptraits", "wingspan_mm", "LepTraits (Shirey et al. 2022)", "Butterfly wingspan. The source column is labelled _mm but its values are cm (monarch 9.4, cabbage white 4.5, verified against known wingspans), so multiplied by 10 to mm.", map = cm2mm)
      )
    ),
    beak_length = list(
      label = "Beak length (culmen)", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        avonet = nsrc("avonet", "beak_length", "AVONET (Tobias et al. 2022)", "Culmen length, mm.")
      )
    ),
    hand_wing_index = list(
      label = "Hand-wing index", kind = "numeric", unit = "index", vocab = NULL,
      sources = list(
        avonet = nsrc("avonet", "hand_wing_index", "AVONET (Tobias et al. 2022)", "Hand-wing index, a dispersal-ability proxy (unitless).")
      )
    ),
    von_bertalanffy_k = list(
      label = "Von Bertalanffy growth coefficient (K)", kind = "numeric", unit = "per yr", vocab = NULL,
      sources = list(
        beukhof     = nsrc("beukhof", "growth_coefficient", "Beukhof et al. 2019", "VBGF growth coefficient K, per year."),
        sharkipedia = nsrc("sharkipedia", "vbgf_k", "Sharkipedia (sharkipedia.org)", "VBGF growth coefficient K, per year.")
      )
    ),
    von_bertalanffy_linf = list(
      label = "Von Bertalanffy asymptotic length (Linf)", kind = "numeric", unit = "cm", vocab = NULL,
      sources = list(
        beukhof     = nsrc("beukhof", "length_infinity_cm", "Beukhof et al. 2019", "VBGF asymptotic length Linf, cm."),
        sharkipedia = nsrc("sharkipedia", "vbgf_linf_cm", "Sharkipedia (sharkipedia.org)", "VBGF asymptotic length Linf, cm (ratio 1.13 vs beukhof on 19 shared species; both cm, thin overlap because sharks skew large).")
      )
    ),
    thermal_max = list(
      label = "Upper thermal limit", kind = "numeric", unit = "deg C", vocab = NULL,
      sources = list(
        globtherm   = nsrc("globtherm", "thermal_max_c", "GlobTherm (Bennett et al. 2018)", "Upper thermal tolerance (CTmax / UTNZ / lethal temperature), degrees C."),
        pottier     = nsrc("pottier", "heat_tolerance_c", "Pottier et al. 2022", "Amphibian upper thermal tolerance (CTmax / LT50), degrees C."),
        thermofresh = nsrc("thermofresh", "ctmax", "Freshwater thermal-tolerance database (Bayat et al., Zenodo 14056760)", "Critical thermal maximum (CTmax) of freshwater fish, invertebrates and amphibians, degrees C (ratio 1.00 vs globtherm on 135 shared species). The source's lethal limits (lt50 / ltmax) are separate columns and are left out, so one record type feeds this trait.")
      )
    ),
    thermal_min = list(
      label = "Lower thermal limit", kind = "numeric", unit = "deg C", vocab = NULL,
      sources = list(
        globtherm   = nsrc("globtherm", "thermal_min_c", "GlobTherm (Bennett et al. 2018)", "Lower thermal tolerance, degrees C."),
        thermofresh = nsrc("thermofresh", "ctmin", "Freshwater thermal-tolerance database (Bayat et al., Zenodo 14056760)", "Critical thermal minimum (CTmin) of freshwater fish, invertebrates and amphibians, degrees C (ratio 1.00 vs globtherm on 16 shared species).")
      )
    ),

    ## ---- Climatic niche: the climate where a species lives, not what it can
    ## tolerate physiologically. Kept strictly apart from thermal_max/thermal_min
    ## (organismal CTmax/CTmin): a species' range climate is bounded by dispersal,
    ## competition and history, so it sits well inside its tolerance.
    climatic_temp_mean = list(
      label = "Mean annual temperature of range", kind = "numeric", unit = "deg C", vocab = NULL,
      sources = list(
        arthropod_traits = nsrc("arthropod_traits", "thermal_mean", "Logghe et al. 2025 (NW European arthropod traits)", "Mean annual temperature (WorldClim BIO1) averaged over 0.2-degree buffers around the species' occurrences, degrees C. The source calls this a realised thermal niche and warns it is not a thermal limit."),
        repttraits       = nsrc("repttraits", "mean_annual_temp_c", "ReptTraits (Oskyrko et al. 2024)", "Mean annual temperature over the species' range, degrees C, from CHELSA (Karger et al. 2017) on the GARD ranges (Roll et al. 2017) per the source's own trait-source sheet.")
      )
    ),
    climatic_temp_min = list(
      label = "Coldest-month temperature of range", kind = "numeric", unit = "deg C", vocab = NULL,
      sources = list(
        fishtraits = nsrc("fishtraits", "min_temp_c", "FishTraits (Frimpong & Angermeier 2009)", "30-year average minimum January temperature at the range centroid, degrees C, read from PRISM 400-m grids per the source's FGDC field definition. A range climate, not a cold tolerance: it reaches -22.5 deg C, well below the freezing point of the water the fish lives in.")
      )
    ),
    climatic_temp_max = list(
      label = "Warmest-month temperature of range", kind = "numeric", unit = "deg C", vocab = NULL,
      sources = list(
        fishtraits = nsrc("fishtraits", "max_temp_c", "FishTraits (Frimpong & Angermeier 2009)", "30-year average maximum July temperature at the range centroid, degrees C, read from PRISM 400-m grids per the source's FGDC field definition. A range climate, not a heat tolerance: it runs at 0.88x the CTmax thermofresh measures on the same species.")
      )
    ),

    ## ---- AVONET bird morphology (numeric, mm; single-source) --------------
    beak_width = list(
      label = "Beak width", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        avonet = nsrc("avonet", "beak_width", "AVONET (Tobias et al. 2022)", "Beak width at anterior nostrils, mm.")
      )
    ),
    beak_depth = list(
      label = "Beak depth", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        avonet = nsrc("avonet", "beak_depth", "AVONET (Tobias et al. 2022)", "Beak depth at anterior nostrils, mm.")
      )
    ),
    tarsus_length = list(
      label = "Tarsus length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        avonet = nsrc("avonet", "tarsus_length", "AVONET (Tobias et al. 2022)", "Tarsus length, mm.")
      )
    ),
    tail_length = list(
      label = "Tail length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        avonet = nsrc("avonet", "tail_length", "AVONET (Tobias et al. 2022)", "Tail length, mm.")
      )
    ),
    secondary1 = list(
      label = "First-secondary length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        avonet = nsrc("avonet", "secondary1", "AVONET (Tobias et al. 2022)", "Length of the first secondary feather, mm.")
      )
    ),
    kipps_distance = list(
      label = "Kipp's distance", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        avonet = nsrc("avonet", "kipps_distance", "AVONET (Tobias et al. 2022)", "Kipp's distance (wing-tip to first secondary), mm.")
      )
    ),

    ## ---- GRooT root traits (numeric; units calibrated on shared species) ---
    root_diameter = list(
      label = "Root diameter", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        groot     = nsrc("groot", "root_diameter", "GRooT (Guerrero-Ramirez et al. 2021)", "Fine-root diameter, mm."),
        austraits = nsrc("austraits", "root_diameter", "AusTraits (Falster et al. 2021)", "Root diameter, mm (no conversion).",
                         caution = "AusTraits reports maximum root diameter (APD trait_0012111), including coarse roots; GRooT is fine-root diameter. Runs ~0.3x GRooT on shared species.")
      )
    ),
    specific_root_length = list(
      label = "Specific root length", kind = "numeric", unit = "m/g", vocab = NULL,
      sources = list(
        groot     = nsrc("groot", "specific_root_length", "GRooT (Guerrero-Ramirez et al. 2021)", "Specific root length, m/g."),
        austraits = nsrc("austraits", "root_specific_root_length", "AusTraits (Falster et al. 2021)", "Specific root length, m/g (agrees with GRooT, ratio 1.12 on shared species).")
      )
    ),
    specific_root_area = list(
      label = "Specific root area", kind = "numeric", unit = "cm2/g", vocab = NULL,
      sources = list(
        groot = nsrc("groot", "specific_root_area", "GRooT (Guerrero-Ramirez et al. 2021)", "Specific root area, cm^2/g (data paper Table 1, median 385.8). Three source papers (Quanquan 2011, Mokany & Ash 2008, Chanteloup & Bonis 2013) are ~1000x low from a compilation unit error and are rescaled x1000 in taxifydb's parse_groot -- grounded by Mokany & Ash 2008's own SRA-SLA regression (real SRA ~10 m2/kg = ~100 cm2/g), not a guess -- with standardized sources winning per species. GRooT-only: AusTraits root_specific_root_area is entirely Mokany 2008, the same primary data, so it cannot serve as an independent second source.")
      )
    ),
    root_tissue_density = list(
      label = "Root tissue density", kind = "numeric", unit = "g/cm3", vocab = NULL,
      sources = list(
        groot = nsrc("groot", "root_tissue_density", "GRooT (Guerrero-Ramirez et al. 2021)", "Root tissue density, g/cm^3.")
      )
    ),
    root_mass_fraction = list(
      label = "Root mass fraction", kind = "numeric", unit = "g/g", vocab = NULL,
      sources = list(
        groot     = nsrc("groot", "root_mass_fraction", "GRooT (Guerrero-Ramirez et al. 2021)", "Root mass fraction, g/g."),
        austraits = nsrc("austraits", "root_mass_fraction", "AusTraits (Falster et al. 2021)", "Root mass fraction, g/g (agrees with GRooT, ratio 0.97 on shared species).")
      )
    ),
    root_dry_matter_content = list(
      label = "Root dry matter content", kind = "numeric", unit = "g/g", vocab = NULL,
      sources = list(
        groot     = nsrc("groot", "root_dry_matter_content", "GRooT (Guerrero-Ramirez et al. 2021)", "Root dry matter content, g/g."),
        austraits = nsrc("austraits", "root_dry_matter_content", "AusTraits (Falster et al. 2021)", "mg/g converted to g/g (/1000; 199 -> 0.199 matches GRooT 0.227).", map = function(v) suppressWarnings(as.numeric(v)) / 1000)
      )
    ),
    root_n_concentration = list(
      label = "Root nitrogen concentration", kind = "numeric", unit = "mg/g", vocab = NULL,
      sources = list(
        groot     = nsrc("groot", "root_n_concentration", "GRooT (Guerrero-Ramirez et al. 2021)", "Root nitrogen concentration, mg/g."),
        austraits = nsrc("austraits", "root_n_per_dry_mass", "AusTraits (Falster et al. 2021)", "Root N per dry mass, mg/g (no conversion).",
                         caution = "AusTraits root_N_per_dry_mass (APD trait_0000838) is whole-root N; GRooT is fine-root. Runs ~2x lower on shared species.")
      )
    ),
    rooting_depth = list(
      label = "Rooting depth", kind = "numeric", unit = "m", vocab = NULL,
      sources = list(
        groot = nsrc("groot", "rooting_depth", "GRooT (Guerrero-Ramirez et al. 2021)", "Maximum rooting depth, metres."),
        brot  = nsrc("brot", "rootdepth", "BROT 2.0 (Tavsanoglu & Pausas 2018)", "Rooting depth, metres (no conversion).",
                     caution = "BROT rooting depth runs ~2x GRooT on shared species, likely a maximum-vs-typical depth definition difference.")
      )
    ),
    root_mycorrhizal_colonization = list(
      label = "Root mycorrhizal colonization", kind = "numeric", unit = "percent", vocab = NULL,
      sources = list(
        groot = nsrc("groot", "root_mycorrhizal_colonization", "GRooT (Guerrero-Ramirez et al. 2021)", "Percent of root length colonized by mycorrhizal fungi, 0-100.")
      )
    ),

    ## ---- age at first reproduction (numeric, years) -----------------------
    age_at_first_reproduction = list(
      label = "Age at first reproduction", kind = "numeric", unit = "yr", vocab = NULL,
      sources = list(
        combine = nsrc("combine", "age_first_reproduction_d", "COMBINE (Soria et al. 2021)", "Days converted to years (/365.25); distinct from age at maturity.", map = d2y)
      )
    ),

    ## ---- spider behaviour (World Spider Trait DB) --------------------------
    hunting_guild = list(
      label = "Hunting guild (spider)", kind = "categorical", unit = NA_character_,
      vocab = c("orb weaver", "sheet-web weaver", "space-web weaver",
                "ambush hunter", "ground hunter", "other hunter",
                "specialist", "sensing"),
      sources = list(
        spider_traits = list(enrichment = "spider_traits", col = "hunting_guild",
                          citation = "World Spider Trait DB (Pekar et al. 2021)", note = "Cardoso et al. 2011 guilds; web-builders and hunters folded to the standard set, 'active hunter'/bare hunter -> other hunter.",
                          map = function(v) .xw_grep(v, spider_guild_patterns))
      )
    ),
    web_building = list(
      label = "Web building (spider)", kind = "categorical", unit = NA_character_,
      vocab = c("yes", "no"),
      sources = list(
        spider_traits = list(enrichment = "spider_traits", col = "web_building",
                          citation = "World Spider Trait DB (Pekar et al. 2021)", note = "Builds a capture web or not; yes/present -> yes, no/absent -> no, 'burrow' (a retreat, not a web) -> NA.",
                          map = function(v) .xw_cat(v, webbuild_lookup))
      )
    ),

    ## ---- zooplankton behaviour (Global Zooplankton Trait DB) --------------
    bioluminescence = list(
      label = "Bioluminescence (zooplankton)", kind = "categorical", unit = NA_character_,
      vocab = c("yes", "no"),
      sources = list(
        zooplankton = list(enrichment = "zooplankton", col = "bioluminescence",
                          citation = "Global Zooplankton Trait DB (Pata & Hunt 2025)", note = "present / likely present -> yes, absent -> no.",
                          map = function(v) .xw_grep(v, presence_yn))
      )
    ),
    diel_vertical_migration = list(
      label = "Diel vertical migration (zooplankton)", kind = "categorical", unit = NA_character_,
      vocab = c("yes", "no"),
      sources = list(
        zooplankton = list(enrichment = "zooplankton", col = "diel_vertical_migration",
                          citation = "Global Zooplankton Trait DB (Pata & Hunt 2025)", note = "present (incl. weak/strong/reverse) -> yes, absent -> no, 'maybe' -> NA. Daily vertical movement, distinct from bird seasonal migration.",
                          map = function(v) .xw_grep(v, presence_yn))
      )
    ),

    ## ---- bird nest modalities + genus-keyed mycorrhizal type --------------
    nest_structure = list(
      label = "Nest structure (birds)", kind = "categorical", unit = NA_character_,
      vocab = c("scrape", "platform", "cup", "dome", "dome_tunnel",
                "primary_cavity", "second_cavity"),
      sources = list(
        nesttrait = list(enrichment = "nesttrait", col = "nest_structure",
                          citation = "NestTrait v2 (Chia et al. 2023)", note = "Nest structural type. Multi-modal species keep every modality as a pipe-delimited set (e.g. 'cup|dome') in source order; derived at build time from the seven one-hot NestStr_* flags.",
                          map = chr_verbatim)
      )
    ),
    nest_site = list(
      label = "Nest site (birds)", kind = "categorical", unit = NA_character_,
      vocab = c("ground", "tree", "nontree", "cliff_bank", "underground",
                "waterbody", "termite_ant"),
      sources = list(
        nesttrait = list(enrichment = "nesttrait", col = "nest_site",
                          citation = "NestTrait v2 (Chia et al. 2023)", note = "Nest placement. Multi-modal species keep every modality as a pipe-delimited set (e.g. 'tree|cliff_bank'); derived at build time from the seven one-hot NestSite_* flags.",
                          map = chr_verbatim)
      )
    ),
    nest_attachment = list(
      label = "Nest attachment (birds)", kind = "categorical", unit = NA_character_,
      vocab = c("basal", "forked", "lateral", "pensile"),
      sources = list(
        nesttrait = list(enrichment = "nesttrait", col = "nest_attachment",
                          citation = "NestTrait v2 (Chia et al. 2023)", note = "How the nest attaches to its support. Multi-modal species keep every modality as a pipe-delimited set; derived at build time from the four one-hot NestAtt_* flags.",
                          map = chr_verbatim)
      )
    ),
    mycorrhizal_type = list(
      label = "Mycorrhizal type", kind = "categorical", unit = NA_character_,
      vocab = c("AM", "EcM", "ErM", "OM", "NM", "EcM-AM", "ErM-EcM", "ErM-AM",
                "uncertain", "Other"),
      sources = list(
        fungalroot = list(enrichment = "fungalroot", col = "mycorrhizal_type",
                          join_col = "genus",
                          citation = "FungalRoot (Soudzilovskaia et al. 2020)", note = "Genus-level majority-consensus mycorrhizal type (AM arbuscular, EcM ecto, ErM ericoid, OM orchid, NM non-mycorrhizal, plus dual types); joined on genus. Verbatim source code.",
                          map = chr_verbatim)
      )
    ),

    ## ---- bryophytes --------------------------------------------------------
    ## BET is the only registry-eligible bryophyte source (BRYOATT is
    ## build-only), so every slot here is single-source and grounded on
    ## distribution sanity plus the source's own vocabulary.
    bryophyte_life_form = list(
      label = "Bryophyte life form", kind = "categorical", unit = NA_character_,
      vocab = c("turf", "mat", "cushion", "weft", "dendroid", "rosette", "annual"),
      sources = list(
        bet = list(enrichment = "bet", col = "life_form",
               citation = "Bryophytes of Europe Traits (Hodgetts et al. 2020)",
               note = "During's bryophyte growth architecture. Kept apart from the vascular-plant life_form and growth_form traits: a different scheme over a different structure.",
               map = function(v) .xw_grep(v, bryoform_patterns))
      )
    ),
    shoot_length = list(
      label = "Shoot length", kind = "numeric", unit = "mm", vocab = NULL,
      sources = list(
        bet = nsrc("bet", "shoot_size_mm", "Bryophytes of Europe Traits (Hodgetts et al. 2020)",
               "Millimetres, median 28 over 1,891 species. Not folded into plant_height: bryophytes in mats and turfs grow prostrate, so shoot length is not a height.")
      )
    ),
    spore_diameter = list(
      label = "Spore diameter", kind = "numeric", unit = "um", vocab = NULL,
      sources = list(
        bet = nsrc("bet", "spore_diameter_um", "Bryophytes of Europe Traits (Hodgetts et al. 2020)",
               "Micrometres, median 16 over 1,727 species.")
      )
    ),

    ## ---- corals ------------------------------------------------------------
    larval_development_mode = list(
      label = "Larval development mode", kind = "categorical", unit = NA_character_,
      vocab = c("spawner", "brooder"),
      sources = list(
        coral_traits = list(enrichment = "coral_traits", col = "larval_development_mode",
                        citation = "Coral Trait DB (Madin et al. 2016)",
                        note = "Broadcast spawning against brooding. Kept apart from reproductive_mode, whose vocabulary is the oviparous/viviparous parity axis and shares no term with this one.",
                        map = function(v) .xw_grep(v, c("brood" = "brooder", "spawn" = "spawner")))
      )
    ),
    substrate_attachment = list(
      label = "Substrate attachment", kind = "categorical", unit = NA_character_,
      vocab = c("attached", "unattached", "both"),
      sources = list(
        coral_traits = list(enrichment = "coral_traits", col = "substrate_attachment",
                        citation = "Coral Trait DB (Madin et al. 2016)",
                        note = "Whether the colony is fixed to the substrate.",
                        map = function(v) .xw_grep(v, c(
                          "both" = "both", "unattached" = "unattached", "attached" = "attached")))
      )
    ),
    linear_extension_rate = list(
      label = "Coral linear extension rate", kind = "numeric", unit = "mm/yr", vocab = NULL,
      sources = list(
        coral_traits = nsrc("coral_traits", "growth_rate_mm_yr", "Coral Trait DB (Madin et al. 2016)",
                        "Skeletal linear extension, mm/yr. Deliberately NOT registered as growth_rate: the registry rejects that trait because coral extension, zooplankton per-day growth and AnAge's Gompertz constant are physically different rates, so this carries the coral-specific name instead of widening a trait that cannot hold it.")
      )
    ),
    polyp_retractability = list(
      label = "Polyp retractability", kind = "categorical", unit = NA_character_,
      vocab = c("retractable", "non_retractable"),
      sources = list(
        octocoral = list(enrichment = "octocoral", col = "polyp_retractability",
                     citation = "Gomez-Gras et al. 2024",
                     note = "Stored as 1/0 over 3,539 species.",
                     map = function(v) .xw_cat(v, c("1" = "retractable", "0" = "non_retractable")))
      )
    ),

    ## ---- habitat -----------------------------------------------------------
    primary_habitat = list(
      label = "Primary habitat", kind = "categorical", unit = NA_character_,
      vocab = c("forest", "woodland", "shrub", "grassland", "savanna", "wetland",
                "riparian", "coastal", "sea", "rocky", "plains", "artificial",
                "desert", "bamboo", "open"),
      sources = list(
        birdbase = list(enrichment = "birdbase", col = "primary_habitat",
                    citation = "Sekercioglu et al. 2025 (BIRDBASE)",
                    note = "BIRDBASE's own 14-term habitat vocabulary over 13,067 species, taken verbatim in lower case. Distinct from the numeric habitat_breadth already registered from the same source.",
                    map = function(v) .xw_grep(v, birdhab_patterns)),
        chowdhury = list(enrichment = "chowdhury", col = "habitat_pref",
                    citation = "Chowdhury et al. 2025 (German carabids)",
                    note = paste("German ground beetles, sharing coastal, forest, riparian and",
                                 "wetland with the bird vocabulary and adding open. The taxa are",
                                 "disjoint, so the two vocabularies are never blended for one",
                                 "species. Eurytopic (16) states niche breadth rather than a",
                                 "habitat and 'Special habitats' (10) is a residual bin, so both",
                                 "stay NA; the other 356 map."),
                    map = function(v) .xw_cat(v, carabhab_lookup))
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
.trait_join_one <- function(x, enrichment, col, kind, join_col = "accepted_name",
                            group = NULL, verbose = TRUE,
                            aggregate_trait_fallback =
                              getOption("taxify.aggregate_trait_fallback", TRUE)) {
  tmp  <- ".__taxify_trait_raw__"
  na_t <- stats::setNames(
    list(if (kind == "numeric") NA_real_ else NA_character_), tmp)
  res <- tryCatch(
    if (is.null(group)) {
      enrich_simple(
        x, enrichment_name = enrichment,
        col_map      = stats::setNames(col, tmp),
        source_label = enrichment,
        na_types     = na_t,
        join_col     = join_col,
        expose_all   = FALSE,
        verbose      = FALSE,
        aggregate_trait_fallback = aggregate_trait_fallback
      )
    } else {
      # enrich_by_group() has no aggregate fallback, so a grain-pinned source
      # ignores this setting -- as it already ignores the global option.
      # A grain-pinned source (see nsrc's `group`): one group, so the value
      # lands in an unsuffixed `tmp` exactly as the ungrouped path leaves it.
      enrich_by_group(
        x, enrichment_name = enrichment,
        group_col    = names(group),
        groups       = unname(group),
        value_cols   = stats::setNames(col, tmp),
        source_label = enrichment,
        na_types     = na_t,
        expose_all   = FALSE,
        verbose      = FALSE
      )
    },
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


# Fetch one numeric source's value plus its within-source min/max, where the
# .vtr stores them as <col>_min / <col>_max (built by taxifydb wherever a source
# has several records per species). The source's unit map is applied to all
# three. Missing spread columns come back all-NA, so min/max fall back to the
# point value -- the source then contributes only to the cross-source range, and
# the same code path deepens automatically once a rebuilt .vtr carries the
# stored spread. pmin/pmax guard against a non-monotonic map swapping the bounds.
.trait_join_spread <- function(x, enrichment, col, join_col = "accepted_name",
                               map = identity, verbose = TRUE,
                               aggregate_trait_fallback =
                                 getOption("taxify.aggregate_trait_fallback", TRUE)) {
  cm   <- c(.v = col, .lo = paste0(col, "_min"), .hi = paste0(col, "_max"))
  na_t <- list(.v = NA_real_, .lo = NA_real_, .hi = NA_real_)
  res <- tryCatch(
    enrich_simple(
      x, enrichment_name = enrichment,
      col_map = cm, source_label = enrichment,
      na_types = na_t, join_col = join_col,
      expose_all = FALSE, verbose = FALSE,
      aggregate_trait_fallback = aggregate_trait_fallback
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
  v  <- map(res[[".v"]])
  lo <- map(res[[".lo"]])
  hi <- map(res[[".hi"]])
  lo[is.na(lo)] <- v[is.na(lo)]        # no stored lower bound -> the value
  hi[is.na(hi)] <- v[is.na(hi)]        # no stored upper bound -> the value
  list(value = v, min = pmin(lo, hi), max = pmax(lo, hi))
}


# Resolve the coalesce reducer, defaulting by trait kind (numeric -> median,
# categorical -> first) and validating against the reducers each kind allows.
.resolve_combine <- function(combine, kind) {
  ok <- if (kind == "numeric") {
    c("median", "mean", "first", "min", "max", "complete")
  } else {
    c("first", "vote", "complete")
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
# majority with priority-order tie-breaking. `complete` selects the single most
# populated source (ties broken by priority order) and reports it verbatim --
# used when sources measure the trait by different methods, where blending would
# manufacture a value matching no method. When an aggregator is used the source
# label is the comma-separated set of contributing sources.
.coalesce_sources <- function(per_src, ord, kind, combine) {
  n         <- length(per_src[[1L]])
  na_scalar <- if (kind == "numeric") NA_real_ else NA_character_
  present   <- vapply(per_src, function(v) !is.na(v), logical(n))
  if (is.null(dim(present))) present <- matrix(present, nrow = n)
  nsrc      <- as.integer(rowSums(present))

  if (combine == "complete") {
    counts <- vapply(per_src, function(v) sum(!is.na(v)), integer(1L))
    j      <- which.max(counts)          # ties -> first in ord (registry priority)
    v      <- per_src[[j]]
    has    <- !is.na(v)
    return(list(value  = v,
                source = ifelse(has, ord[j], NA_character_),
                n      = as.integer(has),
                best   = ord[j]))
  }

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


# Reduce the per-source lower/upper bounds (in priority order) to one spread per
# row: the smallest lower bound and largest upper bound across every source that
# supplied a value there. With no stored within-source spread each source's
# min/max equal its point value, so this returns the cross-source range; with
# stored spread it widens to the extremes actually observed in any source.
.coalesce_spread <- function(per_min, per_max) {
  n  <- length(per_min[[1L]])
  Lo <- do.call(cbind, per_min)
  Hi <- do.call(cbind, per_max)
  mn <- vapply(seq_len(n), function(i) {
    r <- Lo[i, ]; r <- r[!is.na(r)]; if (!length(r)) NA_real_ else min(r)
  }, numeric(1L))
  mx <- vapply(seq_len(n), function(i) {
    r <- Hi[i, ]; r <- r[!is.na(r)]; if (!length(r)) NA_real_ else max(r)
  }, numeric(1L))
  list(min = mn, max = mx)
}


# Build the per-row `<trait>_caution` vector for a coalesced trait, or NULL when
# no caution applies. `cvec` is the named per-source caution text (NA where the
# source carries none). Two cases:
#   * method-discordant selection (combine "complete" with a cautioned source):
#     the whole trait mixes methods, so every reported row is flagged with which
#     source was used and what the alternatives measure.
#   * otherwise: flag only the rows whose producing source(s) are cautioned.
.trait_caution_col <- function(co, cvec, disc, combine) {
  if (all(is.na(cvec))) return(NULL)
  val <- co$value
  n   <- length(val)

  if (disc && combine == "complete") {
    if (all(is.na(val))) return(NULL)
    altc <- cvec[!is.na(cvec)]
    txt  <- sprintf(
      paste0("Sources measure this differently; reported the most complete ",
             "source '%s'. %s Use mode = \"wide\" to see every source."),
      co$best,
      paste(sprintf("[%s] %s", names(altc), unname(altc)), collapse = " "))
    return(ifelse(!is.na(val), txt, NA_character_))
  }

  src <- co$source
  out <- vapply(seq_len(n), function(i) {
    s <- src[i]
    if (is.na(s)) return(NA_character_)
    parts <- strsplit(s, ",", fixed = TRUE)[[1L]]
    cc    <- cvec[parts]; cc <- cc[!is.na(cc)]
    if (!length(cc)) NA_character_
    else paste(sprintf("[%s] %s", names(cc), unname(cc)), collapse = " | ")
  }, character(1L))
  if (all(is.na(out))) NULL else out
}


# Wide-mode caution column: for each row, the caution text of every cautioned
# source that actually supplied a value there. NULL when no cautioned source
# contributed any value. `per_src` is named by source; `cvec` the caution texts.
.trait_wide_caution <- function(per_src, cvec, n) {
  caut <- names(cvec)[!is.na(cvec)]
  if (!length(caut)) return(NULL)
  out <- rep(NA_character_, n)
  for (s in caut) {
    v <- per_src[[s]]
    if (is.null(v)) next
    hit <- !is.na(v)
    piece <- sprintf("[%s] %s", s, cvec[[s]])
    out[hit] <- ifelse(is.na(out[hit]), piece, paste(out[hit], piece, sep = " | "))
  }
  if (all(is.na(out))) NULL else out
}


# Merge per-record source cautions (`perrec`, named by source, each a length-n
# text vector NA where no caution) into an existing caution vector `cr` (or NULL).
# In coalesce mode pass `contributors` = the coalesced source label per row so a
# source's caution fires only where it actually contributed to the reported
# value; in wide mode pass NULL (each source's text is already gated to where it
# supplied a value). Returns NULL when nothing is flagged.
.merge_perrec_caution <- function(cr, perrec, contributors, n) {
  if (!length(perrec)) return(cr)
  out <- if (is.null(cr)) rep(NA_character_, n) else cr
  for (s in names(perrec)) {
    txt <- perrec[[s]]
    if (!is.null(contributors)) {
      inrow <- vapply(seq_len(n), function(i) {
        cs <- contributors[i]
        !is.na(cs) && s %in% strsplit(cs, ",", fixed = TRUE)[[1L]]
      }, logical(1L))
      txt[!inrow] <- NA_character_
    }
    hit <- !is.na(txt)
    out[hit] <- ifelse(is.na(out[hit]), txt[hit],
                       paste(out[hit], txt[hit], sep = " | "))
  }
  if (all(is.na(out))) NULL else out
}
