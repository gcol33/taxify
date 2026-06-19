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
