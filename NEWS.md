# taxify (development version)

## New features

* New `reptiledb` backend: the Reptile Database (Uetz et al.), the global
  taxonomic reference for reptiles (snakes, lizards, amphisbaenians, turtles,
  crocodiles and the tuatara). It carries ~12.6k accepted species plus ~34k
  synonyms with full genus/family classification, filling the one vertebrate
  class the other backbones cover only partially. Use it like any backbone:
  `taxify(x, backend = "reptiledb")`. License: CC-BY 4.0.
* New `add_repttraits()` joins species-level reptile traits from ReptTraits
  (Oskyrko et al. 2024) by accepted name. Beyond body-size and life-history
  traits, it carries a per-species distribution signal -- biogeographic realm,
  elevation range and mean climate -- across all reptiles. This replaces the
  earlier `add_lizard_traits()`, which drew on the same ReptTraits source but
  was mislabelled (it covered all reptiles, not lizards) and exposed only the
  morphology columns. License: CC-BY 4.0.
* New `inspect()` flags probable typos and other anomalies in a name list and
  returns only the anomalous rows, each labelled with what stands out and, where
  known, the name to use instead. `inspect()` does not match names against
  backbones itself -- that is `taxify()`'s job. On a character vector it runs the
  checks that need no matching: `unknown` (the genus is not in the genus register,
  the union of all 13 backbones' genera, so no backbone recognises it -- a real
  "probably not a name"), `near_duplicate` (a near-twin of a more frequent name in
  the same list, computed from the list alone, so it catches typos in names no
  backbone contains), and `outlier_group` (a name whose kingdom group is a tiny
  minority of an otherwise coherent list -- the lone animal or fungus among
  plants). To also surface the match-based anomalies, opt in with
  `backbones = TRUE` (matches against every installed backbone, listed in the
  report header) or match yourself first and inspect the result --
  `taxify(x) |> inspect()` -- which adds `typo` (fuzzy-corrected
  spelling), `synonym` (outdated name), `ambiguous` (homonym), `case`, and the
  geographic checks `geographic` (a species with no WCVP record in a declared
  `region`/`coords`) and `out_of_range` (no region declared, yet the species'
  range falls outside the list's main TDWG continents; skipped for globally
  spread lists). Rows are ordered most-notable first and carry a `suggestion`;
  each gets a `tier` describing what it needs, not how bad it is: `unresolved`
  (no usable name), `review` (a name is there but its identity is uncertain), or
  `note` (correct, optional cleanup) -- an anomaly may be intended.
  `inspect()` is read-only: it never alters the input or applies a correction.
  Narrow with `min_tier`. The list-context labels cannot apply to a single name,
  so `inspect()` on one name warns.
* `taxify()` gains a `region` argument for geographically constrained fuzzy
  matching. Pass TDWG botanical regions to restrict **fuzzy** candidates to
  species with WCVP records in those regions; exact matches are always kept.
  `region` accepts Level 3 codes (`region = "BGM"`) or region names at any
  level, matched case- and accent-insensitively against a bundled WGSRPD
  crosswalk: a botanical country (`"Belgium"`), a Level 2 region
  (`"Middle Europe"`), or a Level 1 continent (`"Europe"`, expanded to all its
  codes). The new `coords` argument takes a `c(lon, lat)` pair or a
  matrix/data.frame of coordinates and maps them to regions by point-in-polygon
  against the WGSRPD Level 3 boundaries (downloaded and cached on first use);
  `region` and `coords` are unioned. `coords` also accepts an `sf`/`sfc` object
  or a `terra` `SpatVector` of points (reprojected automatically). The point-in-
  polygon test uses `terra` or `sf` when installed and falls back to a native
  implementation otherwise; the engine can be forced with
  `options(taxify.pip_engine = "terra" | "sf" | "native")`. The filter only narrows genuinely
  ambiguous fuzzy candidates -- a candidate is dropped only when the same input
  name has another candidate that is in-region or has no WCVP range data -- so
  non-plant matches are never affected and a name whose only candidate is
  out-of-region is still returned. The companion `range` argument selects which
  WCVP statuses count as in-region: `"present"` (default, any record),
  `"native"`, or `"introduced"`.
* New `taxify_regions()` lists the WGSRPD Level 3 botanical regions (codes and
  names) used by `region` and by `add_wcvp()`, with an optional search term.
* Two new backbone backends: `"fishbase"` (FishBase, ~36k accepted fish
  species) and `"sealifebase"` (SeaLifeBase, ~100k accepted non-fish aquatic
  species). Both resolve synonyms to their accepted names and carry kingdom /
  phylum / class / order classification. Use them like any other backbone, e.g.
  `taxify("Gadus morhua", backend = "fishbase")`.
* `add_sealifebase()` joins SeaLifeBase morphological and ecological traits
  (body length, mass, trophic level, depth range, vulnerability, habitat,
  commercial importance) to a `taxify()` result. It is the non-fish companion
  to `add_fishbase()`.
* `add_groot()` joins species-level root traits from the Global Root Traits
  (GRooT) database: root diameter, specific root length, tissue density, N and
  C concentration, root mass fraction, lateral spread, mycorrhizal colonization
  and rooting depth (per-species means for 6,154 vascular plant species).

# taxify 0.3.0

## Breaking changes

* `add_qualifier_info()` has been removed. `taxify()` now reports the qualifier
  natively (see New features), so a separate parsing pass is no longer needed.
  Replace `taxify(x) |> add_qualifier_info()` with `taxify(x)`. Note the integer
  `qualifier_position` (a character index) is replaced by a two-value
  `"genus"` / `"species"` placement.

## New features

* Species aggregates are now handled as a distinct concept. `taxify()` gains an
  `aggregates` argument, default `"preserve"`: an aggregate name (`"... agg."`,
  `"... s.l."`) matches the backbone's aggregate taxon where one exists (for
  example in Euro+Med and WoRMS), otherwise it falls back to the binomial
  species. `aggregates = "collapse"` keeps the previous behaviour of stripping
  the marker and matching the binomial.
* `taxify()` output carries two new columns. `qualifier` is the canonical
  taxonomic qualifier with spelling variants folded to one token (`"aggr."`,
  `"agg"` and `"sensu lato"` map to `"agg."` / `"s.l."`). `qualifier_position`
  is `"genus"` for a leading prefix (`"Cf. Pinus sylvestris"`) and `"species"`
  for an inline or trailing qualifier (`"Pinus cf. sylvestris"`,
  `"Rubus fruticosus agg."`).
* Trait enrichment is aggregate-aware. Traits inherit down the taxonomic
  hierarchy: a species query receives an aggregate-level trait when no
  species-level value exists (for example EIVE indicator values keyed only at
  `"... aggr."`), and an aggregate query reaches the aggregate-level trait.
  A single species' trait is never propagated up to the aggregate. Set
  `options(taxify.trait_provenance = TRUE)` to add a `<enrichment>_inherited`
  flag marking the inherited values.
* Exported `normalize_aggregate_name()` and `is_aggregate_name()` (build-time
  helpers) so the taxifydb build pipeline folds every backbone and enrichment
  aggregate marker (`agg`, `aggr.`, `-agg`, `s.l.`, `sensu lato`, `coll.`, and
  aggregate ranks such as `SPECIES AGGREGATE`) to one canonical `aggr.` form.
  The runtime and build sides therefore recognize aggregates uniformly across
  all backbones.

# taxify 0.2.15

## Bug fixes

* `summary()` now counts abbreviated-genus matches (`match_type == "abbrev"`,
  e.g. `"Q. robur"`). Previously these were resolved correctly in the result but
  omitted from the `matched` total and its breakdown, so the digest under-reported
  the number of matched names. The `matched` line now reads
  `(exact, case-insensitive, fuzzy, abbrev)`, and `match_tally` carries an
  `abbrev` count.

## Documentation

* Rewrote the "Getting started" vignette as a demo-first walkthrough: the
  one-call example, four canvas animations (matching pipeline, genus blocking,
  the WorldFlora speed benchmark, and the enrichment hub), and a worked
  trait-stacking analysis. Each section links to the dedicated vignette for
  depth.
* The enrichments vignette now documents `add_fungalroot()` (genus-level
  mycorrhizal type), including the genus-keyed join and the type vocabulary,
  and stacks it into the European and global vascular-plant guidance.

# taxify 0.2.14

## New features

* `add_fungalroot()` joins genus-level mycorrhizal type from the FungalRoot
  database (Soudzilovskaia et al. 2020, GBIF doi:10.15468/a7ujmj, CC BY-NC 4.0)
  to a `taxify()` result. Because mycorrhizal type is conserved at the genus
  level, the join is on `genus`, so any species in a covered genus is annotated
  with `mycorrhizal_type` (`AM`, `EcM`, `ErM`, `OM`, `NM`, the dual types,
  `Other`, or `uncertain`), `mycorrhizal_status`, and the supporting record
  count. Plant genera only.

# taxify 0.2.13

## Bug fixes

* A leading genus-level `Cf.` prefix (e.g. `"Cf. Pinus sylvestris"`) is now
  recorded as the `cf.` qualifier by `clean_names()`, `clean_one()`, and
  `add_qualifier_info()`. Previously the prefix was stripped before matching
  but the qualifier was lost, so only inline `cf.` (e.g. `"Pinus cf.
  sylvestris"`) was reported. `add_qualifier_info()` now also matches the
  prefix case-insensitively and reports `qualifier_position = 1`.

# taxify 0.2.12

## New features

* `taxify_data_dir()` can now be redirected with the `taxify.data_dir` option
  or the `TAXIFY_DATA_DIR` environment variable, so the cache location is
  configurable (shared caches, scratch directories, the bundled example data).
* `taxify_example_data()` returns the path to a small bundled example database
  (a handful of species per backbone plus matching enrichment tables). Setting
  `options(taxify.data_dir = taxify_example_data())` lets matching and
  enrichment run fully offline.

## Documentation

* Examples now run against the bundled example database instead of being
  wrapped in `\dontrun{}`. Only `add_pignatti()` (fetched live via TR8) and
  `list_enrichments()` (reads the online manifest) remain in `\donttest{}`.

# taxify 0.2.11

## New features

* `add_floraweb()` joins German-flora plant traits from FloraWeb (the live BfN
  portal carrying the BiolFlor data of Klotz, Kuehn & Durka 2002, plus
  Rothmaler morphology and Ellenberg indicator values). It bundles the full
  per-species trait profile -- morphology, reproductive biology, the nine
  Ellenberg indicator values, ploidy and chromosome number, and chorological
  distribution (59 `_de` columns) -- as a pre-built dataset, so it works
  offline.

## Changes

* `add_ecoflora()` now joins a bundled, pre-built Ecoflora dataset (18 `_uk`
  columns: canopy height, leaf traits, life form, flowering phenology,
  pollination, seed weight, and British-calibrated Ellenberg values) instead
  of fetching live through TR8. It works offline and returns the full trait
  set rather than the previous five columns.

* `add_pignatti()` remains an on-demand TR8 source: its values are from a
  copyrighted publication and cannot be redistributed.


# taxify 0.2.10

## New features

* `add_ecoflora()`, `add_biolflor()`, and `add_pignatti()` join plant traits
  that taxify does not ship as a pre-built dataset, accessing them on demand
  through the suggested TR8 package on your own machine; taxify redistributes
  nothing. The reasons differ by source: `add_ecoflora()` adds British
  flowering months, pollen vector, life form, and leaf longevity (CC BY-NC-SA,
  which would allow redistribution, but ecoflora.org.uk has no bulk download,
  so it is fetched live per species); `add_biolflor()` adds Grime CSR strategy
  type, breeding system, pollen vector, life form, life span, and apomixis
  (usable with acknowledgement + citation per the BioFresh metadata statement,
  but no bulk copy is obtainable while the UFZ site is offline, so fetched
  live); `add_pignatti()` adds Italian Ellenberg-type indicator values, life
  form, and chorotype (copyrighted; read from the copy bundled in TR8, which
  TR8 redistributes, not taxify; works offline). Columns are region-suffixed
  (`_uk`/`_de`/`_it`) so they never collide with `add_baseflor()`. TR8 is a
  Suggests dependency. If a live source (Ecoflora, BiolFlor) is unreachable the
  call errors rather than attaching silent NA.

# taxify 0.2.9

## New features

* `add_baseflor()` joins plant traits from Baseflor (Programme Catminat,
  Julve 1998 ff.; ODbL 1.0 / CC BY-SA 2.0) to a `taxify()` result. It covers
  ~7,000 vascular plant taxa of France and neighbouring regions and adds
  flowering phenology (`flower_begin_month`, `flower_end_month`), pollination
  vector, dispersal mode, breeding system, flower colour, fruit type, woody
  growth form, and the continentality and salinity indicator-value axes absent
  from EIVE. The enrichment is registered in the manifest (`list_enrichments()`)
  with a pre-built `.vtr`; light/temperature/moisture/reaction/nutrient axes
  are left to `add_eive()` and Raunkiaer life form to `add_leda()`.

# taxify 0.2.8

## Internal

* Added an end-to-end regression test (`tests/e2e/test-e2e-enrichment.R`) for
  the enrichment join fixed in 0.2.5 (#1). It checks that
  `add_conservation_status()`, `add_common_names()`, and `add_woodiness()`
  attach each value to the row's own accepted taxon, stay invariant to batch
  composition and order, and land documented values on the correct species.

# taxify 0.2.7

## New features

* Abbreviated-genus names such as `"Q. robur"` now resolve. A matching pass
  restricts the backbone to rows whose genus starts with the given initial and
  whose specific epithet matches, resolving only when that is unique. When two
  or more genera sharing the initial also share the epithet the abbreviation is
  ambiguous: the row is left unmatched with `is_ambiguous = TRUE` and the
  conflicting accepted IDs in `ambiguous_targets`, rather than guessing a genus.
  A genus spelled out in full elsewhere in the same input takes precedence
  (the convention of abbreviating after first mention). Resolved rows carry
  `match_type = "abbrev"`.


# taxify 0.2.6

## New features

* New `accepted_authorship` output column: the authorship of the resolved
  accepted name. For a synonym match, `authorship` holds the synonym's own
  author while `accepted_authorship` holds the accepted name's author, so
  `accepted_name` and `accepted_authorship` together form the accepted taxon's
  full citation. Backbones that carry authorship populate it; sources without
  authorship (NCBI, OTT) return `NA`.

## Bug fixes

* `taxify()` no longer errors with "replacement has length zero" for backbones
  whose `.meta` sidecar records the build date as `build_date` (the current
  taxifydb build format) rather than `download_date`. Backbone metadata now
  reads both layouts and version formatting tolerates a missing date. This
  previously broke matching against the WoRMS and Open Tree of Life backbones.

## Internal

* Declared the companion build package taxifydb in `Additional_repositories`
  (https://gcol33.r-universe.dev), so its location is discoverable as required
  for a Suggests dependency outside the mainstream repositories.


# taxify 0.2.5

## Bug fixes

* `taxify()` no longer errors with "incorrect number of dimensions" when the
  genus register is present but the backend-coverage file is not (the state on
  a clean install before any coverage download, and during package checks). An
  early `return()` evaluated inside a `tryCatch()` expression returned `NULL`
  from the pre-filter, which `$<-` then turned into a list; the out-of-scope
  pre-filter now resolves missing coverage to a no-op and preserves the result
  data frame.

* Replaced non-ASCII characters in roxygen documentation with ASCII equivalents
  so the PDF reference manual builds under LaTeX.


# taxify 0.2.4

## Bug fixes

* Ambiguous homonym synonyms now resolve to the epithet-preserving accepted
  name (the homotypic basionym) instead of an arbitrary lowest-id candidate.
  `taxify("Pinus abies")` resolves to *Picea abies* (not *Picea polita*), and
  the spurious `is_ambiguous` flag is cleared when one candidate keeps the
  specific epithet (#2). Genuinely ambiguous names (no candidate, or several,
  preserving the epithet) are still flagged.

* Silenced tidyselect deprecation warnings emitted during fuzzy matching.

## Internal

* `score_candidates()` is exported (kept internal in the reference index) so the
  companion `taxifydb` build pipeline can collapse each backbone key to the
  single accepted name `taxify()` resolves it to. This corrects enrichment
  joins that previously landed trait/status values on within-genus neighbours
  (#1); the fix reaches users through rebuilt enrichment data.
