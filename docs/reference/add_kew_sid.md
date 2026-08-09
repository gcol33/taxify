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

- sid_thousand_seed_weight:

  Thousand-seed weight (grams per 1000 seeds, median of all records).

- sid_storage_behaviour:

  Seed storage behaviour (Orthodox/Recalcitrant/Intermediate/Uncertain).

- sid_oil_content_pct:

  Seed oil content (percent, median).

- sid_protein_content_pct:

  Seed protein content (percent, median).

- sid_lifeform:

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

options(old)
```
