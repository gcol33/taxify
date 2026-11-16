# Add seed traits from the Kew Seed Information Database (SER-SID)

Joins species-level seed traits from the Kew Seed Information Database
(SER-SID) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_kew_sid(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) the curated set, `"all"`
  every column the source carries, or a character vector of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns. The curated set:

- kew_sid_sid_thousand_seed_weight:

  Thousand-seed weight (grams per 1000 seeds, median of all records).

- kew_sid_sid_storage_behaviour:

  Seed storage behaviour (Orthodox/Recalcitrant/Intermediate/Uncertain).

- kew_sid_sid_oil_content_pct:

  Seed oil content (percent, median).

- kew_sid_sid_protein_content_pct:

  Seed protein content (percent, median).

- kew_sid_sid_lifeform:

  Raunkiaer life-form code as recorded by SID.

With `cols = "all"` the seed-weight record count
(`n_seed_weight_records`) and modal `fruit_type` are also attached under
their source names. Joined on `accepted_name`.

## Details

Source: Royal Botanic Gardens Kew, Seed Information Database, served as
SER-SID (<https://ser-sid.org/>), CC BY 2.0. Per-record measurements are
reduced to per-species medians (numeric) and modes (categorical); a
thousand-seed weight in grams equals the per-seed mass in milligrams.

## References

Royal Botanic Gardens Kew. Seed Information Database (SID).
<https://ser-sid.org/>

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus robur", backbone = "gbif") |>
  add_kew_sid()
#> Matching 1 names...
#> add_kew_sid(): attaching 5 of 7 columns. Pass cols = "all" for all, or see enrichment_cols("kew_sid").
#>      input_name  matched_name accepted_name    taxon_id accepted_id    rank
#> 1 Quercus robur Quercus robur Quercus robur gbif-ex-001 gbif-ex-001 species
#>     family   genus epithet authorship accepted_authorship is_synonym
#> 1 Fagaceae Quercus   robur         L.                  L.      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group  life_form qualifier
#> 1 gbif:example (2026-06-24)       plantae  angiosperm angiosperm      <NA>
#>   qualifier_position aggregate_fallback hybrid_type
#> 1               <NA>                 NA        <NA>
#>   kew_sid_sid_thousand_seed_weight kew_sid_sid_oil_content_pct
#> 1                               11                          11
#>   kew_sid_sid_protein_content_pct kew_sid_sid_storage_behaviour
#> 1                              11     example_storage_behaviour
#>   kew_sid_sid_lifeform
#> 1     example_lifeform
#> Sources: GBIF example, Kew Seed Information Database (SID) example | cite() for full citations

options(old)
```
