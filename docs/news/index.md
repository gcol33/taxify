# Changelog

## taxify 0.3.6

### Hybrid matching

- Hybrid names are handled by type instead of being reduced to their
  first component.
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  gains a `hybrid_type` column (`"nothogenus"`, `"nothospecies"`,
  `"formula"`, or `NA`).

- Hybrid formulas (`"Salix alba × Salix fragilis"`) no longer resolve to
  a single species. Previously the cross was silently cut to its first
  parent and returned as an exact match to `Salix alba`; now the cross
  row carries `match_type = "hybrid_formula"` with `NA` backbone-match
  columns. The parent binomials, and their accepted names, are available
  on demand via
  [`add_hybrid_info()`](https://gillescolling.com/taxify/reference/add_hybrid_info.md),
  which now adds `hybrid_parent_1`, `hybrid_parent_2`,
  `hybrid_parent_1_accepted`, and `hybrid_parent_2_accepted`.

- The same-genus formula shorthand is recognized:
  `"Salix alba × fragilis"` (second parent written as a bare epithet)
  parses to parents `"Salix alba"` and `"Salix fragilis"`.

- Nothogenus names match backbones that store the multiplication sign.
  `"× Cupressocyparis leylandii"` previously returned `NA` against
  backbones whose canonical form keeps the sign
  (e.g. `"× Cupressocyparis leylandii"`); matching now tries the
  `"× Genus ..."` and `"×Genus ..."` forms alongside the sign-stripped
  binomial. Nothospecies (`"Quercus × hispanica"`) continue to match as
  before.

## taxify 0.3.5

### Discovery

- New
  [`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md)
  lists every supported taxonomic backbone with its scope, name count,
  download size, version, install status, and source, mirroring
  [`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md).
  New
  [`taxify_databases()`](https://gillescolling.com/taxify/reference/taxify_databases.md)
  stacks the backbones and enrichments into one overview so the full
  breadth is one call away. A canonical backbone registry now backs
  `resolve_backend()`, `installed_backbones()`, and these verbs, so the
  supported set cannot drift between them.

- A “Databases” pkgdown article lists every backbone, enrichment, and
  trait, generated from the shipped manifest so it stays current.

### Backbones

- The LCVP and WCVP backbones are downloadable as pre-built `.vtr`
  files. They previously had no published release and could only be
  built from source; both are now in the manifest (`lcvp-3.0.1`,
  `wcvp-2026.06`), so all fifteen backbones resolve without `taxifydb`
  installed.

## taxify 0.3.4

CRAN release: 2026-07-09

### Bug fixes

- `clean_names()` recognizes a much wider set of taxonomic qualifiers
  and rank abbreviations. Previously an unrecognized marker survived
  into the cleaned name, so the name no longer matched the backbone’s
  bare binomial/trinomial (it dropped to fuzzy) and the annotation was
  lost from the `qualifier` column. Now folded to their canonical
  tokens: the subspecies abbreviations `ssp.` and `nssp.` and the
  spelled-out `subspecies` (to `subsp.`); the sensu-stricto form `s.s.`
  (to `s.str.`); the forma spellings `fo.` and `forma` (to `f.`); the
  infraspecific ranks `subvar.`, `subf.`, and `convar.`; the notho-
  (hybrid) ranks `nothosubsp.` and `nothovar.` (to `subsp.`/`var.`, the
  hybrid signal being carried separately by the multiplication sign);
  cultivar `cv.`; the pathogen infrasubspecific categories `f. sp.`
  (forma specialis, previously mislabelled as a bare forma) and `pv.`
  (pathovar); the determination marker `nr.` (“near”); the
  open-nomenclature markers `indet.` and `sp. nov.`; the long and bare
  concept forms `s. lat.` and `coll.` (to `s.l.`); and the species-group
  markers `group` and `gr.`. Each token matches only as a whole trailing
  word, so it never touches a real epithet (`Carex novae-zelandiae` and
  `Convallaria majalis` are untouched). The qualifier registry in
  `R/clean.R` remains the single source of truth for every spelling.

## taxify 0.3.3

### New features

- WCVP and LCVP join the plant backbones. `taxify(x, backend = "wcvp")`
  matches against Kew’s World Checklist of Vascular Plants (Govaerts et
  al. 2021, ~1.4M names, CC BY 4.0); `backend = "lcvp"` matches the
  Leipzig Catalogue of Vascular Plants (Freiberg et al. 2020, MIT). Both
  slot into the fallback chain (`backend = c("wcvp", "wfo")`) and
  contribute their genera (kingdom Plantae) to the unified genus
  register. Fifteen backbones are now available.
- Four new verbs read the backbone in the directions
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  does not.
  [`synonyms()`](https://gillescolling.com/taxify/reference/synonyms.md)
  lists every synonym that resolves to a name’s accepted taxon (the
  reverse of the forward resolution).
  [`add_classification()`](https://gillescolling.com/taxify/reference/add_classification.md)
  fills the higher ranks (kingdom, phylum, class, order) from the
  matched backbone, complementing the `family` and `genus` already in
  the core output.
  [`children()`](https://gillescolling.com/taxify/reference/children.md)
  lists the accepted taxa within a genus or family, for building a
  checklist rather than only validating one.
  [`taxify_candidates()`](https://gillescolling.com/taxify/reference/taxify_candidates.md)
  expands an ambiguous match (`is_ambiguous`) into one row per candidate
  accepted taxon, so homonyms can be resolved by hand.
- [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  gains an `aggregate_fallback` column that makes the default
  `aggregates = "preserve"` accountable. Where a backbone carries no
  dedicated aggregate taxon for an aggregate query, preserve falls back
  to the nominal binomial; that collapse is now flagged (`TRUE` on
  fallback, `FALSE` when the aggregate taxon was matched, `NA` for
  non-aggregate queries and under `collapse`) rather than being silent.
  Only Euro+Med (433 aggregate taxa) and WoRMS (189) carry them, so
  preserve is a no-op for the other backbones – the flag now says so per
  row.
- [`add_kew_sid()`](https://gillescolling.com/taxify/reference/add_kew_sid.md)
  opens the Kew Seed Information Database (SER-SID, CC BY 2.0): seed
  weight (thousand-seed weight over 42,000 species), storage behaviour
  (orthodox/recalcitrant/intermediate), oil and protein content, life
  form, and fruit type, joined on `accepted_name` across 50,146 accepted
  names. Verified end-to-end (*Quercus robur* 3493 g/1000 seeds and
  recalcitrant; *Helianthus annuus* 43.5% seed oil). Its seed weight
  also joins the cross-source `add_trait("seed_mass")` verb as a seventh
  source (a thousand-seed weight in grams equals the per-seed mass in
  mg; grounded at ratio 1.00 against Diaz, BIEN, and AusTraits), roughly
  doubling seed-mass species coverage.
- [`add_edwards_phyto()`](https://gillescolling.com/taxify/reference/add_edwards_phyto.md)
  opens the Edwards et al. (2015) phytoplankton nutrient-utilization
  database (~130 species): Droop/Monod uptake and growth parameters for
  ammonium, nitrate, and phosphorus (`mu`/`k`/`vmax`/`qmin`/`qmax`),
  plus cell volume, carbon content, taxonomic group, and
  marine/freshwater habitat. A curated core attaches by default;
  `cols = "all"` surfaces every uptake parameter. Door-only
  (single-source physiology with no cross-source analogue), so it stays
  out of the
  [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
  verb. Verified end-to-end (*Alexandrium catenella* recovered as a
  marine dinoflagellate).
- Nine new
  [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
  traits covering algae, marine-benthic invertebrates, and octocorals,
  each grounded on its source’s own vocabulary before wiring. Algae
  (AlgaeTraits): `calcification`, `gamete_type`, `algal_life_cycle`
  (dominant ploidy phase), `algal_substrate`. Marine benthos, harmonized
  across two sources (Arctic Traits + New Zealand Trait Database):
  `bioturbation` (Solan/Queiros functional groups), `living_habit`,
  `feeding_guild`. Octocoral (Gomez-Gras et al. 2024):
  `skeletal_rigidity`, `colony_growth_form`. Verified end-to-end
  (Corallina calcified-articulated, Fucus diplontic, Laminaria
  haplodiplontic; the bryozoan Alcyonidium gelatinosum an attached
  suspension-feeder with no bioturbation).
- Seven new single-source
  [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
  traits, each grounded on its source’s own values before wiring:
  `gc_content` (prokaryote genome GC %, Madin et al.
  2020. and `sporulation` (endospore formation, same source), extending
        the prokaryote block; `larval_nutrition` (bee larval food,
        EuPollTrait); `colour_lightness` (beetle body greyness 0-255,
        saproxylic beetle traits, a melanism axis); `cell_surface_area`
        (microalgae, um2, Rimet et al., alongside
        `cell_length`/`cell_width`/`cell_thickness`/`cell_biovolume`);
        `carapace_length` (turtle, mm, TurtleTraits); and
        `parental_care` (fish Balon reproductive guild
        guarder/non-guarder/bearer, Beukhof et al. 2019). Verified
        end-to-end (Thermus aquaticus GC 67%, Bacillus subtilis
        sporulates, leatherback carapace 2.26 m, stickleback a guarder).
        `add_trait("fruit_type")` also gains AusTraits as a third plant
        source.
- Three new
  [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
  traits, each grounded on the source’s own values before wiring:
  `zooxanthellate` (coral symbiotic state, from the Coral Trait Database
  and the octocoral dataset, which share the
  zooxanthellate/azooxanthellate vocabulary), `optimal_growth_ph`
  (prokaryote, from Madin et al. 2020, the pH companion to
  `optimal_growth_temperature`), and `cell_thickness` (microalgae, from
  Rimet et al., alongside the existing
  `cell_length`/`cell_width`/`cell_biovolume`).
- `add_trait("diet_guild")` now also draws on EltonTraits (Wilman et
  al. 2014), extending diet guilds from birds and reptiles to mammals.
  The guild is derived from the ten EltonTraits diet fractions (built
  into `elton_traits.vtr`) and agrees 93% with EltonTraits’ own diet
  classification and 83% with AVONET.
  [`add_elton_traits()`](https://gillescolling.com/taxify/reference/add_elton_traits.md)
  exposes the same `diet_guild` column directly.
- `add_trait("ellenberg_salt")` gains Baseflor as a third source: its
  salinity column is on the same 0-9 Ellenberg scale as FloraWeb and
  Ecoflora (Pearson r = 0.88 on shared species), so it joins them
  without rescaling.
- New
  [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
  traits `egg_length` and `egg_width` (mm) gather reptile, bird, and
  turtle egg dimensions from the Amniote database, ReptTraits, and
  TurtleTraits, which agree to within measurement noise on shared
  species.
- New `add_trait("brain_mass")` (g) coalesces COMBINE with AnimalTraits
  (kg converted to grams), calibrated 1:1 on shared species.
- Wider taxonomic coverage for several life-history traits, each source
  shared-species calibrated before it was added:
  `reproductive_frequency` now spans mammals through reptiles and
  turtles (AnAge, PanTHERIA, ReptTraits, TurtleTraits added);
  `clutch_litter_size` gains turtles (TurtleTraits) and birds
  (Birdbase); `age_at_maturity` gains turtles and fish (TurtleTraits,
  Beukhof); and `longevity` gains fish (Beukhof, whose ~390 yr maximum
  is the Greenland shark).
- `add_trait("pollination_vector")` gains FloraWeb and AusTraits, which
  agree 82-91% with the existing Baseflor and Ecoflora sources on shared
  species. Named insect taxa (bee, beetle, fly, …) resolve to `insect`;
  AusTraits’ coarse `biotic`/`abiotic` and animal (bird, bat) records
  have no single vector in this vocabulary and stay `NA` rather than
  being guessed.
- Six new
  [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
  traits, each numeric source shared-species calibrated (ratio ~1.00)
  against a co-registered source before it was added: `male_maturity`
  (yr; AnAge, Amniote, COMBINE – the male analogue of
  `age_at_maturity`), `incubation_period` (days; Amniote, TurtleTraits
  egg incubation, kept separate from the combined
  `gestation_incubation`), `diet_breadth` (count of dietary categories;
  COMBINE, PanTHERIA, Birdbase), `tongue_length` (mm; Ostwald,
  EuPollTrait bee proboscis), `aspect_ratio` (caudal-fin aspect ratio;
  Beukhof, Quimbayo), and `foraging_mode` (active/ambush/mixed;
  ReptTraits, TurtleTraits).
- `add_trait("diet_guild")` gains TurtleTraits and Blanchard ant diets,
  mapped to the guild vocabulary by ordered regex (compound “omnivorous
  to carnivorous” resolves to its primary guild; ant “predator” to
  carnivore).
- Six more
  [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
  traits: `reproductive_mode` (oviparous/ovoviviparous/ viviparous;
  ReptTraits plus Sharkipedia, whose shark strategies collapse to
  viviparous); the coral-habitat traits `coloniality`, `wave_exposure`,
  and `water_clarity` (Coral Trait DB and octocoral, sharing one
  vocabulary); and `head_length`/`head_width` (mm; amphibian and beetle
  morphometrics). The depth traits `depth_min`/`depth_max` gain coral
  occurrence-depth limits (Coral Trait DB, octocoral) in the same metres
  unit as the fish sources.
- Eleven more
  [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
  traits, including a new prokaryote domain from Madin et al. (2020):
  `gram_stain`, `oxygen_metabolism`, `cell_shape`,
  `optimal_growth_temperature` (deg C), and `genome_size` (bp). Also
  `caudal_fin_shape` (Beukhof + Quimbayo fish fin shape), `voltinism`
  (generations per year; Arthropod Traits + EuPollTrait), `migration`
  (AVONET), `flightless` (BIRDBASE), `venomous` (ReptTraits), and
  `sociality` (EuPollTrait bees). `thermal_max` gains Pottier amphibian
  CTmax on the same degrees-C scale.
- Nine more
  [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
  traits: `wingspan` (mm; LepTraits butterflies, whose source column is
  labelled mm but is actually cm, corrected on the known wingspans of
  monarch, cabbage white, and swallowtail); `leaf_length` and
  `leaf_width` (mm; AusTraits); `fungal_trophic_mode` (FUNGuild and
  FungalTraits); `feeding_mode` and `mouth_position` (fish; Beukhof,
  Quimbayo); `air_breathing` (FishBase); `motility` (prokaryote; Madin);
  and `lecty` (bee pollen host breadth; EuPollTrait).

### Bug fixes

- Static enrichments now refresh their local cache when the source data
  is rebuilt and re-released under the same tag. Previously a
  version-locked enrichment never re-checked, so a cache downloaded
  before a rebuild stayed stale forever (silent all-NA for any newly
  added columns). The manifest now carries a `content_id` (an md5 of the
  built `.vtr`); a static cache is reconciled against it entirely
  offline, re-downloading only when the bytes actually changed. A
  pre-existing cache with no stored id is hashed in place, so an
  unchanged asset is adopted without a download. Fixes stale
  [`add_nesttrait()`](https://gillescolling.com/taxify/reference/add_nesttrait.md)
  nest-modality columns and
  [`add_disperse()`](https://gillescolling.com/taxify/reference/add_disperse.md)
  bin-midpoint columns for anyone who cached those before the rebuild.
  Every enrichment asset now carries a content id, and the same gate is
  extended to backbones (a content id catches a same-tag republish that
  a version bump would miss). The read-only example database and its
  offline fixtures are never touched.
- [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
  now joins genus-keyed sources on `genus`: the ant-diet contribution to
  `diet_guild` (Blanchard) was silently all-NA, and
  `fungal_trophic_mode`’s FungalTraits source likewise. A registry guard
  test now asserts every genus-keyed source is joined correctly.

## taxify 0.3.2

### New features

- New
  [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
  attaches a single trait across every source that carries it,
  reconciling their vocabularies and units. Where each `add_*()` door
  joins one dataset, `add_trait("seed_mass")` gathers the sources: it
  pulls seed mass from Diaz et al. and GIFT and returns both in one unit
  (mg), woodiness from Zanne and GIFT in one vocabulary, and likewise
  plant height and SLA. The default `mode = "coalesce"` adds one value
  per row with the columns that document it – `seed_mass`,
  `seed_mass_unit`, `seed_mass_sources`, and `seed_mass_n` – which keeps
  chained calls tidy; `mode = "wide"` instead gives one harmonized
  column per source (`seed_mass_diaz`, `seed_mass_gift`) to inspect
  agreement and conflict. When sources measure a trait by different
  methods (for example maximum vs fine-root diameter), the value is not
  blended: the most complete source is reported and a
  `seed_mass_caution` column explains the difference.
  [`list_traits()`](https://gillescolling.com/taxify/reference/list_traits.md)
  lists the available traits and
  [`trait_info()`](https://gillescolling.com/taxify/reference/trait_info.md)
  shows a trait’s sources, units, harmonization notes, and cautions. The
  registry ships dozens of traits spanning plant functional and root
  traits, animal body size, life history and morphology, diel activity,
  thermal limits, phenology, indicator values, and conservation status,
  each with a crosswalk grounded on the source values rather than
  assumed.

### Renamed (source-named doors)

- Enrichment doors are named after their source; the trait name is
  reserved for
  [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md).
  `add_woodiness()`, `add_conservation_status()`,
  `add_invasive_status()`, and `add_fish_traits()` are renamed to
  [`add_zanne()`](https://gillescolling.com/taxify/reference/add_zanne.md)
  (Zanne et al. 2014),
  [`add_iucn()`](https://gillescolling.com/taxify/reference/add_iucn.md)
  (IUCN Red List),
  [`add_griis()`](https://gillescolling.com/taxify/reference/add_griis.md)
  (GRIIS), and
  [`add_fishmorph()`](https://gillescolling.com/taxify/reference/add_fishmorph.md)
  (FISHMORPH; also avoids confusion with
  [`add_fishbase()`](https://gillescolling.com/taxify/reference/add_fishbase.md)).
  The old names are removed, not deprecated – they never appeared in a
  release.

- New
  [`add_gift()`](https://gillescolling.com/taxify/reference/add_gift.md)
  joins plant traits from GIFT, the Global Inventory of Floras and
  Traits (Weigelt et al. 2020), by accepted name. GIFT’s API exposes
  only the subset of its data it may redistribute (CC BY 4.0; restricted
  references excluded); taxifydb fetches that subset once at build time
  and it ships as a pre-built `.vtr`, so
  [`add_gift()`](https://gillescolling.com/taxify/reference/add_gift.md)
  joins it offline like every other enrichment – no runtime API calls.
  Choose which traits to attach via `cols=` (any `gift_` column names,
  or `"all"`); the default is a convenient set of well-populated ones
  (woodiness, growth form, life cycle and form, habit flags, height,
  photosynthetic pathway, seed mass, dispersal, flowering months,
  deciduousness, SLA).
  [`gift_traits()`](https://gillescolling.com/taxify/reference/gift_traits.md)
  browses the available columns.

## taxify 0.3.1

### New features

- New `reptiledb` backend: the Reptile Database (Uetz et al.), the
  global taxonomic reference for reptiles (snakes, lizards,
  amphisbaenians, turtles, crocodiles and the tuatara). It carries
  ~12.6k accepted species plus ~34k synonyms with full genus/family
  classification, filling the one vertebrate class the other backbones
  cover only partially. Use it like any backbone:
  `taxify(x, backend = "reptiledb")`. License: CC-BY 4.0.
- New
  [`add_repttraits()`](https://gillescolling.com/taxify/reference/add_repttraits.md)
  joins species-level reptile traits from ReptTraits (Oskyrko et
  al. 2024) by accepted name. Beyond body-size and life-history traits,
  it carries a per-species distribution signal – biogeographic realm,
  elevation range and mean climate – across all reptiles. This replaces
  the earlier `add_lizard_traits()`, which drew on the same ReptTraits
  source but was mislabelled (it covered all reptiles, not lizards) and
  exposed only the morphology columns. License: CC-BY 4.0.
- New
  [`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
  flags probable typos and other anomalies in a name list and returns
  only the anomalous rows, each labelled with what stands out and, where
  known, the name to use instead.
  [`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
  does not match names against backbones itself – that is
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)‘s
  job. On a character vector it runs the checks that need no matching:
  `unknown` (the genus is not in the genus register, the union of all 13
  backbones’ genera, so no backbone recognises it – a real “probably not
  a name”), `near_duplicate` (a near-twin of a more frequent name in the
  same list, computed from the list alone, so it catches typos in names
  no backbone contains), and `outlier_group` (a name whose kingdom group
  is a tiny minority of an otherwise coherent list – the lone animal or
  fungus among plants). To also surface the match-based anomalies, opt
  in with `backbones = TRUE` (matches against every installed backbone,
  listed in the report header) or match yourself first and inspect the
  result – `taxify(x) |> inspect()` – which adds `typo` (fuzzy-corrected
  spelling), `synonym` (outdated name), `ambiguous` (homonym), `case`,
  and the geographic checks `geographic` (a species with no WCVP record
  in a declared `region`/`coords`) and `out_of_range` (no region
  declared, yet the species’ range falls outside the list’s main TDWG
  continents; skipped for globally spread lists). Rows are ordered
  most-notable first and carry a `suggestion`; each gets a `tier`
  describing what it needs, not how bad it is: `unresolved` (no usable
  name), `review` (a name is there but its identity is uncertain), or
  `note` (correct, optional cleanup) – an anomaly may be intended.
  [`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
  is read-only: it never alters the input or applies a correction.
  Narrow with `min_tier`. The list-context labels cannot apply to a
  single name, so
  [`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
  on one name warns.
- [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  gains a `region` argument for geographically constrained fuzzy
  matching. Pass TDWG botanical regions to restrict **fuzzy** candidates
  to species with WCVP records in those regions; exact matches are
  always kept. `region` accepts Level 3 codes (`region = "BGM"`) or
  region names at any level, matched case- and accent-insensitively
  against a bundled WGSRPD crosswalk: a botanical country (`"Belgium"`),
  a Level 2 region (`"Middle Europe"`), or a Level 1 continent
  (`"Europe"`, expanded to all its codes). The new `coords` argument
  takes a `c(lon, lat)` pair or a matrix/data.frame of coordinates and
  maps them to regions by point-in-polygon against the WGSRPD Level 3
  boundaries (downloaded and cached on first use); `region` and `coords`
  are unioned. `coords` also accepts an `sf`/`sfc` object or a `terra`
  `SpatVector` of points (reprojected automatically). The point-in-
  polygon test uses `terra` or `sf` when installed and falls back to a
  native implementation otherwise; the engine can be forced with
  `options(taxify.pip_engine = "terra" | "sf" | "native")`. The filter
  only narrows genuinely ambiguous fuzzy candidates – a candidate is
  dropped only when the same input name has another candidate that is
  in-region or has no WCVP range data – so non-plant matches are never
  affected and a name whose only candidate is out-of-region is still
  returned. The companion `range` argument selects which WCVP statuses
  count as in-region: `"present"` (default, any record), `"native"`, or
  `"introduced"`.
- New
  [`taxify_regions()`](https://gillescolling.com/taxify/reference/taxify_regions.md)
  lists the WGSRPD Level 3 botanical regions (codes and names) used by
  `region` and by
  [`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md),
  with an optional search term.
- Two new backbone backends: `"fishbase"` (FishBase, ~36k accepted fish
  species) and `"sealifebase"` (SeaLifeBase, ~100k accepted non-fish
  aquatic species). Both resolve synonyms to their accepted names and
  carry kingdom / phylum / class / order classification. Use them like
  any other backbone, e.g.
  `taxify("Gadus morhua", backend = "fishbase")`.
- [`add_sealifebase()`](https://gillescolling.com/taxify/reference/add_sealifebase.md)
  joins SeaLifeBase morphological and ecological traits (body length,
  mass, trophic level, depth range, vulnerability, habitat, commercial
  importance) to a
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  result. It is the non-fish companion to
  [`add_fishbase()`](https://gillescolling.com/taxify/reference/add_fishbase.md).
- [`add_groot()`](https://gillescolling.com/taxify/reference/add_groot.md)
  joins species-level root traits from the Global Root Traits (GRooT)
  database: root diameter, specific root length, tissue density, N and C
  concentration, root mass fraction, lateral spread, mycorrhizal
  colonization and rooting depth (per-species means for 6,154 vascular
  plant species).

## taxify 0.3.0

### Breaking changes

- `add_qualifier_info()` has been removed.
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) now
  reports the qualifier natively (see New features), so a separate
  parsing pass is no longer needed. Replace
  `taxify(x) |> add_qualifier_info()` with `taxify(x)`. Note the integer
  `qualifier_position` (a character index) is replaced by a two-value
  `"genus"` / `"species"` placement.

### New features

- Species aggregates are now handled as a distinct concept.
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  gains an `aggregates` argument, default `"preserve"`: an aggregate
  name (`"... agg."`, `"... s.l."`) matches the backbone’s aggregate
  taxon where one exists (for example in Euro+Med and WoRMS), otherwise
  it falls back to the binomial species. `aggregates = "collapse"` keeps
  the previous behaviour of stripping the marker and matching the
  binomial.
- [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  output carries two new columns. `qualifier` is the canonical taxonomic
  qualifier with spelling variants folded to one token (`"aggr."`,
  `"agg"` and `"sensu lato"` map to `"agg."` / `"s.l."`).
  `qualifier_position` is `"genus"` for a leading prefix
  (`"Cf. Pinus sylvestris"`) and `"species"` for an inline or trailing
  qualifier (`"Pinus cf. sylvestris"`, `"Rubus fruticosus agg."`).
- Trait enrichment is aggregate-aware. Traits inherit down the taxonomic
  hierarchy: a species query receives an aggregate-level trait when no
  species-level value exists (for example EIVE indicator values keyed
  only at `"... aggr."`), and an aggregate query reaches the
  aggregate-level trait. A single species’ trait is never propagated up
  to the aggregate. Set `options(taxify.trait_provenance = TRUE)` to add
  a `<enrichment>_inherited` flag marking the inherited values.
- Exported
  [`normalize_aggregate_name()`](https://gillescolling.com/taxify/reference/normalize_aggregate_name.md)
  and
  [`is_aggregate_name()`](https://gillescolling.com/taxify/reference/is_aggregate_name.md)
  (build-time helpers) so the taxifydb build pipeline folds every
  backbone and enrichment aggregate marker (`agg`, `aggr.`, `-agg`,
  `s.l.`, `sensu lato`, `coll.`, and aggregate ranks such as
  `SPECIES AGGREGATE`) to one canonical `aggr.` form. The runtime and
  build sides therefore recognize aggregates uniformly across all
  backbones.

## taxify 0.2.15

### Bug fixes

- [`summary()`](https://rdrr.io/r/base/summary.html) now counts
  abbreviated-genus matches (`match_type == "abbrev"`,
  e.g. `"Q. robur"`). Previously these were resolved correctly in the
  result but omitted from the `matched` total and its breakdown, so the
  digest under-reported the number of matched names. The `matched` line
  now reads `(exact, case-insensitive, fuzzy, abbrev)`, and
  `match_tally` carries an `abbrev` count.

### Documentation

- Rewrote the “Getting started” vignette as a demo-first walkthrough:
  the one-call example, four canvas animations (matching pipeline, genus
  blocking, the WorldFlora speed benchmark, and the enrichment hub), and
  a worked trait-stacking analysis. Each section links to the dedicated
  vignette for depth.
- The enrichments vignette now documents
  [`add_fungalroot()`](https://gillescolling.com/taxify/reference/add_fungalroot.md)
  (genus-level mycorrhizal type), including the genus-keyed join and the
  type vocabulary, and stacks it into the European and global
  vascular-plant guidance.

## taxify 0.2.14

### New features

- [`add_fungalroot()`](https://gillescolling.com/taxify/reference/add_fungalroot.md)
  joins genus-level mycorrhizal type from the FungalRoot database
  (Soudzilovskaia et al. 2020, GBIF <doi:10.15468/a7ujmj>, CC BY-NC 4.0)
  to a
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  result. Because mycorrhizal type is conserved at the genus level, the
  join is on `genus`, so any species in a covered genus is annotated
  with `mycorrhizal_type` (`AM`, `EcM`, `ErM`, `OM`, `NM`, the dual
  types, `Other`, or `uncertain`), `mycorrhizal_status`, and the
  supporting record count. Plant genera only.

## taxify 0.2.13

### Bug fixes

- A leading genus-level `Cf.` prefix (e.g. `"Cf. Pinus sylvestris"`) is
  now recorded as the `cf.` qualifier by `clean_names()`, `clean_one()`,
  and `add_qualifier_info()`. Previously the prefix was stripped before
  matching but the qualifier was lost, so only inline `cf.`
  (e.g. `"Pinus cf. sylvestris"`) was reported. `add_qualifier_info()`
  now also matches the prefix case-insensitively and reports
  `qualifier_position = 1`.

## taxify 0.2.12

CRAN release: 2026-06-30

### New features

- [`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md)
  can now be redirected with the `taxify.data_dir` option or the
  `TAXIFY_DATA_DIR` environment variable, so the cache location is
  configurable (shared caches, scratch directories, the bundled example
  data).
- [`taxify_example_data()`](https://gillescolling.com/taxify/reference/taxify_example_data.md)
  returns the path to a small bundled example database (a handful of
  species per backbone plus matching enrichment tables). Setting
  `options(taxify.data_dir = taxify_example_data())` lets matching and
  enrichment run fully offline.

### Documentation

- Examples now run against the bundled example database instead of being
  wrapped in `\dontrun{}`. Only
  [`add_pignatti()`](https://gillescolling.com/taxify/reference/add_pignatti.md)
  (fetched live via TR8) and
  [`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md)
  (reads the online manifest) remain in `\donttest{}`.

## taxify 0.2.11

### New features

- [`add_floraweb()`](https://gillescolling.com/taxify/reference/add_floraweb.md)
  joins German-flora plant traits from FloraWeb (the live BfN portal
  carrying the BiolFlor data of Klotz, Kuehn & Durka 2002, plus
  Rothmaler morphology and Ellenberg indicator values). It bundles the
  full per-species trait profile – morphology, reproductive biology, the
  nine Ellenberg indicator values, ploidy and chromosome number, and
  chorological distribution (59 `_de` columns) – as a pre-built dataset,
  so it works offline.

### Changes

- [`add_ecoflora()`](https://gillescolling.com/taxify/reference/add_ecoflora.md)
  now joins a bundled, pre-built Ecoflora dataset (18 `_uk` columns:
  canopy height, leaf traits, life form, flowering phenology,
  pollination, seed weight, and British-calibrated Ellenberg values)
  instead of fetching live through TR8. It works offline and returns the
  full trait set rather than the previous five columns.

- [`add_pignatti()`](https://gillescolling.com/taxify/reference/add_pignatti.md)
  remains an on-demand TR8 source: its values are from a copyrighted
  publication and cannot be redistributed.

## taxify 0.2.10

### New features

- [`add_ecoflora()`](https://gillescolling.com/taxify/reference/add_ecoflora.md),
  `add_biolflor()`, and
  [`add_pignatti()`](https://gillescolling.com/taxify/reference/add_pignatti.md)
  join plant traits that taxify does not ship as a pre-built dataset,
  accessing them on demand through the suggested TR8 package on your own
  machine; taxify redistributes nothing. The reasons differ by source:
  [`add_ecoflora()`](https://gillescolling.com/taxify/reference/add_ecoflora.md)
  adds British flowering months, pollen vector, life form, and leaf
  longevity (CC BY-NC-SA, which would allow redistribution, but
  ecoflora.org.uk has no bulk download, so it is fetched live per
  species); `add_biolflor()` adds Grime CSR strategy type, breeding
  system, pollen vector, life form, life span, and apomixis (usable with
  acknowledgement + citation per the BioFresh metadata statement, but no
  bulk copy is obtainable while the UFZ site is offline, so fetched
  live);
  [`add_pignatti()`](https://gillescolling.com/taxify/reference/add_pignatti.md)
  adds Italian Ellenberg-type indicator values, life form, and chorotype
  (copyrighted; read from the copy bundled in TR8, which TR8
  redistributes, not taxify; works offline). Columns are region-suffixed
  (`_uk`/`_de`/`_it`) so they never collide with
  [`add_baseflor()`](https://gillescolling.com/taxify/reference/add_baseflor.md).
  TR8 is a Suggests dependency. If a live source (Ecoflora, BiolFlor) is
  unreachable the call errors rather than attaching silent NA.

## taxify 0.2.9

### New features

- [`add_baseflor()`](https://gillescolling.com/taxify/reference/add_baseflor.md)
  joins plant traits from Baseflor (Programme Catminat, Julve 1998 ff.;
  ODbL 1.0 / CC BY-SA 2.0) to a
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  result. It covers ~7,000 vascular plant taxa of France and
  neighbouring regions and adds flowering phenology
  (`flower_begin_month`, `flower_end_month`), pollination vector,
  dispersal mode, breeding system, flower colour, fruit type, woody
  growth form, and the continentality and salinity indicator-value axes
  absent from EIVE. The enrichment is registered in the manifest
  ([`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md))
  with a pre-built `.vtr`; light/temperature/moisture/reaction/nutrient
  axes are left to
  [`add_eive()`](https://gillescolling.com/taxify/reference/add_eive.md)
  and Raunkiaer life form to
  [`add_leda()`](https://gillescolling.com/taxify/reference/add_leda.md).

## taxify 0.2.8

### Internal

- Added an end-to-end regression test
  (`tests/e2e/test-e2e-enrichment.R`) for the enrichment join fixed in
  0.2.5 ([\#1](https://github.com/gcol33/taxify/issues/1)). It checks
  that `add_conservation_status()`,
  [`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md),
  and `add_woodiness()` attach each value to the row’s own accepted
  taxon, stay invariant to batch composition and order, and land
  documented values on the correct species.

## taxify 0.2.7

### New features

- Abbreviated-genus names such as `"Q. robur"` now resolve. A matching
  pass restricts the backbone to rows whose genus starts with the given
  initial and whose specific epithet matches, resolving only when that
  is unique. When two or more genera sharing the initial also share the
  epithet the abbreviation is ambiguous: the row is left unmatched with
  `is_ambiguous = TRUE` and the conflicting accepted IDs in
  `ambiguous_targets`, rather than guessing a genus. A genus spelled out
  in full elsewhere in the same input takes precedence (the convention
  of abbreviating after first mention). Resolved rows carry
  `match_type = "abbrev"`.

## taxify 0.2.6

### New features

- New `accepted_authorship` output column: the authorship of the
  resolved accepted name. For a synonym match, `authorship` holds the
  synonym’s own author while `accepted_authorship` holds the accepted
  name’s author, so `accepted_name` and `accepted_authorship` together
  form the accepted taxon’s full citation. Backbones that carry
  authorship populate it; sources without authorship (NCBI, OTT) return
  `NA`.

### Bug fixes

- [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) no
  longer errors with “replacement has length zero” for backbones whose
  `.meta` sidecar records the build date as `build_date` (the current
  taxifydb build format) rather than `download_date`. Backbone metadata
  now reads both layouts and version formatting tolerates a missing
  date. This previously broke matching against the WoRMS and Open Tree
  of Life backbones.

### Internal

- Declared the companion build package taxifydb in
  `Additional_repositories` (<https://gcol33.r-universe.dev>), so its
  location is discoverable as required for a Suggests dependency outside
  the mainstream repositories.

## taxify 0.2.5

### Bug fixes

- [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) no
  longer errors with “incorrect number of dimensions” when the genus
  register is present but the backend-coverage file is not (the state on
  a clean install before any coverage download, and during package
  checks). An early [`return()`](https://rdrr.io/r/base/function.html)
  evaluated inside a
  [`tryCatch()`](https://rdrr.io/r/base/conditions.html) expression
  returned `NULL` from the pre-filter, which `$<-` then turned into a
  list; the out-of-scope pre-filter now resolves missing coverage to a
  no-op and preserves the result data frame.

- Replaced non-ASCII characters in roxygen documentation with ASCII
  equivalents so the PDF reference manual builds under LaTeX.

## taxify 0.2.4

### Bug fixes

- Ambiguous homonym synonyms now resolve to the epithet-preserving
  accepted name (the homotypic basionym) instead of an arbitrary
  lowest-id candidate. `taxify("Pinus abies")` resolves to *Picea abies*
  (not *Picea polita*), and the spurious `is_ambiguous` flag is cleared
  when one candidate keeps the specific epithet
  ([\#2](https://github.com/gcol33/taxify/issues/2)). Genuinely
  ambiguous names (no candidate, or several, preserving the epithet) are
  still flagged.

- Silenced tidyselect deprecation warnings emitted during fuzzy
  matching.

### Internal

- [`score_candidates()`](https://gillescolling.com/taxify/reference/score_candidates.md)
  is exported (kept internal in the reference index) so the companion
  `taxifydb` build pipeline can collapse each backbone key to the single
  accepted name
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  resolves it to. This corrects enrichment joins that previously landed
  trait/status values on within-genus neighbours
  ([\#1](https://github.com/gcol33/taxify/issues/1)); the fix reaches
  users through rebuilt enrichment data.
