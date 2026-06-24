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

* `add_biolflor()` is deprecated in favour of `add_floraweb()`, which carries
  the same BiolFlor data (now bundled from FloraWeb) plus the full FloraWeb
  profile. It forwards to `add_floraweb()` with a deprecation message.

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
