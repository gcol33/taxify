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
