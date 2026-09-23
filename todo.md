# todo

## COL XR migration: when taxify follows GBIF's default taxonomy

Closed as gcol33/taxify#89 and tracked here instead, because it is gated on an
upstream change rather than on work in this repo.

GBIF has changed its default taxonomy from the GBIF Backbone Taxonomy to the
Catalogue of Life Extended Release (COL XR). The legacy backbone was last
updated in 2023 and will not be updated again. rgbif 3.9.0 makes COL XR the
default, a breaking change.

- https://data-blog.gbif.org/post/rgbif-colxr-preparation/
- https://data-blog.gbif.org/post/catalogue-of-life-taxonomic-backbone/

taxify ships both: the `gbif` backbone (legacy, numeric keys) and `colxr`
(COL XR, alpha-numeric keys such as `4R5YN`). The open question is whether
`colxr` should become the backbone `gbif_request()` builds on, and whether
`gbif` should be renamed to `gbif-legacy`.

### Why not yet

The occurrence index is still keyed on the legacy numeric IDs. Measured
2026-09-23 against api.gbif.org/v1, reproducing the figures first recorded
2026-09-23 in #89 exactly:

| key | backbone | occurrence count |
|---|---|---|
| `4R5YN` *Quercus robur* | taxify colxr | 0 |
| `5WH44` *Bellis perennis* | taxify colxr | 0 |
| `4J2J5` *Pinus sylvestris* | taxify colxr | 0 |
| `2878688` *Quercus robur* | gbif legacy | 1,725,528 |
| `3117424` *Bellis perennis* | gbif legacy | 1,107,989 |

`GET /v1/species/match?name=Quercus robur` still answers `usageKey: 2878688`,
`matchType: EXACT`.

Building a request from taxify's COL XR keys today returns nothing, silently,
which is the worst failure mode. `gbif_keys_of()` therefore refuses non-numeric
IDs and `ensure_gbif_match()` re-matches a `colxr` result against `gbif`;
`tests/testthat/test-gbif-request.R` pins both.

### Trigger to revisit

Re-run the probe. When a COL XR key returns a non-zero occurrence count, the
migration is possible:

```r
rgbif::occ_search(taxonKey = "4R5YN", limit = 0)$meta$count   # 0 on 2026-09-23
```

Without rgbif:

```bash
curl -s "https://api.gbif.org/v1/occurrence/search?taxonKey=4R5YN&limit=0"
```

### Still to pin down before switching

- whether taxify's COL XR release and GBIF's COL XR release share key values,
  or need a `gbif_to_col()` style mapping
- rgbif 3.9.0 behaviour for `pred_in("taxonKey", ...)` with both key shapes
  (it auto-detects numeric and warns)
- `n_occurrences` is carried only by the `gbif` backbone, so the pick's
  `data_score` and the expected-size report do not apply to `colxr` yet

### Checklist when the trigger fires

- [ ] Confirm COL XR keys return occurrence records
- [ ] Decide the `gbif` -> `gbif-legacy` rename. It touches
      `.backbone_registry()`, `.backbone_priority()`, both manifests, the
      `gbif-<ver>` release tags, taxifydb builders and CI, every installed data
      dir, `add_gbif_info()`, and lockfiles written by `taxify_lock()`, so it is
      a coordinated two-repo release
- [ ] Carry occurrence counts on `colxr` so `data_score` keeps working
- [ ] Update `gbif_keys_of()` to accept COL XR keys, and `vignette("gbif-requests")`

## colxr manifest entry moves backwards

`33c6ae1` sets colxr `latest` to `2026.08`, down from `2026.09`, and removes the
`source_version` field. The manifest-derived blocks in `README.md` and
`vignettes/large-scale.Rmd` are generated from that entry by
`scripts/sync-readme-stats.R`, so the shipped docs now carry the same version.
Confirm which colxr build is current before the next release.
