# taxify 0.4.3

* Bundled enrichment data now resolves taxonomic names across all fifteen
  backbones during the build, up from the seven broadest. An enrichment value
  keyed to a name accepted only by a domain-specific backbone (Euro+Med,
  Species Fungorum, AlgaeBase, FishBase, SeaLifeBase, Reptile Database, LCVP,
  or WCVP) now joins a `taxify()` result that resolved through that backbone,
  instead of falling through. The manifest points at the rebuilt enrichment
  release.

* Documentation: corrected references that presented WFO as the default
  backbone. The default is COL, matched first in the fallback chain, and the
  first `taxify()` call installs the default set COL, GBIF, and ITIS.

# taxify 0.4.2

* Removed `taxify_download_vtr()`, the deprecated alias of `taxify_download()`.
  Use `taxify_download()`.

* Slimmed the bundled example database. The BIEN and AusTraits example `.vtr`
  fixtures were the full production tables (116k and 35k rows); they now carry
  only the few dozen species the offline examples and `add_trait()` tests use.
  Installed size drops from ~9.9 MB to ~3.2 MB. The offline examples and test
  coverage are unchanged.

# taxify 0.4.1

* `add_hybrid_info()` gains `hybrid_parent_1_id` / `hybrid_parent_2_id`: the
  backbone `taxon_id` of the accepted taxon each parent of a hybrid formula
  resolves to. An unresolved hybrid formula has no single backbone record, so
  the result's own `taxon_id` is `NA`; the two component ids now travel in these
  columns, each ready to pass straight to `id2name()`.

# taxify 0.4.0

## Breaking: `backend` is renamed to `backbone` throughout the API (issue #24)

* Two real concepts had one name. A `backbone` is a data source and its `.vtr`
  file; a `backend` is the `taxify_backend` S3 handle that knows how to read
  one. The name-string layer conflated them -- `install_backbones(backends =)`
  and `backbone_path(backend)` collided inside single lines. `backbone` now
  names the data source and its name string everywhere, `backend` names the S3
  handle only, and `resolve_backend()` is the single crossing point between
  them.

* **This breaks existing code, with no aliases.** `taxify(backend = "wfo")` is
  now `taxify(backbone = "wfo")`, and the same for `synonyms()`, `children()`,
  `upstream()`, `downstream()`, `id2name()`, `reconcile()`, `comm2sci()`,
  `sci2comm()`, `class2tree()`, `lowest_common()` and `taxify_download()`.
  `install_backbones(backends =)` becomes `install_backbones(backbones =)`.

* The `backend` output column is renamed to `backbone` in `taxify()`,
  `taxify_long()`, `reconcile()`, `inspect()` and `taxify_register_coverage()`.
  A lockfile's `backends` key becomes `backbones`, so a lockfile written before
  this release no longer loads.

* Three other conflations went with it. `comm2sci()` and `sci2comm()` returned
  the accepted name as `scientific_name`; it is `accepted_name`, the name every
  other verb uses. Their `query` column and `parse_name()`'s `input` and
  `upstream()`'s `query` are all the caller's input string, so they are all
  `input_name` now. `register_enrichment()`'s `source` argument is the
  human-readable description, which `enrich_simple()` already called
  `source_label`; the key is `name`.

* `bb_path` and `vtr_path` named the same value; it is `vtr_path` everywhere.

* Not renamed: the `backends` key inside `inst/manifest.json`, and the
  `backend` column inside the published `backend_coverage.vtr`. Both are
  serialized schemas that `taxifydb` writes and taxify only reads, so renaming
  them is a coordinated release rather than a rename. The runtime translates at
  the boundary, and `taxify_register_coverage()` reports `backbone`.

## An example fixture was keyed at the wrong level

* `add_fungal_traits()` joins on `genus`, but the bundled example database
  shipped a `fungal_traits.vtr` keyed on `canonical_name` with no `genus`
  column, so its own documented example errored. The fixture is rebuilt from
  the released asset at genus grain.

## The performance and size figures are measured, and generated from the manifest (issue #19)

* The README's headline "1,862x faster than WorldFlora" had nothing in the
  repository behind it, and neither did the memory figures in the large-scale
  vignette. Both are now produced by committed scripts --
  `scripts/benchmark-worldflora.R` and `scripts/benchmark-memory.R` -- which
  write their runs to JSON alongside package versions and the backbone
  snapshot. On 1,000 names that each carry a one-character typo, taxify takes
  18.8 s against WorldFlora's 4,192 s, both reading the same Zenodo Darwin Core
  archive; exact matching is 2.2 s against 17.1 s.

* The invented console output is gone from the large-scale vignette. The timing
  chunks show how to measure rather than asserting a number that was never run,
  and the memory section reports resident set size, which is what a backbone
  actually costs -- `gc()` sees only a fraction of it, since vectra reads the
  `.vtr` through the operating system. Opening a backbone costs 1.8 to 2.2 times
  its `.vtr` size, and a 5,000-name all-fuzzy pass adds 1.3 GB against WFO.

* Backbone row counts, download sizes and the enrichment count are generated
  from `inst/manifest.json` and taxify's own backbone registry, between HTML
  comment markers, by `scripts/sync-readme-stats.R`. The hand-kept copies had
  drifted up to 4.1x (WFO listed at 400k names against 1.6M, its download at
  ~120 MB against 797 MB). A `manifest-docs` workflow fails if a block goes
  stale.

* Smaller: the `taxify()` match-type list in the README was missing
  `hybrid_formula`, and the Euro+Med row count in the backends vignette still
  described the 2020 build.

## The genus register is downloaded, not built locally (issue #21)

* The register carries the `kingdom_group`, `taxon_group` and `life_form` that
  `taxify()` reports, and it was built on each machine from whichever backbones
  that machine happened to have installed. Two users running identical code
  therefore got different labels for the same name. `genus_register.vtr` and
  `backend_coverage.vtr` are now built by `taxifydb` over a fixed backbone set,
  published, and resolved through the same chain as any other asset: disk,
  download, then a local build. Every install reads the same 496,127 genera.

* The build pipeline itself -- the thirteen genus extractors, kingdom
  normalization and inference, the GBIF hierarchy walk, and the family
  life-form table -- moved to `taxifydb` (about 1,900 lines).
  `taxify_build_register()` remains as an escape hatch that delegates there,
  and `taxify_download("register")` fetches the published pair.

* The register now lives at `<data_dir>/genus_register/latest/` rather than
  `<data_dir>/unified/latest/`, so it follows the same versioned layout as
  every backbone and picks up a new release through the usual version check.

## Offline mode (`options(taxify.offline = TRUE)`)

* Confines taxify to what is on disk plus the bundled manifest: no version
  checks, no downloads, no build-from-source that would fetch a raw dataset. A
  `file://` manifest URL still resolves. The test suite runs under it, which is
  what makes a run independent of any release published between two runs.

## A new asset resolves against a manifest that predates it

* The fetched manifest is served from the default branch, so it lags a release
  that adds an asset. An entry the remote does not carry now falls back to the
  copy bundled with the installed package instead of failing to resolve. Where
  both carry a key the remote still wins, so a version bump reaches an
  already-installed package as before.

## Name cleaning keeps Title-Case and all-caps epithets (issue #8)

* `clean_names()` stripped a capitalized specific epithet as if it were an
  author, so `"Quercus Robur"` cleaned to `"Quercus"` and then matched the
  genus rather than the species. Trailing authorship is now removed by token
  position: the token after the genus is the specific epithet whatever its
  case, so Title-Case (`"Quercus Robur"`) and all-caps legacy (`"QUERCUS
  ROBUR"`) binomials keep their epithet, while a genus followed by an author
  (`"Rosa L."`) still reduces to the bare genus. Internal-capital author
  abbreviations (`"Picea abies (L.) H.Karst."`, `"Solidago canadensis
  A.Gray"`), which the previous pattern left in the cleaned name, are removed
  too.

## reconcile() no longer reports case variants as merges (issue #11)

* A name paired with its own case variant (`c("Quercus robur", "QUERCUS
  ROBUR")`) was flagged as a many-to-one merge, because the merge detector
  grouped on the raw input string while the status comparison used the
  normalized form. Input distinctness is now measured in the same normalized
  space, so a case- or spelling-only variant counts as one input; genuine
  merges are unchanged.

## lowest_common() ignores blank rank values (issue #15)

* A backbone that stores `""` (rather than `NA`) for an unresolved rank could
  make `lowest_common()` report the blank as the shared ancestor. Empty rank
  values are now treated as unresolved, so the most recent common ancestor
  falls through to the next rank every taxon actually shares.

## Reverse verbs default to the installed backbone set (issue #24)

* `synonyms()`, `children()`, `downstream()`, `upstream()` and `id2name()`
  defaulted to a single hardcoded backbone (`"wfo"` or `"col"`), so on a fresh
  install `synonyms("Quercus robur")` triggered a WFO download the default
  backbone set does not include. They now default to `backend = NULL`, which
  resolves to the highest-priority installed backbone, matching `taxify()`,
  `reconcile()` and `comm2sci()`.

## inspect() no longer flags valid congeners as typos (issue #10)

* `near_duplicate_targets()` measures the edit-distance and length gates on the
  epithet, not the whole binomial, so `"Carex flava"` is no longer flagged as a
  near-duplicate of `"Carex flacca"`. A genuine one-edit epithet typo still
  fires.

## enrich_simple() surfaces join and column gaps (issue #12)

* An explicitly requested `join_col` absent from the `.vtr` now errors instead
  of silently falling back to `canonical_name` (the mechanism behind past
  all-NA doors), and a mapped column absent from the schema warns, naming the
  enrichment and column, rather than attaching a silent all-NA column. The
  diagnostic is gated off the bundled example database.

## add_combine() preserves metadata and provenance (issue #13)

* A new `[.taxify_result` method carries `taxify_meta` through subsetting, so
  `add_combine()` (and any manual subset) no longer strips it. Reported columns
  are selected by exact set, so an already-imputed value is never mislabelled as
  a measurement.

## Lockfile and summary robustness (issue #14)

* `summary()` no longer errors on an enrichment entry without a version;
  `taxify_restore()` reports a distinct `"unverified"` status when nothing could
  be compared (instead of a false `"ok"`), and tolerates zero-length lockfile
  fields.

## Enrichment metadata and example-database safety (issue #16)

* `download_enrichment()` copies `license`, `available_groups` and `citation`
  into the installed `meta.json` (licence is no longer `NA` for downloaded
  enrichments); `ensure_enrichment()` refuses to download an unbundled
  enrichment into the example database.
* The bundled manifest now carries `group_col` for all seven grouped
  enrichments (`griis`, `gidias`, `alien_first_records`, `wcvp`,
  `marine_distribution`, `common_names`, `glonaf`), and
  `enrichment_groups()` falls back to the manifest when the installed
  `meta.json` lacks it. A grouped enrichment installed before the metadata was
  copied reported itself as ungrouped with no way to recover, because
  `available_groups` had a manifest fallback and `group_col` did not.

## Fuzzy matching picks the closest candidate (issue #23)

* Candidate ranking had no distance term: `score_candidates()` ordered by
  status, rank, validity, epithet and then `taxonID`, so among several fuzzy
  candidates the winner was decided by ID and a farther name could beat a
  nearer one. `"Carex flavaa"` resolved to `Carex flacca` (distance 0.167)
  while `Carex flava` (0.083) was in range, and the two were reported
  ambiguous although one was strictly closer. Distance now sorts first, so the
  nearest name wins and ambiguity is declared only among equidistant
  candidates. Exact matching is unaffected.
* `dedup_fuzzy_targets()` ran once per fuzzy pass, so a query dropped by the
  genus-blocked pass competed again in the prefix-blocked fallback and claimed
  the backbone row the first pass had already taken. The claimed rows are now
  carried forward, so two queries can no longer collapse onto one row.
* Measured over the full 34,589-name EVA-to-WFO corpus, fuzzy accepted-name
  agreement rises from 0.9152 to 0.9172 and WFO-ID agreement from 0.8031 to
  0.8050, against a 0.0009 fall in match rate.

## An executable accuracy corpus (issue #23)

* `tests/e2e/test-asaas-validation.R` asserted nothing: it printed its
  agreement rates with `cat()`, so a matching regression reported a worse
  number and passed, and it read from a hardcoded `J:/` path. It now locates
  the corpus through `TAXIFY_ASAAS_CORPUS`, asserts floors on match rate and
  on accepted-name, family, genus and WFO-ID agreement over the whole corpus,
  and asserts both sides of the fuzzy trade so neither recall nor precision
  can erode unnoticed. Divergence is split into backbone drift, the corpus
  hybrid-formula convention, and genuine misses, and only the last is capped.
  See `tests/e2e/README.md` for the baseline and how to read a disagreement.
* Assertions that could not fail were replaced: the trait-registry vocabulary
  check drove every crosswalk with `NA` only, `test-doors.R` accepted one
  populated column out of twenty, `children()` case-insensitivity held at zero
  rows, `summary()` was matched with `grepl("3", .)`, and the multi-backend
  fallback test used fixtures that both carried the species. Self-fulfilling
  comparisons in `test-default-backend.R`, `test-add-trait.R`, `test-region.R`,
  `test-gap-verbs.R` and `test-new-verbs.R` now assert independent literals.
* New coverage for ITIS (a member of the first-run backbone set that had no
  test at all), `add_common_names()`, `add_wcvp(region=)`, `add_glonaf()`,
  `add_alien_first_records()`, `install_backbones()`, and `taxify_restore()`'s
  `version_drift` / `content_drift` / `missing` branches. Negative and
  threshold-boundary fuzzy tests cover equidistant candidates, typos that must
  not resolve to a close-but-wrong species, and the accept/reject flip.

## Authorship tiebreak and fuzzy validation (issue #17)

* The authorship homonym tiebreak writes the accepted taxon's genus/family, not
  the rejected synonym's, so a disambiguated homonym carries a consistent
  lineage and life-form. `fuzzy_join` errors now warn instead of silently
  returning no matches, and `taxify()` validates `fuzzy` and `fuzzy_threshold`.

## Internals: backend registry and shared enrichment join (issues #20, #22)

* The 15 `backend-*.R` clones collapse into one registry-driven factory; adding
  a backbone is now a registry row plus a manifest entry. The three
  backend-info doors (`add_wfo_info()` / `add_gbif_info()` / `add_col_info()`)
  share one `enrich_from_backbone()` helper, and `add_data()` uses a vectorized,
  typed-NA join keyed on `accepted_id`.

## taxifydb is required at 0.1.19 or newer

* The register fallback calls `taxifydb::build_register()`, which taxifydb
  added during 0.1.18 rather than at its start, so a 0.1.18 built before that
  point satisfied an unversioned dependency and then failed the call. `Suggests`
  now names `taxifydb (>= 0.1.19)`, the first version whose number identifies
  code that carries the function.

## Documentation (issues #18, #19)

* Every `\donttest` example now runs offline against the example database or is
  `\dontrun`, so `R CMD check --run-donttest` never triggers a download. UTF-8
  BOMs removed from three R files and three vignettes; `taxify()`'s `@return`
  documents all 26 columns; the FISHMORPH trait list matches the columns
  `add_fishmorph()` emits.

## The fallback chain reaches every backbone again (issue #9)

* A name whose genus the leading backbone did not cover was marked
  `"out_of_scope"` and then skipped by every backbone behind it, because the
  fallback loop only retried rows whose `match_type` was `NA`. The chain ended
  at whichever backbone happened to be first. The package's own documented
  example, `taxify(c("Quercus robur", "Panthera leo"), backend = c("wfo",
  "gbif"))`, returned *Panthera leo* as `out_of_scope` without ever consulting
  GBIF.

* The default `backend = NULL` path was hit hardest, since COL leads the
  priority order: on a full install 41.4% of register genera (207,980 of
  502,088) sit outside COL's coverage, and every one of them is carried by a
  backbone further down the chain. 14,354 of those are marine genera that never
  reached WoRMS, so `region=` could not constrain a marine name COL does not
  list. `taxify("Parvocaris samnitica")` now resolves through WoRMS instead of
  returning `out_of_scope`.

* `"out_of_scope"` means what the documentation always said it meant: no
  backbone in the query covers the genus. The per-backbone mark still runs, so
  the abbreviated-genus and fuzzy stages are still skipped for a backbone that
  cannot carry the name (which also stops a spurious fuzzy near-match there
  from outranking the exact match waiting further down the chain), but it is
  released again for any name another backbone in the chain still covers. A
  single-backend query is unchanged.

* `backend` and `backbone_version` now name only the rows a backbone lookup
  actually resolved. They were stamped whenever `match_type` was non-`NA`, which
  swept in the verdicts a backbone never produced: an `out_of_scope` row read
  the leading backend's name and its resolved version even though no lookup
  found it there. Selecting `result[result$backend == "wfo", ]` then counted
  those rows, so a per-backbone hit rate over-reported every backbone in the
  chain. `"exact"`, `"exact_ci"`, `"fuzzy"` and `"abbrev"` carry the two
  columns; `"out_of_scope"`, `"hybrid_formula"` and `"none"` leave them `NA`.

## The marine region assets ship (issue #21)

* 0.3.20 added the marine range providers but the data they read did not exist
  yet, so the marine path stayed inert for everyone. Both assets are now
  published and registered in the manifest, and `region=` / `coords=` constrain
  marine matches out of the box.

* New `meow` boundary entry: 196,807 polygon vertices across all 232 Marine
  Ecoregions of the World, resolved through `download_backbone()` the way
  `wgsrpd` is. Reference geometry, so it does not join the taxonomic backbone
  set that `list_backbones()` reports.

* New `marine_distribution` enrichment entry: WoRMS distribution records rolled
  up to MEOW ecoregions, keyed on `canonical_name` with a `region_code` and a
  native/introduced status, the marine counterpart of the WCVP range table.

* `taxify_regions()` lists both vocabularies `region=` accepts, and gains a
  `scheme` argument (`"all"`, `"wgsrpd"`, `"meow"`) and a `scheme` column. It
  resolved marine names as soon as the asset was installed but only ever listed
  the botanical crosswalk, and the warning for an unrecognised region pointed
  users there. MEOW rows reuse the three name columns, since the two schemes
  nest the same way: ecoregion as `name`, province as `level2_name`, realm as
  `level1_name`. Marine rows appear only when the asset is installed, which is
  also when they resolve.

# taxify 0.3.20

## Region filtering generalizes beyond plants (issue #21)

* `region=` and `coords=` now constrain fuzzy matching for marine taxa, not
  only vascular plants. When the `marine_distribution` asset is installed,
  `region_range_sets()` unions two providers behind the unchanged arguments:
  WCVP (plants, keyed on TDWG Level 3 `tdwg_code`) and the marine distribution
  table (keyed on MEOW ecoregion `region_code`). Each resolved region code is
  routed to its provider by vocabulary -- alphabetic TDWG codes to WCVP, numeric
  MEOW `ECO_CODE`s to the marine table -- through one shared engine, so a
  plant-only query never touches the marine asset and vice versa.

* `region=` accepts MEOW ecoregion codes and ecoregion / province / realm names
  (a province or realm expands to its member ecoregions), resolved from the
  installed marine asset. `coords=` maps points to MEOW ecoregions by
  point-in-polygon against a new `meow.vtr` boundary set, unioned with the
  WGSRPD botanical lookup, so a coastal coordinate can resolve to both a
  botanical region and a marine ecoregion. The point-in-polygon machinery is
  now scheme-generic across the botanical and marine boundary sets.

* Marine support is inert until the `marine_distribution` enrichment is
  installed: the plant-only default path is unchanged.

## Five more name verbs

* `parse_name()` decomposes a name into its parts -- genus, specific epithet,
  infraspecific rank and epithet, authorship, hybrid status, open-nomenclature
  qualifier, and the canonical form -- without matching against a backbone, the
  role `rgbif::name_parse()` or gnparser fill. It reuses the same cleaning
  pipeline `taxify()` runs, so a name breaks apart the way it matches.
* `upstream()` returns the higher classification (ancestors) of a taxon as a
  tidy long frame, one row per rank from kingdom down to genus; `to =` restricts
  it to a single rank ("what family is this in?"). The ancestor-direction
  complement of `downstream()`.
* `sci2comm()` resolves scientific names to their common (vernacular) names --
  the forward complement of `comm2sci()`, reading the bundled `common_names`
  data offline. `resolve = TRUE` (default) taxifys the input to its accepted
  name first.
* `reconcile()` reports how a checklist maps onto a backbone's current
  treatment, classifying each name as `unchanged`, `synonym`, `misspelling`,
  `ambiguous`, or `unresolved`, and flagging many-to-one merges where several
  inputs collapse onto one accepted name -- a checklist-migration summary.
* `taxify_lock()` / `taxify_restore()` write and verify a reproducibility
  lockfile: `taxify_lock()` serializes the resolved backbones and enrichment
  layers (name, version, content id, download date) behind a result to JSON, and
  `taxify_restore()` compares a lockfile to the current install and reports
  `ok` / `version_drift` / `content_drift` / `missing`.

## Authorship-aware homonym disambiguation

* When an ambiguous match (a homonym such as *Pinus abies* L. vs Thunb.) carries
  an author in the input, `taxify()` now resolves it to the single
  author-matching accepted target instead of returning the tie. The tiebreak
  only touches ambiguous author-bearing rows; the fast path and every
  unambiguous result are unchanged.

## Bug fixes

* Resolved an `R CMD check` warning about an unresolvable `taxifydb::build_meow`
  reference. The scheme's boundary builder is now looked up by name at run time,
  so the marine builder is used when taxifydb provides it and skipped cleanly
  when it does not.

# taxify 0.3.19

## Five new name-resolution verbs

* `comm2sci()` resolves common (vernacular) names to scientific names -- the
  reverse of `add_common_names()`. Reads the bundled `common_names` data
  offline; `resolve = TRUE` runs the matches through `taxify()` and returns an
  enrichable `taxify_result`.
* `id2name()` looks a backend ID (a GBIF key, ITIS TSN, WoRMS AphiaID, ...) back
  up to its name, rank, classification, and accepted-name resolution -- the
  inverse of the `taxon_id` / `accepted_id` columns `taxify()` emits.
* `downstream()` lists every accepted taxon at a chosen rank (species by
  default) beneath a higher taxon, where `children()` gives only the immediate
  level.
* `class2tree()` assembles a taxonomy tree (Newick, plus an `ape` `phylo` object
  when `ape` is installed) from a set of resolved names, and `lowest_common()`
  reports the deepest rank at which a set of names shares a common ancestor.

## Cross-kingdom disambiguation on `taxify()`

* `taxify(..., kingdom = )` restricts matches to one or more kingdoms
  (`"animals"`, `"plants"`, `"fungi"`, ...), so a name shared across kingdoms (a
  *Prunella* that is both a bird and a plant) resolves to the intended one. A
  match whose kingdom is wrong is passed on to the next backbone in the fallback
  chain; the kingdom is read from the backbone where it stores one, falling back
  to the genus register otherwise.

# taxify 0.3.18

## Documentation

* The README now notes that the backbones are pre-built by the companion
  taxifydb package, and updates the enrichment-layer count to match
  `list_enrichments()`.

# taxify 0.3.17

## A downloaded backbone reports the version it actually contains

* Downloading a backbone into a slot that was previously built from source no
  longer keeps reporting the old built version. `download_backbone()` now clears
  the stale `.meta` build sidecar it leaves behind, restoring the invariant that
  a downloaded backbone carries only its `meta.json`. Previously the leftover
  `.meta` shadowed `meta.json` in `format_backbone_version()`, so a freshly
  downloaded release (e.g. Euro+Med 2026.07) was still labelled with the old
  built version (2020.1) in the `backbone_version` output column.

## meta.json and manifest reads tolerate a UTF-8 BOM

* A `meta.json` or manifest carrying a leading UTF-8 byte-order mark (as written
  by Windows PowerShell's `Set-Content` / `Out-File`) no longer emits an
  "illegal byte-order-mark" warning on every version read. All meta.json and
  manifest reads strip a leading BOM before parsing.

# taxify 0.3.16

## The genus register is reachable and builds from what you have

* `taxify_build_register()` is now exported. It builds the unified genus
  register from the backbones you have installed and is the front door for the
  `life_form` / `kingdom_group` / `taxon_group` output columns, out-of-scope
  detection, and `inspect()`'s no-backbone checks. Previously the only builder
  was internal, so `taxify_load_register()` on a fresh setup pointed users at a
  function they could not call, and the manifest's register entry was a Zenodo
  placeholder that never resolved. `taxify_download("register")` is a
  convenience alias for it.

* Building the register no longer force-downloads every known backbone. It
  unions only the backbones actually installed (via the new internal
  `installed_backbone_path()`), matching the documented "union of installed
  backends" behaviour instead of silently pulling several gigabytes.

## Backbone version reflects the installed data, not a static default

* The build-from-source shims no longer pass a hardcoded version label into
  `taxifydb::build_<name>()`; taxifydb stamps its own current version. A backbone
  built from source is now labelled with the data it actually contains, not a
  constant that drifts as releases advance.

* `format_backbone_version()` falls back to the download-time `meta.json`
  (the manifest version) before the backend constructor's static default, so a
  downloaded backbone reports the version it was downloaded at.

* Manifest: the `reptiledb` backbone points at the `reptiledb-2026.07` release
  (byte-identical to 2026.06) and records its content id; the placeholder
  `register` entry is removed.

# taxify 0.3.15

## `add_gidias()` can ask what a species impacts

* GIDIAS scores each impact record against an affected native taxon, so
  `add_gidias(group = )` reads impact at that grain: *Felis catus* is `"MO"`
  against invertebrates (reduced populations) where the default is `"MV"`, the
  global extinctions it drove among vertebrates. 28% of species with an
  affected taxon recorded impact two or more of the five groups
  (`Plant`, `Invertebrate`, `Vertebrate`, `Microbe`, `Fungi`), so for those the
  species-level category is the most severe impact on anything, not the impact
  on each thing. `enrichment_groups("gidias")` lists them; several groups
  suffix the columns, as `add_alien_first_records()` does for countries.

* `add_gidias()` with no `group` is unchanged: it reads the `"Any"` grain, the
  same all-records summary it returned before, with the same columns. `"Any"`
  is the only grain carrying SEICAT and the impact records with no affected
  taxon recorded, so `gidias_seicat_category` is `NA` on the other groups.
  Requires the rebuilt `gidias` enrichment.

* `cols` now works on the grouped doors even when the source carries no columns
  beyond the curated set, which previously ignored it.

## Citations carry an access date

* A source harvested live from a server is not identified by its year: two
  harvests a year apart share it. `format_bibtex_entry()` now emits the
  citation's `note` field, so an access date recorded in the manifest reaches
  the BibTeX entry. Entries carrying no `note` are unchanged.

# taxify 0.3.14

## A wrong temperature reached users, and is fixed

* FishTraits shipped a `-1` missing-data code in its two temperature columns, so
  90 introduced fish (goldfish, zebrafish, brown trout) reported a July maximum
  of -1 degrees C, which is impossible in the conterminous US. `add_fishtraits()`
  surfaced it as `ft_min_temp_c` / `ft_max_temp_c`. The rebuilt data reads NA for
  those species, and the warmest-month value now bottoms out at a believable
  20.4 degrees C. Species whose January minimum genuinely is -1 keep it.
* The same source also used "." for an absent text value, which reached
  `ft_itis_tsn` and `ft_common_name`, and produced five unusable rows named
  after a family ("Percidae ."). Both are cleaned.
* The corrected data ships under the existing release, and taxify refreshes a
  stale local copy once, on its own, the first time you use it.

## The range climate gains its minimum and maximum

* New `climatic_temp_min` and `climatic_temp_max` (degrees C): the coldest-month
  and warmest-month temperature at a species' range centroid, from FishTraits.
  They join `climatic_temp_mean` in the climatic-niche family, which stays apart
  from the organismal `thermal_max` / `thermal_min`. Largemouth bass shows why
  the split earns its keep: its range tops out at 32.0 degrees C while it can
  survive 33.5. These were held back until the `-1` code above was fixed.

## Plant chromosome numbers

* `chromosome_number` reported a count nobody had measured, and is fixed.
  *Arabidopsis thaliana* read 15 and *Acer campestre* 39, from species recorded
  at more than one cytotype: Kew holds a diploid 2n = 10 and a tetraploid 2n = 20
  for *Arabidopsis*, and averaging them lands on 15, which is in neither record.
  The value is now the base cytotype (10 and 26 for those two), and the range
  across cytotypes is reported in `chromosome_number_min` /
  `chromosome_number_max`, so nothing is lost. 421 species change value, and
  every value now comes from a real record.
* An odd chromosome number is still reported wherever Kew measured one. A
  triploid carries an odd 2n by definition (Tahiti lime is 2n = 3x = 27), as do
  aneuploid hybrids and the gametophytic counts of mosses and liverworts.
* Kew's plant genome size is a continuous measurement and is unaffected.
* Every Kew value can now be traced to the paper it was measured in.
  `add_kew_cvalues(cols = "all")` attaches `cval_original_reference` and
  `cval_estimation_method`, both populated for every species, covering 941
  distinct papers. Where a species carries records from several papers, all are
  listed, as with *Arabidopsis thaliana* ("Bennett et al.,2003; Schmuths
  et al.,2004").
* The estimation method is worth reading before comparing genome sizes. 9,015
  species were measured by flow cytometry and 3,391 by Feulgen densitometry,
  which are different measurements, and 97 species carry both.
* The corrected data ships under the existing release, and taxify refreshes a
  stale local copy once, on its own, the first time you use it.
* New `add_ccdb()`: somatic chromosome numbers from the Chromosome Counts
  Database for 65,051 plant species, with the range of cytotypes each spans.
  CCDB states no licence, so taxify publishes no copy; the door builds it on your
  machine through taxifydb, like the other build-only sources.
* The `chromosome_number` trait continues to come from Kew alone. CCDB covers
  seven times more species, but a source reachable only where a build tool is
  installed would make `add_trait()` return a different number on two machines
  running the same code.
* Kew's plant genome size stays behind `add_kew_cvalues()` in picograms rather
  than joining the prokaryote `genome_size` trait in base pairs. The picogram to
  base-pair conversion is a constant, but a plant 1C value counts every subgenome
  a polyploid carries, while a bacterial genome size counts one chromosome.

# taxify 0.3.13

## Four sources taxify cannot redistribute now have doors

* New `add_gmpd()` (Global Mammal Parasite Database 2.0: per-host parasite
  richness, counts by parasite type, mean prevalence), `add_plantatt()`
  (British and Irish vascular plants: Ellenberg values, maximum height,
  life-form/woodiness/status codes), `add_bryoatt()` (the bryophyte companion --
  a group otherwise almost absent from the bundled traits), and `add_clopla()`
  (CLO-PLA clonal and bud-bank traits of the Central European flora, 29 codes
  kept verbatim).
* These four state no usable licence, so taxify publishes no copy of them and
  they carry no manifest entry. The door builds the data from the original
  source on your own machine through taxifydb, which is required for them and
  errors with an install instruction when absent. taxify redistributes none of
  the data; cite the sources when you use them.

## Climatic niche is now separate from thermal tolerance

* New `climatic_temp_mean`: the mean annual temperature of a species' range, in
  degrees C, from the NW European arthropod dataset (WorldClim BIO1 over
  occurrence buffers) and ReptTraits (CHELSA over GARD ranges). It is kept
  strictly apart from `thermal_max` / `thermal_min`, which are organismal CTmax
  and CTmin: a range climate is bounded by dispersal, competition and history,
  so it sits well inside what an animal can survive.

## New traits

* `forearm_length` (mm): the standard bat measurement, from COMBINE, PanTHERIA
  and the European bat dataset (the first two carried it for 1130 and 1012
  species without any trait reaching it).
* `chromosome_number` (2n): from the Kew Plant DNA C-values database.
* `thermal_max` / `thermal_min` gain the freshwater thermal-tolerance database
  (CTmax and CTmin of freshwater fish, invertebrates and amphibians).
* `body_mass`, `longevity`, `clutch_litter_size` and `diet_guild` gain the
  European bat dataset; `longevity` and `age_at_maturity` gain FishTraits;
  `clutch_litter_size` gains the zooplankton per-clutch egg count.

# taxify 0.3.12

## Default backend is now every installed backbone

* `taxify(backend = NULL)` (the new default) matches against **every installed
  backbone** as a first-match fallback chain, instead of only WFO. A name is
  resolved by the first backbone that matches it in priority order -- COL, then
  the domain authorities (marine, vascular plants, fungi, algae, fishes,
  reptiles), then the broad aggregators (GBIF, ITIS, NCBI, OTT) -- so cross-
  kingdom input works without knowing which backbone to name, and disagreement
  cases resolve to the more current treatment (e.g. `Macropus rufus` ->
  `Osphranter rufus`). It is a first-match pick, not a consensus vote (a vote
  would regress toward the most conservative treatment across backbones that
  copy one another); use `mode = "wide"` / `"agreement"` to see disagreement.
* On a fresh setup with nothing installed, the first `taxify()` call downloads a
  default set once -- **COL, GBIF, and ITIS** -- covering all kingdoms with a
  genuine cross-backbone agreement signal. Pre-install a different set with the
  new `install_backbones()`, or set it via
  `options(taxify.default_backbones = ...)`. The priority order is configurable
  with `options(taxify.backbone_priority = ...)`.
* New exported `install_backbones()` downloads one or more backbones for offline
  use (defaults to the first-run set).
* Naming a `backend` explicitly is unchanged, so existing calls keep working;
  only the unset default moved off WFO.

## COMBINE: one door fills imputed gaps and tags provenance

* `add_combine()` is now the full COMBINE door rather than a thin alias of
  `add_combine_reported()`. It attaches the reported (measured) values and fills
  each still-missing cell from COMBINE's phylogenetically imputed table, so a
  single call reaches COMBINE's fullest coverage. A measurement is never
  overwritten -- the reported value wins and the model only fills gaps -- and a
  companion `combine_<trait>_src` column tags every cell as `"reported"`,
  `"imputed"`, or `NA`, keeping the measured-vs-modelled distinction explicit
  per cell. `add_combine_reported()` (measured only) and `add_combine_imputed()`
  (the imputed table on its own) are unchanged. Runtime-only; no data rebuild.

# taxify 0.3.11

## Genus-resolved enrichment joins

* `add_cefas_btrait()` now joins on `genus`. The Cefas benthic-traits database
  codes traits at genus level, so the previous species-level join returned `NA`
  for every species; it now annotates every species in a coded genus.
* `add_epa_freshwater()` now uses a species-first, genus-fallback join. The US
  EPA Freshwater Biological Traits Database records each trait at the finest
  resolution available, so a species keeps its species-level values and any
  trait still missing is filled from the taxon's genus-level row (a species
  value is never overwritten). This is a new `genus_fallback` option on the
  shared enrichment engine, available to any mixed-resolution source.

# taxify 0.3.10

## Five more trait sources

* Five enrichments that had working parsers but had never been released now have
  doors: `add_kew_cvalues()` (plant genome size, chromosome number and ploidy
  from the Kew Plant DNA C-values database, CC BY), `add_copepod_traits()`
  (marine copepod body size, egg and clutch traits, Brun et al. 2017, CC BY 3.0),
  `add_fishtraits()` (United States freshwater-fish life history, temperature and
  salinity tolerance, and conservation traits, Frimpong & Angermeier 2009, public
  domain), `add_epa_freshwater()` (freshwater-invertebrate functional traits, US
  EPA, public domain), and `add_cefas_btrait()` (North-West European shelf
  benthic biological traits, Cefas, OGL v3.0). Each is source-prefixed
  (`cval_`, `cop_`, `ft_`, `epa_`, `cefas_`) and takes `cols = "all"` for the
  full column set.

## Documentation and metadata

* The reference index now lists `add_combine_reported()`, `add_combine_imputed()`,
  `enrichment_groups()`, and the low-level building blocks.
* `thermofresh`, `ramond`, `freshwater_insects_conus`, and `eurobat` are flagged
  static in the manifest, so their version is not re-checked each session.

# taxify 0.3.9

## Invasion impact (EICAT / SEICAT)

* `add_gidias()` joins per-species invasion-impact aggregates from GIDIAS
  (Bacher et al. 2025, CC BY 4.0), the IPBES invasive-species assessment's
  global impact compilation. Each species carries its IUCN EICAT
  environmental-impact category (`gidias_eicat_category`, `MC`/`MN`/`MO`/`MR`/`MV`,
  or `DD`) and SEICAT socio-economic-impact category (`gidias_seicat_category`),
  each the most severe magnitude among the species' documented negative impacts,
  alongside the driving mechanism, affected well-being constituents, realms, and
  record and source counts. Only the derived per-species aggregates are
  distributed, not the raw impact records.

* `add_trait()` gains two categorical traits, `"environmental_impact"` (EICAT)
  and `"socioeconomic_impact"` (SEICAT), so invasion impact reconciles across
  sources the way every other trait does. GIDIAS is the first source; the
  ordinal categories are shared so further EICAT assessments can coalesce onto
  them later.

# taxify 0.3.8

## Economic cost of invasions

* `add_invacost()` joins per-species economic-cost aggregates from InvaCost
  (Diagne et al. 2020, CC BY 4.0): `invacost_cost_total_usd` (cumulative
  documented 2017-USD cost), `invacost_cost_n` (number of estimates), and the
  dominant `invacost_cost_type`.

## PHYLACINE mass is not silently model-derived

* `add_phylacine()` surfaces `phylacine_mass_method` and
  `phylacine_mass_method_class`, recording whether a body mass is measured
  (`reported`), allometrically `estimated`, or phylogenetically `imputed`.
* `add_trait("body_mass")` now flags model-derived PHYLACINE masses per species:
  where PHYLACINE contributes an imputed or estimated mass, `body_mass_caution`
  explains it for that species only; measured masses are left unflagged. A trait
  registry source can attach such a per-record caution via `caution_col` /
  `caution_fn`, distinct from the existing whole-source method caution.

# taxify 0.3.7

## Compare backbones in one call

* `taxify()` gains a `mode` argument. With more than one `backend`, the default
  `mode = "fallback"` is the usual fallback chain, while `mode = "wide"` consults
  every backbone for every name and adds one `accepted_<backbone>` column plus a
  logical `all_agree`, and `mode = "agreement"` adds `n_backbones_matched`,
  `n_distinct_accepted`, and `all_agree`. Both are a strict superset of the
  standard result (a single `accepted_name`, still pipeable into the `add_*()`
  enrichments), so a backbone disagreement, such as GBIF keeping `Macropus rufus`
  where the Catalogue of Life resolves it to `Osphranter rufus`, is visible in
  one call instead of querying each backbone by hand.

## Discovering group values

* `enrichment_groups()` lists the group values a grouped enrichment door can
  filter on, the way `enrichment_cols()` lists a door's columns. It answers "what
  country / region / language codes are valid?" for `add_griis(country=)`,
  `add_wcvp(region=)`, `add_common_names(lang=)`, and
  `add_alien_first_records(country=)`.

## Aggregate trait resolution

* An aggregate query (`"Rubus fruticosus agg."`, `"... s.l."`) now falls back to
  the nominal binomial's trait when a source carries no aggregate-level value.
  Aggregate-level values are still used first where present; the binomial is a
  pragmatic stand-in, not a real aggregate-level measurement. This also fixes a
  preserve-fell-back aggregate (one with no dedicated aggregate taxon in the
  backbone) reaching its binomial's traits.

* The fallback is on by default and can be turned off per call with
  `aggregate_trait_fallback = FALSE`, or globally with
  `options(taxify.aggregate_trait_fallback = FALSE)`, which keeps a resolved
  aggregate without aggregate-level data as `NA`.

* `options(taxify.trait_provenance = TRUE)` now adds a character
  `<enrichment>_basis` column (`"primary"` a same-level hit, `"aggregate"` a
  species inheriting its aggregate's value, `"binomial"` an aggregate standing
  in on its binomial) in place of the earlier logical `<enrichment>_inherited`
  flag, so the basis of every filled value is explicit.

# taxify 0.3.6

## Hybrid matching

* Hybrid names are handled by type instead of being reduced to their first
  component. `taxify()` gains a `hybrid_type` column (`"nothogenus"`,
  `"nothospecies"`, `"formula"`, or `NA`).

* Hybrid formulas (`"Salix alba × Salix fragilis"`) no longer resolve to a
  single species. Previously the cross was silently cut to its first parent and
  returned as an exact match to `Salix alba`; now the cross row carries
  `match_type = "hybrid_formula"` with `NA` backbone-match columns. The parent
  binomials, and their accepted names, are available on demand via
  `add_hybrid_info()`, which now adds `hybrid_parent_1`, `hybrid_parent_2`,
  `hybrid_parent_1_accepted`, and `hybrid_parent_2_accepted`.

* The same-genus formula shorthand is recognized: `"Salix alba × fragilis"`
  (second parent written as a bare epithet) parses to parents `"Salix alba"` and
  `"Salix fragilis"`.

* Nothogenus names match backbones that store the multiplication sign.
  `"× Cupressocyparis leylandii"` previously returned `NA` against backbones
  whose canonical form keeps the sign (e.g. `"× Cupressocyparis leylandii"`);
  matching now tries the `"× Genus ..."` and `"×Genus ..."` forms alongside the
  sign-stripped binomial. Nothospecies (`"Quercus × hispanica"`) continue to
  match as before.

# taxify 0.3.5

## Discovery

* New `list_backbones()` lists every supported taxonomic backbone with its scope,
  name count, download size, version, install status, and source, mirroring
  `list_enrichments()`. New `taxify_databases()` stacks the backbones and
  enrichments into one overview so the full breadth is one call away. A canonical
  backbone registry now backs `resolve_backend()`, `installed_backbones()`, and
  these verbs, so the supported set cannot drift between them.

* A "Databases" pkgdown article lists every backbone, enrichment, and trait,
  generated from the shipped manifest so it stays current.

## Backbones

* The LCVP and WCVP backbones are downloadable as pre-built `.vtr` files. They
  previously had no published release and could only be built from source; both
  are now in the manifest (`lcvp-3.0.1`, `wcvp-2026.06`), so all fifteen
  backbones resolve without `taxifydb` installed.

# taxify 0.3.4

## Bug fixes

* `clean_names()` recognizes a much wider set of taxonomic qualifiers and rank
  abbreviations. Previously an unrecognized marker survived into the cleaned
  name, so the name no longer matched the backbone's bare binomial/trinomial
  (it dropped to fuzzy) and the annotation was lost from the `qualifier` column.
  Now folded to their canonical tokens: the subspecies abbreviations `ssp.` and
  `nssp.` and the spelled-out `subspecies` (to `subsp.`); the sensu-stricto form
  `s.s.` (to `s.str.`); the forma spellings `fo.` and `forma` (to `f.`); the
  infraspecific ranks `subvar.`, `subf.`, and `convar.`; the notho- (hybrid)
  ranks `nothosubsp.` and `nothovar.` (to `subsp.`/`var.`, the hybrid signal
  being carried separately by the multiplication sign); cultivar `cv.`; the
  pathogen infrasubspecific categories `f. sp.` (forma specialis, previously
  mislabelled as a bare forma) and `pv.` (pathovar); the determination marker
  `nr.` ("near"); the open-nomenclature markers `indet.` and `sp. nov.`; the
  long and bare concept forms `s. lat.` and `coll.` (to `s.l.`); and the
  species-group markers `group` and `gr.`. Each token matches only as a whole
  trailing word, so it never touches a real epithet (`Carex novae-zelandiae`
  and `Convallaria majalis` are untouched). The qualifier registry in
  `R/clean.R` remains the single source of truth for every spelling.

# taxify 0.3.3

## New features

* WCVP and LCVP join the plant backbones. `taxify(x, backend = "wcvp")` matches
  against Kew's World Checklist of Vascular Plants (Govaerts et al. 2021, ~1.4M
  names, CC BY 4.0); `backend = "lcvp"` matches the Leipzig Catalogue of Vascular
  Plants (Freiberg et al. 2020, MIT). Both slot into the fallback chain
  (`backend = c("wcvp", "wfo")`) and contribute their genera (kingdom Plantae) to
  the unified genus register. Fifteen backbones are now available.
* Four new verbs read the backbone in the directions `taxify()` does not.
  `synonyms()` lists every synonym that resolves to a name's accepted taxon (the
  reverse of the forward resolution). `add_classification()` fills the higher
  ranks (kingdom, phylum, class, order) from the matched backbone, complementing
  the `family` and `genus` already in the core output. `children()` lists the
  accepted taxa within a genus or family, for building a checklist rather than
  only validating one. `taxify_candidates()` expands an ambiguous match
  (`is_ambiguous`) into one row per candidate accepted taxon, so homonyms can be
  resolved by hand.
* `taxify()` gains an `aggregate_fallback` column that makes the default
  `aggregates = "preserve"` accountable. Where a backbone carries no dedicated
  aggregate taxon for an aggregate query, preserve falls back to the nominal
  binomial; that collapse is now flagged (`TRUE` on fallback, `FALSE` when the
  aggregate taxon was matched, `NA` for non-aggregate queries and under
  `collapse`) rather than being silent. Only Euro+Med (433 aggregate taxa) and
  WoRMS (189) carry them, so preserve is a no-op for the other backbones -- the
  flag now says so per row.
* `add_kew_sid()` opens the Kew Seed Information Database (SER-SID, CC BY 2.0):
  seed weight (thousand-seed weight over 42,000 species), storage behaviour
  (orthodox/recalcitrant/intermediate), oil and protein content, life form, and
  fruit type, joined on `accepted_name` across 50,146 accepted names. Verified
  end-to-end (*Quercus robur* 3493 g/1000 seeds and recalcitrant; *Helianthus
  annuus* 43.5% seed oil). Its seed weight also joins the cross-source
  `add_trait("seed_mass")` verb as a seventh source (a thousand-seed weight in
  grams equals the per-seed mass in mg; grounded at ratio 1.00 against Diaz,
  BIEN, and AusTraits), roughly doubling seed-mass species coverage.
* `add_edwards_phyto()` opens the Edwards et al. (2015) phytoplankton
  nutrient-utilization database (~130 species): Droop/Monod uptake and growth
  parameters for ammonium, nitrate, and phosphorus (`mu`/`k`/`vmax`/`qmin`/`qmax`),
  plus cell volume, carbon content, taxonomic group, and marine/freshwater
  habitat. A curated core attaches by default; `cols = "all"` surfaces every
  uptake parameter. Door-only (single-source physiology with no cross-source
  analogue), so it stays out of the `add_trait()` verb. Verified end-to-end
  (*Alexandrium catenella* recovered as a marine dinoflagellate).
* Nine new `add_trait()` traits covering algae, marine-benthic invertebrates,
  and octocorals, each grounded on its source's own vocabulary before wiring.
  Algae (AlgaeTraits): `calcification`, `gamete_type`, `algal_life_cycle`
  (dominant ploidy phase), `algal_substrate`. Marine benthos, harmonized across
  two sources (Arctic Traits + New Zealand Trait Database): `bioturbation`
  (Solan/Queiros functional groups), `living_habit`, `feeding_guild`.
  Octocoral (Gomez-Gras et al. 2024): `skeletal_rigidity`, `colony_growth_form`.
  Verified end-to-end (Corallina calcified-articulated, Fucus diplontic,
  Laminaria haplodiplontic; the bryozoan Alcyonidium gelatinosum an attached
  suspension-feeder with no bioturbation).
* Seven new single-source `add_trait()` traits, each grounded on its source's
  own values before wiring: `gc_content` (prokaryote genome GC %, Madin et al.
  2020) and `sporulation` (endospore formation, same source), extending the
  prokaryote block; `larval_nutrition` (bee larval food, EuPollTrait);
  `colour_lightness` (beetle body greyness 0-255, saproxylic beetle traits, a
  melanism axis); `cell_surface_area` (microalgae, um2, Rimet et al., alongside
  `cell_length`/`cell_width`/`cell_thickness`/`cell_biovolume`); `carapace_length`
  (turtle, mm, TurtleTraits); and `parental_care` (fish Balon reproductive guild
  guarder/non-guarder/bearer, Beukhof et al. 2019). Verified end-to-end
  (Thermus aquaticus GC 67%, Bacillus subtilis sporulates, leatherback carapace
  2.26 m, stickleback a guarder). `add_trait("fruit_type")` also gains AusTraits
  as a third plant source.
* Three new `add_trait()` traits, each grounded on the source's own values
  before wiring: `zooxanthellate` (coral symbiotic state, from the Coral Trait
  Database and the octocoral dataset, which share the
  zooxanthellate/azooxanthellate vocabulary), `optimal_growth_ph` (prokaryote,
  from Madin et al. 2020, the pH companion to `optimal_growth_temperature`), and
  `cell_thickness` (microalgae, from Rimet et al., alongside the existing
  `cell_length`/`cell_width`/`cell_biovolume`).
* `add_trait("diet_guild")` now also draws on EltonTraits (Wilman et al. 2014),
  extending diet guilds from birds and reptiles to mammals. The guild is derived
  from the ten EltonTraits diet fractions (built into `elton_traits.vtr`) and
  agrees 93% with EltonTraits' own diet classification and 83% with AVONET.
  `add_elton_traits()` exposes the same `diet_guild` column directly.
* `add_trait("ellenberg_salt")` gains Baseflor as a third source: its salinity
  column is on the same 0-9 Ellenberg scale as FloraWeb and Ecoflora (Pearson
  r = 0.88 on shared species), so it joins them without rescaling.
* New `add_trait()` traits `egg_length` and `egg_width` (mm) gather reptile,
  bird, and turtle egg dimensions from the Amniote database, ReptTraits, and
  TurtleTraits, which agree to within measurement noise on shared species.
* New `add_trait("brain_mass")` (g) coalesces COMBINE with AnimalTraits (kg
  converted to grams), calibrated 1:1 on shared species.
* Wider taxonomic coverage for several life-history traits, each source
  shared-species calibrated before it was added: `reproductive_frequency` now
  spans mammals through reptiles and turtles (AnAge, PanTHERIA, ReptTraits,
  TurtleTraits added); `clutch_litter_size` gains turtles (TurtleTraits) and
  birds (Birdbase); `age_at_maturity` gains turtles and fish (TurtleTraits,
  Beukhof); and `longevity` gains fish (Beukhof, whose ~390 yr maximum is the
  Greenland shark).
* `add_trait("pollination_vector")` gains FloraWeb and AusTraits, which agree
  82-91% with the existing Baseflor and Ecoflora sources on shared species. Named
  insect taxa (bee, beetle, fly, ...) resolve to `insect`; AusTraits' coarse
  `biotic`/`abiotic` and animal (bird, bat) records have no single vector in this
  vocabulary and stay `NA` rather than being guessed.
* Six new `add_trait()` traits, each numeric source shared-species calibrated
  (ratio ~1.00) against a co-registered source before it was added: `male_maturity`
  (yr; AnAge, Amniote, COMBINE -- the male analogue of `age_at_maturity`),
  `incubation_period` (days; Amniote, TurtleTraits egg incubation, kept separate
  from the combined `gestation_incubation`), `diet_breadth` (count of dietary
  categories; COMBINE, PanTHERIA, Birdbase), `tongue_length` (mm; Ostwald,
  EuPollTrait bee proboscis), `aspect_ratio` (caudal-fin aspect ratio; Beukhof,
  Quimbayo), and `foraging_mode` (active/ambush/mixed; ReptTraits, TurtleTraits).
* `add_trait("diet_guild")` gains TurtleTraits and Blanchard ant diets, mapped to
  the guild vocabulary by ordered regex (compound "omnivorous to carnivorous"
  resolves to its primary guild; ant "predator" to carnivore).
* Six more `add_trait()` traits: `reproductive_mode` (oviparous/ovoviviparous/
  viviparous; ReptTraits plus Sharkipedia, whose shark strategies collapse to
  viviparous); the coral-habitat traits `coloniality`, `wave_exposure`, and
  `water_clarity` (Coral Trait DB and octocoral, sharing one vocabulary); and
  `head_length`/`head_width` (mm; amphibian and beetle morphometrics). The depth
  traits `depth_min`/`depth_max` gain coral occurrence-depth limits (Coral Trait
  DB, octocoral) in the same metres unit as the fish sources.
* Eleven more `add_trait()` traits, including a new prokaryote domain from Madin
  et al. (2020): `gram_stain`, `oxygen_metabolism`, `cell_shape`,
  `optimal_growth_temperature` (deg C), and `genome_size` (bp). Also
  `caudal_fin_shape` (Beukhof + Quimbayo fish fin shape), `voltinism`
  (generations per year; Arthropod Traits + EuPollTrait), `migration` (AVONET),
  `flightless` (BIRDBASE), `venomous` (ReptTraits), and `sociality` (EuPollTrait
  bees). `thermal_max` gains Pottier amphibian CTmax on the same degrees-C scale.
* Nine more `add_trait()` traits: `wingspan` (mm; LepTraits butterflies, whose
  source column is labelled mm but is actually cm, corrected on the known
  wingspans of monarch, cabbage white, and swallowtail); `leaf_length` and
  `leaf_width` (mm; AusTraits); `fungal_trophic_mode` (FUNGuild and FungalTraits);
  `feeding_mode` and `mouth_position` (fish; Beukhof, Quimbayo); `air_breathing`
  (FishBase); `motility` (prokaryote; Madin); and `lecty` (bee pollen host
  breadth; EuPollTrait).

## Bug fixes

* Static enrichments now refresh their local cache when the source data is
  rebuilt and re-released under the same tag. Previously a version-locked
  enrichment never re-checked, so a cache downloaded before a rebuild stayed
  stale forever (silent all-NA for any newly added columns). The manifest now
  carries a `content_id` (an md5 of the built `.vtr`); a static cache is
  reconciled against it entirely offline, re-downloading only when the bytes
  actually changed. A pre-existing cache with no stored id is hashed in place,
  so an unchanged asset is adopted without a download. Fixes stale
  `add_nesttrait()` nest-modality columns and `add_disperse()` bin-midpoint
  columns for anyone who cached those before the rebuild. Every enrichment
  asset now carries a content id, and the same gate is extended to backbones
  (a content id catches a same-tag republish that a version bump would miss).
  The read-only example database and its offline fixtures are never touched.
* `add_trait()` now joins genus-keyed sources on `genus`: the ant-diet
  contribution to `diet_guild` (Blanchard) was silently all-NA, and
  `fungal_trophic_mode`'s FungalTraits source likewise. A registry guard test
  now asserts every genus-keyed source is joined correctly.

# taxify 0.3.2

## New features

* New `add_trait()` attaches a single trait across every source that carries it,
  reconciling their vocabularies and units. Where each `add_*()` door joins one
  dataset, `add_trait("seed_mass")` gathers the sources: it pulls seed mass from
  Diaz et al. and GIFT and returns both in one unit (mg), woodiness from Zanne
  and GIFT in one vocabulary, and likewise plant height and SLA. The default
  `mode = "coalesce"` adds one value per row with the columns that document it --
  `seed_mass`, `seed_mass_unit`, `seed_mass_sources`, and `seed_mass_n` -- which
  keeps chained calls tidy; `mode = "wide"` instead gives one harmonized column
  per source (`seed_mass_diaz`, `seed_mass_gift`) to inspect agreement and
  conflict. When sources measure a trait by different methods (for example
  maximum vs fine-root diameter), the value is not blended: the most complete
  source is reported and a `seed_mass_caution` column explains the difference.
  `list_traits()` lists the available traits and `trait_info()` shows a trait's
  sources, units, harmonization notes, and cautions. The registry ships dozens of
  traits spanning plant functional and root traits, animal body size, life
  history and morphology, diel activity, thermal limits, phenology, indicator
  values, and conservation status, each with a crosswalk grounded on the source
  values rather than assumed.

## Renamed (source-named doors)

* Enrichment doors are named after their source; the trait name is reserved for
  `add_trait()`. `add_woodiness()`, `add_conservation_status()`,
  `add_invasive_status()`, and `add_fish_traits()` are renamed to `add_zanne()`
  (Zanne et al. 2014), `add_iucn()` (IUCN Red List), `add_griis()` (GRIIS), and
  `add_fishmorph()` (FISHMORPH; also avoids confusion with `add_fishbase()`).
  The old names are removed, not deprecated -- they never appeared in a release.

* New `add_gift()` joins plant traits from GIFT, the Global Inventory of Floras
  and Traits (Weigelt et al. 2020), by accepted name. GIFT's API exposes only
  the subset of its data it may redistribute (CC BY 4.0; restricted references
  excluded); taxifydb fetches that subset once at build time and it ships as a
  pre-built `.vtr`, so `add_gift()` joins it offline like every other
  enrichment -- no runtime API calls. Choose which traits to attach via `cols=`
  (any `gift_` column names, or `"all"`); the default is a convenient set of
  well-populated ones (woodiness, growth form, life cycle and form, habit flags,
  height, photosynthetic pathway, seed mass, dispersal, flowering months,
  deciduousness, SLA). `gift_traits()` browses the available columns.

# taxify 0.3.1

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
