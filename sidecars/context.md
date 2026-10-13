# Context: taxify

## Standing

### taxize
- released: on CRAN, version 0.10.1 published 2026-02-14 (CRAN package page, read 2026-10-13)
- review: method paper Chamberlain and Szöcs 2013, F1000Research 2: 191 (`citation("taxize")`); software review status not checked
- use:
- maintainers: rOpenSci (docs.ropensci.org/taxize, from its DESCRIPTION `URL:`)

### WorldFlora
- released: on CRAN, version 1.14-5 published 2024-09-10 (CRAN package page, read 2026-10-13)
- review: Kindt 2020, Applications in Plant Sciences 8(9): e11388, doi:10.1002/aps3.11388 (Crossref, read 2026-10-13)
- use:
- maintainers: Roeland Kindt

### taxify
- released: on CRAN since 0.6.0 (2026-09-30, doi:10.32614/CRAN.package.taxify); repository at 0.7.0
- review: none yet
- use:
- validation: the testthat suite; `scripts/agreement-worldflora.R` (300 WFO names, accepted names compared with WorldFlora); the knitted articles, run against the installed backbones

### burden
- taxify shows agreement with WorldFlora on the same names and states where and why it differs; taxize and WorldFlora are never asked to justify themselves.

## Debt
- taxize: the verbs and their names (`synonyms()`, `children()`, `downstream()`, `upstream()`, `class2tree()`, `lowest_common()`, `sci2comm()`, `comm2sci()`, `id2name()`).
- WorldFlora: the workflow of exact then fuzzy matching against WFO and keeping one row per name (`WFO.match()` + `WFO.one()`).
- The backbones themselves are the work of their publishers (WFO consortium, COL, GBIF, ...), credited through `cite()`.
- credit: first paragraph of vignettes/migration.Rmd, with both citations; the relation phrase in DESCRIPTION, README, `?taxify-package`.

## Use case
- A species list matched against several backbones at once, from local files, with one accepted name per row and the backbone version recorded, then joined to published datasets on the accepted name.

### novelty claims
- claim: "run offline against local backbone files" (relation phrase)
- parent-does: WorldFlora also matches against a local WFO file read into memory; taxize queries web services.
- precise-form: the README and the comparison article name the backbone count (19) and the single call; neither says WorldFlora needs the network.

## Discrepancies

### record-choice
- kind: design
- behaviour: for a spelling with several accepted taxa, `WFO.one()` keeps one candidate row; taxify keeps its pick and lists the others in `accepted_ids`. 13 of the 18 differing names in the agreement sample have `n_ids` above 1.
- evidence: scripts/agreement-worldflora.R, scripts/agreement-worldflora-results.json
- doc: vignettes/migration.Rmd, Differences

### spelling-distance
- kind: design
- behaviour: WorldFlora `Fuzzy` and taxify `fuzzy_threshold` measure distance differently; taxify makes Latin spelling variants equal before fuzzy matching (*Pinus silvestris*: exact_ci in taxify, fuzzy in WorldFlora).
- evidence: the four-name example in the agreement file
- doc: vignettes/migration.Rmd, Differences

### wfo-release
- kind: reference-data
- behaviour: taxify reads its WFO backbone (2026.06); WorldFlora reads the classification file of the Zenodo release in scripts/benchmark-worldflora.R. These can differ.
- evidence: both result files record the two sources
- doc: vignettes/migration.Rmd, Agreement and Differences

No upstream defects in taxize or WorldFlora are described in the docs.

## Evidence scope

### agreement-worldflora
- shows: on 300 species-rank WFO names, exact matching only, 277 accepted names agree, 18 differ, 5 are unmatched in WorldFlora's file
- does-not-show: agreement on misspelt names, infraspecific names, names outside WFO, or on the same WFO release
- stated-at: vignettes/migration.Rmd, "The comparison covers exact matching of species names ..."

### benchmark-worldflora
- shows: time for 1,000 WFO binomials, exact and with one changed letter, on one machine
- does-not-show: which result is right; WorldFlora returns every candidate within the threshold, more work than a single pick
- stated-at: vignettes/migration.Rmd, Timings against WorldFlora

### benchmark-scale, benchmark-memory
- shows: taxify time and memory for 1,000 to 100,000 WFO names on one machine
- does-not-show: other backbones' times, or other machines
- stated-at: vignettes/large-scale.Rmd

## Framing
- open-with: WorldFlora's closest equivalent (`WFO.match()` + `WFO.one()`) on the same names, then taxify, with agreement measured
- organising question: where taxify and WorldFlora agree on WFO names, and where results change and why
- avoid: "replaces taxize", "faster than", "drop-in", a title that assumes migration ("Coming from ..."), a completeness claim after the timing table
