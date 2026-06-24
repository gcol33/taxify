# Reshape grouped enrichment columns to long format

Converts wide-format columns produced by grouped enrichments (e.g.,
`invasive_status_AT`, `invasive_status_DE`) back to long format with one
row per species x group combination.

## Usage

``` r
taxify_long(x, cols = NULL, group_col = NULL, drop_na = FALSE)
```

## Arguments

- x:

  A data.frame, typically a
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  result after applying a grouped enrichment like
  [`add_invasive_status()`](https://gillescolling.com/taxify/reference/add_invasive_status.md),
  [`add_alien_first_records()`](https://gillescolling.com/taxify/reference/add_alien_first_records.md),
  or
  [`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md).

- cols:

  Character vector of base column names to reshape. These are the column
  names without the group suffix (e.g., `"invasive_status"`, not
  `"invasive_status_AT"`). If omitted, auto-detected from the enrichment
  metadata stamped by the `add_*()` functions.

- group_col:

  Character. Name for the output group column. If omitted, auto-detected
  from enrichment metadata (e.g., `"country_code"` for invasive status
  or alien first records).

- drop_na:

  Logical. If `TRUE`, drop rows where all value columns are `NA`.
  Default `FALSE`.

## Value

A data.frame in long format. All columns from `x` that are not part of
the reshape are preserved. The reshaped columns use their base names
(without suffix), and a new `group_col` column contains the group code
extracted from the suffix.

## Details

When `cols` and `group_col` are omitted, `taxify_long()` reads the
reshape metadata attached by grouped enrichment functions
([`add_invasive_status()`](https://gillescolling.com/taxify/reference/add_invasive_status.md),
[`add_alien_first_records()`](https://gillescolling.com/taxify/reference/add_alien_first_records.md),
[`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md),
[`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md)).
If multiple grouped enrichments were applied, all are reshaped together
(they must share the same group column).

Column matching uses the explicit base names in `cols` to avoid
ambiguity. For example, given
`cols = c("alien_first_record", "alien_first_record_source")`, the
column `alien_first_record_source_AT` is correctly matched to base
`alien_first_record_source` (not `alien_first_record` with suffix
`source_AT`), because longer base names are matched first.

If the columns in `x` exactly match `cols` (no suffixed variants), the
data is already in single-group format. In this case, the data.frame is
returned unchanged with `group_col` set to `NA`.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

# Auto-detected: no cols or group_col needed
taxify("Robinia pseudoacacia") |>
  add_alien_first_records(country = c("AT", "DE")) |>
  taxify_long()

# Explicit: override auto-detection
taxify("Robinia pseudoacacia") |>
  add_invasive_status(country = c("AT", "DE")) |>
  taxify_long(cols = "invasive_status", group_col = "country")

options(old)
```
