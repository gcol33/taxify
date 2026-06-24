# Add custom data by taxonomic matching

Joins an external data source (CSV file or data.frame) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result. Species names in the external data are matched through the same
backbone(s) used in the original
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call,
and the join is performed on `accepted_id` — so synonyms in either
dataset resolve to the same key.

## Usage

``` r
add_data(
  x,
  data,
  species_col = NULL,
  table = NULL,
  sheet = NULL,
  start_row = NULL,
  cols = NULL,
  group_col = NULL,
  groups = "all",
  fuzzy = TRUE,
  fuzzy_threshold = 0.2,
  verbose = TRUE
)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- data:

  One of:

  - A **data.frame** already in R.

  - A **file path** to a `.csv`, `.csv.gz`, `.tsv`, `.tsv.gz`, `.xlsx`,
    `.sqlite`/`.db`, or `.vtr` file (read via vectra).

- species_col:

  Character. Name of the column in `data` that contains species names.
  If `NULL` (default), auto-detected by matching `head(10)` of each
  character column against the backbone.

- table:

  Character. Required when `data` is a SQLite file — the table name to
  read.

- sheet:

  Integer or character. Sheet to read when `data` is an `.xlsx` file.
  Default `NULL` (auto-detect the sheet containing species names). Set
  explicitly to skip auto-detection.

- start_row:

  Integer. Row where column headers begin in an `.xlsx` file. Default
  `NULL` (auto-detect by scanning the first 20 rows for a header row
  that produces species name matches). Set explicitly when the layout is
  known.

- cols:

  Character vector of column names from `data` to join. If `NULL`
  (default), all columns except `species_col` are joined.

- group_col:

  Character or `NULL`. Column in `data` that defines groups (e.g.,
  country codes, regions). When set, the output is pivoted to wide
  format with one column per group (e.g., `trait_AT`, `trait_DE`), just
  like the built-in grouped enrichments. Use
  [`taxify_long()`](https://gillescolling.com/taxify/reference/taxify_long.md)
  to reshape back to long format. Default `NULL` (flat join, one row per
  species).

- groups:

  Character vector or `"all"`. Which groups to include when `group_col`
  is set. Default `"all"`.

- fuzzy:

  Logical. Enable fuzzy matching for names in `data`. Default `TRUE`.

- fuzzy_threshold:

  Numeric. Maximum allowed distance for fuzzy matches. Default `0.2`.

- verbose:

  Logical. Default `TRUE`.

## Value

The input data.frame with additional columns from `data`, joined via
backbone-resolved `accepted_id`. Columns from `data` that collide with
existing columns in `x` are prefixed with `"data_"`.

## Details

The workflow:

1.  Read `data` (CSV or data.frame).

2.  Identify the species column (explicit or auto-detected).

3.  Match species names through the same backbone(s) as the original
    [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
    call, obtaining `accepted_id` for each row.

4.  Check for conflicting duplicates: if multiple rows in `data` resolve
    to the same `accepted_id` with different values, an error is raised
    (unless `group_col` is set). Exact duplicates produce a warning and
    are deduplicated.

5.  Left-join on `accepted_id`.

### Grouped data

When your data has multiple rows per species (e.g., one row per species
per country), set `group_col` to produce wide output with suffixed
columns. This is the same format as the built-in grouped enrichments.

### Auto-detection

When `species_col` is not specified, `add_data()` takes the first 10
rows of each character column and runs them through
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md). The
column with the highest match rate is selected. If no column achieves at
least 50% matches, an error is raised asking the user to specify
`species_col` explicitly.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

result <- taxify(c("Quercus robur", "Pinus sylvestris"))
traits <- data.frame(species = c("Quercus robur", "Pinus sylvestris"),
                     height = c(30, 25))
result |> add_data(traits, species_col = "species")

options(old)
```
