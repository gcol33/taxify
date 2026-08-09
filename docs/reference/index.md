# Package index

## Match and inspect names

Resolve a vector of names against local backbones and check a list
before you trust it.

- [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) :
  Match taxonomic names against local backbone databases

- [`parse_name()`](https://gillescolling.com/taxify/reference/parse_name.md)
  : Parse taxonomic names into their structural parts

- [`comm2sci()`](https://gillescolling.com/taxify/reference/comm2sci.md)
  : Resolve common (vernacular) names to scientific names

- [`sci2comm()`](https://gillescolling.com/taxify/reference/sci2comm.md)
  : Resolve scientific names to common (vernacular) names

- [`id2name()`](https://gillescolling.com/taxify/reference/id2name.md) :
  Resolve backbone IDs to names

- [`inspect()`](https://gillescolling.com/taxify/reference/inspect.md) :
  Inspect a name list for probable typos and other anomalies

- [`reconcile()`](https://gillescolling.com/taxify/reference/reconcile.md)
  : Reconcile a checklist against a backbone's current treatment

- [`taxify_regions()`](https://gillescolling.com/taxify/reference/taxify_regions.md)
  :

  List the regions accepted by `region=`

- [`taxify_long()`](https://gillescolling.com/taxify/reference/taxify_long.md)
  : Reshape grouped enrichment columns to long format

- [`export_data()`](https://gillescolling.com/taxify/reference/export_data.md)
  : Export a taxify result to file

- [`cite()`](https://gillescolling.com/taxify/reference/cite.md) : Cite
  data sources used in a taxify result

## Explore the backbone

Read the backbone the other ways — list synonyms, list the taxa within
or beneath a group, attach the full classification, build a taxonomy
tree.

- [`synonyms()`](https://gillescolling.com/taxify/reference/synonyms.md)
  : List the synonyms of a name
- [`children()`](https://gillescolling.com/taxify/reference/children.md)
  : List the accepted taxa within a genus or family
- [`downstream()`](https://gillescolling.com/taxify/reference/downstream.md)
  : List all descendants of a taxon down to a target rank
- [`upstream()`](https://gillescolling.com/taxify/reference/upstream.md)
  : List the higher classification (ancestors) of a taxon
- [`add_classification()`](https://gillescolling.com/taxify/reference/add_classification.md)
  : Add the full higher classification to a taxify result
- [`class2tree()`](https://gillescolling.com/taxify/reference/class2tree.md)
  [`print(`*`<taxify_tree>`*`)`](https://gillescolling.com/taxify/reference/class2tree.md)
  : Build a taxonomy tree from resolved names
- [`lowest_common()`](https://gillescolling.com/taxify/reference/lowest_common.md)
  : Lowest common taxon of a set of names
- [`taxify_candidates()`](https://gillescolling.com/taxify/reference/taxify_candidates.md)
  : Expand ambiguous matches into their candidate taxa

## Backbone data and cache

Download, cache, and inspect backbone snapshots and the unified genus
register.

- [`install_backbones()`](https://gillescolling.com/taxify/reference/install_backbones.md)
  : Install taxonomic backbones for offline matching
- [`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md)
  : Download a pre-built taxify backbone
- [`taxify_download_enrichment()`](https://gillescolling.com/taxify/reference/taxify_download_enrichment.md)
  : Download one or more enrichment .vtr files
- [`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md)
  : Get the taxify data directory
- [`taxify_example_data()`](https://gillescolling.com/taxify/reference/taxify_example_data.md)
  : Path to the bundled example database
- [`taxify_clear_cache()`](https://gillescolling.com/taxify/reference/taxify_clear_cache.md)
  : Clear all cached backbones
- [`taxify_refresh_manifest()`](https://gillescolling.com/taxify/reference/taxify_refresh_manifest.md)
  : Invalidate the session manifest cache
- [`taxify_build_register()`](https://gillescolling.com/taxify/reference/taxify_build_register.md)
  : Build the genus register from source
- [`taxify_load_register()`](https://gillescolling.com/taxify/reference/taxify_load_register.md)
  : Load the unified genus register into memory
- [`taxify_register_coverage()`](https://gillescolling.com/taxify/reference/taxify_register_coverage.md)
  : Show backbone coverage for a genus
- [`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md)
  : Look up a genus in the register
- [`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md)
  : Record the exact backbone and enrichment versions behind a result
- [`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md)
  : Check an install against a lockfile

## Backend-specific columns

Attach extra columns from the backbone that matched.

- [`add_col_info()`](https://gillescolling.com/taxify/reference/add_col_info.md)
  : Add COL-specific columns
- [`add_gbif_info()`](https://gillescolling.com/taxify/reference/add_gbif_info.md)
  : Add GBIF-specific columns
- [`add_wfo_info()`](https://gillescolling.com/taxify/reference/add_wfo_info.md)
  : Add WFO-specific columns
- [`add_hybrid_info()`](https://gillescolling.com/taxify/reference/add_hybrid_info.md)
  : Add hybrid parent and type information

## Traits across sources

Name one trait; gather and harmonize it from every source that carries
it.

- [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
  : Add a trait from every source that carries it
- [`list_traits()`](https://gillescolling.com/taxify/reference/list_traits.md)
  : List the traits available to add_trait()
- [`trait_info()`](https://gillescolling.com/taxify/reference/trait_info.md)
  : Describe a trait's sources and units

## Browse and discover

See every backbone, enrichment, and trait taxify offers, and join your
own table.

- [`taxify_databases()`](https://gillescolling.com/taxify/reference/taxify_databases.md)
  : One overview of every database taxify knows about
- [`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md)
  : List supported taxonomic backbones
- [`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md)
  : List available enrichments
- [`enrichment_cols()`](https://gillescolling.com/taxify/reference/enrichment_cols.md)
  : Browse the trait columns an enrichment door can attach
- [`enrichment_groups()`](https://gillescolling.com/taxify/reference/enrichment_groups.md)
  : Browse the group values a grouped enrichment can filter on
- [`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
  : Add custom data by taxonomic matching

## Enrichments — distribution and status

- [`add_iucn()`](https://gillescolling.com/taxify/reference/add_iucn.md)
  : Add IUCN Red List conservation status
- [`add_griis()`](https://gillescolling.com/taxify/reference/add_griis.md)
  : Add invasive species status (GRIIS)
- [`add_glonaf()`](https://gillescolling.com/taxify/reference/add_glonaf.md)
  : Add naturalized alien flora status (GloNAF)
- [`add_invacost()`](https://gillescolling.com/taxify/reference/add_invacost.md)
  : Add economic cost of biological invasions (InvaCost)
- [`add_gidias()`](https://gillescolling.com/taxify/reference/add_gidias.md)
  : Add invasive-species impact (EICAT / SEICAT, GIDIAS)
- [`add_alien_first_records()`](https://gillescolling.com/taxify/reference/add_alien_first_records.md)
  : Add alien species first record years
- [`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md)
  : Add WCVP native range status
- [`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md)
  : Add common (vernacular) names
- [`add_globi()`](https://gillescolling.com/taxify/reference/add_globi.md)
  : Add biotic interaction degree (GloBI)

## Enrichments — plants

- [`add_zanne()`](https://gillescolling.com/taxify/reference/add_zanne.md)
  : Add woodiness (Zanne et al. 2014)
- [`add_eive()`](https://gillescolling.com/taxify/reference/add_eive.md)
  : Add EIVE ecological indicator values
- [`add_diaz_traits()`](https://gillescolling.com/taxify/reference/add_diaz_traits.md)
  : Add seed mass and plant height (Diaz et al. 2022)
- [`add_leda()`](https://gillescolling.com/taxify/reference/add_leda.md)
  : Add plant traits from LEDA Traitbase
- [`add_groot()`](https://gillescolling.com/taxify/reference/add_groot.md)
  : Add root traits (GRooT)
- [`add_hydraulics()`](https://gillescolling.com/taxify/reference/add_hydraulics.md)
  : Add plant hydraulic traits (Sanchez-Martinez et al.)
- [`add_noddb()`](https://gillescolling.com/taxify/reference/add_noddb.md)
  : Add root-nodule nitrogen fixation (NodDB)
- [`add_baseflor()`](https://gillescolling.com/taxify/reference/add_baseflor.md)
  : Add plant traits from Baseflor (Catminat / Julve)
- [`add_ecoflora()`](https://gillescolling.com/taxify/reference/add_ecoflora.md)
  : Add British plant traits from Ecoflora
- [`add_floraweb()`](https://gillescolling.com/taxify/reference/add_floraweb.md)
  : Add German plant traits from FloraWeb
- [`add_plantatt()`](https://gillescolling.com/taxify/reference/add_plantatt.md)
  : Add British and Irish plant attributes (PLANTATT)
- [`add_bryoatt()`](https://gillescolling.com/taxify/reference/add_bryoatt.md)
  : Add British and Irish bryophyte attributes (BRYOATT)
- [`add_clopla()`](https://gillescolling.com/taxify/reference/add_clopla.md)
  : Add clonal and bud-bank traits (CLO-PLA)
- [`add_austraits()`](https://gillescolling.com/taxify/reference/add_austraits.md)
  : Add Australian plant traits (AusTraits)
- [`add_bien()`](https://gillescolling.com/taxify/reference/add_bien.md)
  : Add plant traits (BIEN)
- [`add_brot()`](https://gillescolling.com/taxify/reference/add_brot.md)
  : Add Mediterranean plant traits (BROT 2.0)
- [`add_bet()`](https://gillescolling.com/taxify/reference/add_bet.md) :
  Add bryophyte traits (Bryophytes of Europe Traits)
- [`add_kew_sid()`](https://gillescolling.com/taxify/reference/add_kew_sid.md)
  : Add seed traits from the Kew Seed Information Database (SER-SID)
- [`add_kew_cvalues()`](https://gillescolling.com/taxify/reference/add_kew_cvalues.md)
  : Add plant genome size (Kew Plant DNA C-values)
- [`add_ccdb()`](https://gillescolling.com/taxify/reference/add_ccdb.md)
  : Add plant chromosome numbers (Chromosome Counts Database)
- [`add_useful_plants()`](https://gillescolling.com/taxify/reference/add_useful_plants.md)
  : Add human-use categories (World Checklist of Useful Plant Species)
- [`add_gwdd()`](https://gillescolling.com/taxify/reference/add_gwdd.md)
  : Add wood density (Global Wood Density Database v2)
- [`add_pignatti()`](https://gillescolling.com/taxify/reference/add_pignatti.md)
  : Add Italian plant traits from Pignatti (on demand, via TR8)
- [`add_gift()`](https://gillescolling.com/taxify/reference/add_gift.md)
  : Add plant traits from GIFT
- [`gift_traits()`](https://gillescolling.com/taxify/reference/gift_traits.md)
  : Browse the bundled GIFT trait columns

## Enrichments — fungi, algae, lichens, and microbes

- [`add_fungal_traits()`](https://gillescolling.com/taxify/reference/add_fungal_traits.md)
  : Add fungal lifestyle and trait data (FungalTraits)
- [`add_fungalroot()`](https://gillescolling.com/taxify/reference/add_fungalroot.md)
  : Add mycorrhizal type from FungalRoot
- [`add_funguild()`](https://gillescolling.com/taxify/reference/add_funguild.md)
  : Add fungal functional guild data (FUNGuild)
- [`add_usda_fungus_host()`](https://gillescolling.com/taxify/reference/add_usda_fungus_host.md)
  : Add fungal host breadth (USDA Fungus-Host Dataset)
- [`add_italic()`](https://gillescolling.com/taxify/reference/add_italic.md)
  : Add Italian-lichen taxon-page traits (ITALIC)
- [`add_algae_traits()`](https://gillescolling.com/taxify/reference/add_algae_traits.md)
  : Add macroalgal functional traits (AlgaeTraits)
- [`add_bacdive()`](https://gillescolling.com/taxify/reference/add_bacdive.md)
  : Add bacterial and archaeal strain phenotypes (BacDive)
- [`add_madin()`](https://gillescolling.com/taxify/reference/add_madin.md)
  : Add bacterial and archaeal traits (Madin et al.)
- [`add_faprotax()`](https://gillescolling.com/taxify/reference/add_faprotax.md)
  : Add prokaryote metabolic and ecological functions (FAPROTAX)
- [`add_rimet_phyto()`](https://gillescolling.com/taxify/reference/add_rimet_phyto.md)
  : Add phytoplankton cell metrics (Rimet & Druart)
- [`add_edwards_phyto()`](https://gillescolling.com/taxify/reference/add_edwards_phyto.md)
  : Add phytoplankton nutrient-uptake traits (Edwards et al.)
- [`add_ramond()`](https://gillescolling.com/taxify/reference/add_ramond.md)
  : Add marine protist functional traits (Ramond et al.)

## Enrichments — birds and mammals

- [`add_avonet()`](https://gillescolling.com/taxify/reference/add_avonet.md)
  : Add bird morphology and migration (AVONET)
- [`add_birdbase()`](https://gillescolling.com/taxify/reference/add_birdbase.md)
  : Add bird traits (BIRDBASE)
- [`add_nesttrait()`](https://gillescolling.com/taxify/reference/add_nesttrait.md)
  : Add bird nest traits (NestTrait)
- [`add_elton_traits()`](https://gillescolling.com/taxify/reference/add_elton_traits.md)
  : Add diet, foraging, and body mass (EltonTraits 1.0)
- [`add_frugivoria()`](https://gillescolling.com/taxify/reference/add_frugivoria.md)
  : Add Neotropical frugivore traits (Frugivoria)
- [`add_pantheria()`](https://gillescolling.com/taxify/reference/add_pantheria.md)
  : Add mammal life-history traits (PanTHERIA)
- [`add_phylacine()`](https://gillescolling.com/taxify/reference/add_phylacine.md)
  : Add mammal traits including extinct species (PHYLACINE)
- [`add_combine()`](https://gillescolling.com/taxify/reference/add_combine.md)
  : Add mammal traits (COMBINE)
- [`add_combine_reported()`](https://gillescolling.com/taxify/reference/add_combine_reported.md)
  : Add mammal traits from COMBINE (reported values)
- [`add_combine_imputed()`](https://gillescolling.com/taxify/reference/add_combine_imputed.md)
  : Add mammal traits from COMBINE (phylogenetically imputed values)
- [`add_homerange()`](https://gillescolling.com/taxify/reference/add_homerange.md)
  : Add mammal home-range size (HomeRange)
- [`add_tetradensity()`](https://gillescolling.com/taxify/reference/add_tetradensity.md)
  : Add population density (TetraDENSITY)
- [`add_eurobat()`](https://gillescolling.com/taxify/reference/add_eurobat.md)
  : Add European bat traits (EuroBaTrait)
- [`add_gmpd()`](https://gillescolling.com/taxify/reference/add_gmpd.md)
  : Add mammal parasite burden (GMPD 2.0)

## Enrichments — reptiles, amphibians, and fish

- [`add_repttraits()`](https://gillescolling.com/taxify/reference/add_repttraits.md)
  : Add reptile ecological traits and distribution (ReptTraits)
- [`add_chelonians()`](https://gillescolling.com/taxify/reference/add_chelonians.md)
  : Add turtle traits (CheloniansTraits)
- [`add_amphibio()`](https://gillescolling.com/taxify/reference/add_amphibio.md)
  : Add amphibian life-history traits (AmphiBIO)
- [`add_huang_amph()`](https://gillescolling.com/taxify/reference/add_huang_amph.md)
  : Add amphibian morphometrics (Huang)
- [`add_pottier()`](https://gillescolling.com/taxify/reference/add_pottier.md)
  : Add amphibian heat tolerance (Pottier)
- [`add_fishbase()`](https://gillescolling.com/taxify/reference/add_fishbase.md)
  : Add fish traits (FishBase)
- [`add_fishmorph()`](https://gillescolling.com/taxify/reference/add_fishmorph.md)
  : Add freshwater fish morphological traits (FISHMORPH)
- [`add_fishtraits()`](https://gillescolling.com/taxify/reference/add_fishtraits.md)
  : Add United States freshwater fish traits (FishTraits)
- [`add_beukhof()`](https://gillescolling.com/taxify/reference/add_beukhof.md)
  : Add marine fish traits (Beukhof)
- [`add_quimbayo()`](https://gillescolling.com/taxify/reference/add_quimbayo.md)
  : Add reef-fish traits (Quimbayo)
- [`add_parravicini()`](https://gillescolling.com/taxify/reference/add_parravicini.md)
  : Add reef-fish trophic guild (Parravicini)
- [`add_pelagic()`](https://gillescolling.com/taxify/reference/add_pelagic.md)
  : Add pelagic species traits
- [`add_sharkipedia()`](https://gillescolling.com/taxify/reference/add_sharkipedia.md)
  : Add elasmobranch life-history traits (Sharkipedia)

## Enrichments — invertebrates and aquatic life

- [`add_arthropod_traits()`](https://gillescolling.com/taxify/reference/add_arthropod_traits.md)
  : Add arthropod life-history traits (NW European Arthropods)
- [`add_spider_traits()`](https://gillescolling.com/taxify/reference/add_spider_traits.md)
  : Add spider traits (World Spider Trait Database)
- [`add_bee_ostwald()`](https://gillescolling.com/taxify/reference/add_bee_ostwald.md)
  : Add bee morphometrics (Ostwald)
- [`add_eupolltrait()`](https://gillescolling.com/taxify/reference/add_eupolltrait.md)
  : Add European pollinator traits (EuPollTrait)
- [`add_leptraits()`](https://gillescolling.com/taxify/reference/add_leptraits.md)
  : Add butterfly traits (LepTraits)
- [`add_odonata()`](https://gillescolling.com/taxify/reference/add_odonata.md)
  : Add odonate behavioural/ecological traits (OPD)
- [`add_saproxylic()`](https://gillescolling.com/taxify/reference/add_saproxylic.md)
  : Add saproxylic beetle morphology (Hagge)
- [`add_chowdhury()`](https://gillescolling.com/taxify/reference/add_chowdhury.md)
  : Add German ground-beetle traits and occupancy trends (Chowdhury et
  al. 2025)
- [`add_finand()`](https://gillescolling.com/taxify/reference/add_finand.md)
  : Add Helsinki urban-forest carabid traits (Finand & Kotze)
- [`add_eberswalde()`](https://gillescolling.com/taxify/reference/add_eberswalde.md)
  : Add Eberswalde long-term carabid monitoring traits and trends
- [`add_alpine_carabids()`](https://gillescolling.com/taxify/reference/add_alpine_carabids.md)
  : Add Alpine ground-beetle traits (Chamberlain et al.)
- [`add_imageomics_neon()`](https://gillescolling.com/taxify/reference/add_imageomics_neon.md)
  : Add North American ground-beetle elytra measurements (Imageomics /
  NEON)
- [`add_sworm()`](https://gillescolling.com/taxify/reference/add_sworm.md)
  : Add earthworm ecological groups (sWorm)
- [`add_betsi_earthworm_traits()`](https://gillescolling.com/taxify/reference/add_betsi_earthworm_traits.md)
  : Add earthworm traits (Pelosi et al. 2014)
- [`add_betsi_collembola_traits()`](https://gillescolling.com/taxify/reference/add_betsi_collembola_traits.md)
  : Add Collembola traits (Lu et al. 2025)
- [`add_ellers_collembola()`](https://gillescolling.com/taxify/reference/add_ellers_collembola.md)
  : Add Collembola traits (Ellers et al. 2018)
- [`add_inrae_collembola_traits()`](https://gillescolling.com/taxify/reference/add_inrae_collembola_traits.md)
  : Add Collembola traits (Data INRAE deposits)
- [`add_ecomorphosis()`](https://gillescolling.com/taxify/reference/add_ecomorphosis.md)
  : Add Collembola ecomorphosis (Bonfanti et al. 2022)
- [`add_betsi_collembola_body_length()`](https://gillescolling.com/taxify/reference/add_betsi_collembola_body_length.md)
  : Add Collembola body length (BETSI export)
- [`add_monograph_collembola_body_length()`](https://gillescolling.com/taxify/reference/add_monograph_collembola_body_length.md)
  : Add Collembola body length (monographs)
- [`add_plazi_collembola_body_length()`](https://gillescolling.com/taxify/reference/add_plazi_collembola_body_length.md)
  : Add Collembola body length (Plazi treatments)
- [`add_hosts()`](https://gillescolling.com/taxify/reference/add_hosts.md)
  : Add Lepidoptera hostplant breadth (NHM HOSTS)
- [`add_blanchard()`](https://gillescolling.com/taxify/reference/add_blanchard.md)
  : Add ant genus defensive traits (Blanchard & Moreau)
- [`add_coral_traits()`](https://gillescolling.com/taxify/reference/add_coral_traits.md)
  : Add scleractinian coral traits (Coral Trait Database)
- [`add_octocoral()`](https://gillescolling.com/taxify/reference/add_octocoral.md)
  : Add octocoral traits (Octocoral Trait Database)
- [`add_zooplankton()`](https://gillescolling.com/taxify/reference/add_zooplankton.md)
  : Add marine zooplankton traits
- [`add_arctic_traits()`](https://gillescolling.com/taxify/reference/add_arctic_traits.md)
  : Add Arctic marine benthos traits
- [`add_nztd()`](https://gillescolling.com/taxify/reference/add_nztd.md)
  : Add NZ marine benthos traits (NZTD)
- [`add_disperse()`](https://gillescolling.com/taxify/reference/add_disperse.md)
  : Add aquatic-invertebrate dispersal traits (DISPERSE)
- [`add_freshwater_insects_conus()`](https://gillescolling.com/taxify/reference/add_freshwater_insects_conus.md)
  : Add freshwater-insect genus traits (Freshwater Insects CONUS)
- [`add_thermofresh()`](https://gillescolling.com/taxify/reference/add_thermofresh.md)
  : Add freshwater thermal-tolerance traits (ThermoFresh)
- [`add_sheld()`](https://gillescolling.com/taxify/reference/add_sheld.md)
  : Add freshwater mussel traits (SHELD)
- [`add_copepod_traits()`](https://gillescolling.com/taxify/reference/add_copepod_traits.md)
  : Add copepod traits (Brun et al. 2017)
- [`add_epa_freshwater()`](https://gillescolling.com/taxify/reference/add_epa_freshwater.md)
  : Add freshwater invertebrate traits (US EPA)
- [`add_cefas_btrait()`](https://gillescolling.com/taxify/reference/add_cefas_btrait.md)
  : Add benthic invertebrate traits (Cefas)
- [`add_sealifebase()`](https://gillescolling.com/taxify/reference/add_sealifebase.md)
  : Add aquatic-life traits (SeaLifeBase)

## Enrichments — cross-taxon

- [`add_amniote()`](https://gillescolling.com/taxify/reference/add_amniote.md)
  : Add amniote life-history traits (Amniote Life History Database)
- [`add_anage()`](https://gillescolling.com/taxify/reference/add_anage.md)
  : Add longevity and life-history traits (AnAge)
- [`add_animaltraits()`](https://gillescolling.com/taxify/reference/add_animaltraits.md)
  : Add cross-taxon body mass and metabolic rate (AnimalTraits)
- [`add_globtherm()`](https://gillescolling.com/taxify/reference/add_globtherm.md)
  : Add thermal tolerance limits (GlobTherm)
- [`add_tree_of_sex()`](https://gillescolling.com/taxify/reference/add_tree_of_sex.md)
  : Add sex-determination traits (Tree of Sex)
- [`add_virion()`](https://gillescolling.com/taxify/reference/add_virion.md)
  : Add host-virus association breadth (VIRION)

## Low-level building blocks

Exported internals for power users and custom pipelines.

- [`taxify_build()`](https://gillescolling.com/taxify/reference/taxify_build.md)
  : Build a backbone database from source
- [`score_candidates()`](https://gillescolling.com/taxify/reference/score_candidates.md)
  : Score match candidates by resolution priority
- [`embed_accepted()`](https://gillescolling.com/taxify/reference/embed_accepted.md)
  : Embed accepted taxon info at build time (synonym self-join)
- [`precompute_keys()`](https://gillescolling.com/taxify/reference/precompute_keys.md)
  : Precompute matching keys at build time
- [`normalize_epithets()`](https://gillescolling.com/taxify/reference/normalize_epithets.md)
  : Vectorized Latin orthographic normalization
- [`is_aggregate_name()`](https://gillescolling.com/taxify/reference/is_aggregate_name.md)
  : Test whether a canonical name carries an aggregate marker
- [`normalize_aggregate_name()`](https://gillescolling.com/taxify/reference/normalize_aggregate_name.md)
  : Normalize aggregate markers on canonical names (build-time)
