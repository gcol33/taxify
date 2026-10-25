# Information: taxify

Anchors: `@p:readme.<slug>`, `@p:desc.<slug>`, `@p:vig.<article>.<slug>`, `?fn` for a help page. Article slugs are the file names in `vignettes/` (`taxify` is Get started).

## Relation

### taxize-worldflora
- forms: the name-resolution step of taxize and WorldFlora, run offline against local backbone files
- as: the same task (a vector of names in, matched and accepted names out) done against downloaded, versioned files
- avoid: "replaces taxize" (taxify does not cover taxize's non-name functions, and the reader decides what to replace); "a faster WorldFlora"; "unlike taxize, ..." in the README or Get started; any wording that casts the other packages as slow, outdated or broken (`docs-style`, Voice)
- stated-at: @p:desc.claim; @p:readme.relation; ?taxify-package; @p:vig.migration.opener
- home: vignettes/migration.Rmd

## Terms

### backbone
- forms: backbone; backbones
- as: a published taxonomic database (names, their status, the accepted name of each synonym, the classification) stored as one file on disk
- defined: @p:readme.claim (plain words); @p:vig.taxify.backbones; @p:vig.backbones.opener
- avoid: "backend" in reader-facing text (it names the internal `taxify_backend` handle); "database" for a backbone alone

### accepted-name
- forms: accepted name
- as: the name a backbone currently uses for a taxon; a synonym points to it
- defined: known to the audience; glossed at @p:vig.taxify.match-result

### synonym
- forms: synonym
- as: a name the backbone holds that points to a different accepted name
- defined: known

### match-type
- forms: `match_type`; exact, exact_ci, abbrev, fuzzy, none, and the rarer rank_fallback, basionym, short_name, hybrid_formula
- as: how an input reached its matched name
- defined: @p:vig.taxify.match-result (the five common ones); vignettes/fuzzy-matching.Rmd (all); ?taxify (Value)

### fuzzy-match
- forms: fuzzy match; fuzzy matching; `fuzzy_dist`
- as: a match to the closest backbone name within the same genus when no exact match exists; `fuzzy_dist` is the edit distance divided by the length of the longer name
- defined: @p:vig.taxify.match-result; home @p:vig.fuzzy-matching
- default: `fuzzy_threshold = 0.2`, about one edit per five characters (?taxify)

### fallback-chain
- forms: fallback chain; chain
- as: several backbones tried in order; a name matched by an earlier backbone is not matched again, and every backbone is asked for an exact match before any is asked for a fuzzy one
- defined: vignettes/backbones.Rmd; glossed at @p:readme.backbones
- avoid: "cascade" as a second word for it

### default-backbones
- forms: the default set; COL, GBIF and ITIS
- as: what the first `taxify()` call installs when nothing is installed; about 4 GB
- home: ?taxify (`backbone`); stated-at: @p:readme.install-note; @p:vig.taxify.backbones

### multiple-ids
- forms: `n_ids`; `accepted_ids`; more than one accepted ID
- as: the number of accepted taxa a matched spelling could denote, and their IDs (the pick first); the `taxify_multiple_ids` warning names such inputs once per call
- defined: @p:vig.taxify.ids; home @p:vig.fuzzy-matching
- avoid: "ambiguous" as the column name (the old `is_ambiguous` column is gone); `inspect()` and `reconcile()` still label such rows "ambiguous", which is their label, not a column

### enrichment
- forms: published dataset (plain words); enrichment (the API word: `list_enrichments()`, `taxify_download_enrichment()`); `add_<source>()` function
- as: a published trait, status or distribution dataset prepared as a file keyed on accepted names, attached by its own `add_<source>()` function
- defined: @p:vig.taxify.enrich (plain words); home vignettes/enrichments.Rmd
- avoid: "door" (internal jargon); "layer" as a third word

### trait
- forms: trait; `add_trait()`
- as: one quantity or category (seed mass, woodiness) gathered from every registered source that carries it, units harmonized
- defined: vignettes/enrichments.Rmd

### region
- forms: region; `region`; `coords`
- as: a TDWG botanical region or a marine ecoregion used to prefer fuzzy candidates that occur there
- defined: vignettes/regions.Rmd
- avoid: "geographic filter" (exact matches are never filtered)

### vegetation-unit
- forms: vegetation unit; syntaxon, syntaxa (once, at the definition)
- as: a named unit of a vegetation classification (class, order, alliance, association)
- defined: @p:readme.vegetation; home vignettes/vegetation-units.Rmd

### version-record
- forms: `backbone_version`; lockfile; `taxify_lock()`, `taxify_restore()`
- as: the backbone name, release and download date on every row; a JSON file of the versions and file checksums behind a result
- defined: @p:vig.taxify.record; home vignettes/backbones.Rmd (Versions and reproducibility)

### vectra
- forms: vectra
- as: the column-store package taxify reads its backbone files with
- defined: at first mention per document, in one clause; linked to https://gillescolling.com/vectra/ (the URL in the vectra repository's DESCRIPTION; read again before linking)

## Quantities

### backbone-count
- metric: number of taxon backbones; vegetation-unit backbones
- value: 19; 2
- source: `.backbone_registry()` in R/backbones.R; `list_backbones()`
- stated-at: @p:desc.claim; @p:readme.claim; @p:vig.taxify.where-next; vignettes/backbones.Rmd

### enrichment-count
- metric: number of published datasets in the manifest
- source: `list_enrichments()`; `inst/manifest_v3.json`; the `manifest:enrichment-count` marker in README
- note: computed at render time in README.Rmd, never typed

### default-download
- metric: size of the first-run install (COL + GBIF + ITIS)
- value: about 4 GB
- source: manifest sizes (COL 2.1 GB, GBIF 1.7 GB, ITIS 206 MB in the README backbone table)

### worldflora-benchmark
- metric: wall time to load WFO and match 1,000 accepted binomials exactly and with one substituted character per epithet; peak R heap
- population: 1,000 binomials sampled from WFO 2026.06 with seed 20260722; fuzzy corpus 1,000 and 5,000
- values: taxify load 4.9 s, exact 2.2 s, fuzzy 18.8 s (5,000: 26.6 s), peak 678 MB; WorldFlora load 20.1 s, exact 17.1 s, fuzzy 4,192 s, peak 4.0 GB
- source: scripts/benchmark-worldflora.R; scripts/benchmark-worldflora-results.json (git dc9aaa1)
- version: taxify 0.3.21, vectra 0.11.7, WorldFlora 1.14.5, R 4.6.0, Windows 11, 2026-07-22
- home: vignettes/migration.Rmd, which reads the values from the file at knit time
- note: re-run 2026-10-13; the script's header says both packages read one WFO snapshot, but taxify reads the installed WFO backbone and WorldFlora the Zenodo file named in the script, so the article states each separately
- note: the README states no head-to-head timing (`docs-style`, Voice); it links the comparison article

### scale-benchmark
- metric: wall time of `taxify(backbone = "wfo")` on 1,000, 10,000 and 100,000 accepted WFO binomials, as they are and with one character changed in every tenth epithet; backbone load time
- population: names sampled from the installed WFO backbone, seed 20261013
- source: scripts/benchmark-scale.R; scripts/benchmark-scale-results.json (machine, versions and date recorded in the file)
- home: vignettes/large-scale.Rmd, which reads the values from the file at knit time
- stated-at: README Large lists (no number, a link)

### memory-benchmark
- metric: resident set size above an R session with taxify loaded, after loading WFO, COL or GBIF and after matching 5,000 names exactly and with typos
- source: scripts/benchmark-memory.R; scripts/benchmark-memory-results.json
- home: vignettes/large-scale.Rmd, read at knit time
- note: the old large-scale vignette attributed the 2026-07 run to taxify 0.3.21; the file recorded 0.3.6. Re-run 2026-10-13.

### agreement-worldflora
- metric: accepted names equal in taxify and WorldFlora for the same names
- population: 300 species-rank WFO names, seed 20261013, exact matching
- value: 277 agree, 18 differ (13 with n_ids > 1), 5 unmatched in WorldFlora
- source: scripts/agreement-worldflora.R; scripts/agreement-worldflora-results.json
- stated-at: @p:readme.trust; vignettes/migration.Rmd (read from the file at knit time)

## Defaults

### fuzzy-threshold
- argument: taxify(fuzzy_threshold = 0.2)
- home: ?taxify
- stated-at: @p:vig.fuzzy-matching; @p:vig.taxify.match-result ("within the threshold", no value)

### backbone-null
- argument: taxify(backbone = NULL): every installed backbone in priority order; COL, GBIF and ITIS installed on first use
- home: ?taxify
- stated-at: @p:readme.install-note; @p:vig.taxify.backbones; vignettes/backbones.Rmd

## Placement
- The per-source detail of the old enrichments vignette (columns, codes, coverage of each dataset) belongs in each `add_<source>()` help page and the databases article, not in the how-to.
- The WorldFlora timings leave the README and Get started for the comparison article.
- The animated canvas figures of the old Get started looped without a pause control; removed.
- The per-backbone descriptions (scope, source format, licence) of the old backbones vignette moved to the databases catalogue, generated from the manifest and `list_backbones()` (which gained `title`).
- Vegetation-unit matching moved from the backbones vignette to vignettes/vegetation-units.Rmd.
- The genus-register explanation moved to vignettes/fuzzy-matching.Rmd (Names no backbone matches), where `out_of_scope` is decided.
- The coverage table and the per-taxon "recommended stacks" of the old enrichments vignette were not carried over: their counts had no source in the repo. Scope per dataset is on each help page; the catalogue lists version, licence and reference.
- Unsourced claims dropped from the old articles: the 95-99 % exact-match share, the bimodal `fuzzy_dist` rule of thumb, the species counts of *Poa* and *Carex*, the *Pinus nigra* back-match sample.

## Status of other packages
Read 2026-10-13 from their CRAN pages.
- taxize 0.10.1, on CRAN (published 2026-02-14). The project notes calling it removed from CRAN are out of date.
- WorldFlora 1.14-5, on CRAN (published 2024-09-10).
- taxadb 0.3.0, on CRAN.
- rWCVP: archived on CRAN 2025-11-28.
- Taxonstand: archived on CRAN 2023-12-15 at the maintainer's request; the CRAN page recommends WorldFlora.
- lcvplants: GitHub only (idiv-biodiversity/lcvplants); README lists `lcvp_search()`, `lcvp_fuzzy_search()` / `lcvp_fuzzy_match()` (inconsistent there), `lcvp_match()`, `lcvp_join()`.
