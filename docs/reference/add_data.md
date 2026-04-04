# Add custom data by taxonomic matching

Joins an external data source (CSV file or data.frame) to a
[`taxify()`](https://gcol33.github.io/taxify/reference/taxify.md)
result. Species names in the external data are matched through the same
backbone(s) used in the original
[`taxify()`](https://gcol33.github.io/taxify/reference/taxify.md) call,
and the join is performed on `accepted_id` — so synonyms in either
dataset resolve to the same key.

## Usage

``` r
add_data(
  x,
  data,
  species_col = NULL,
  table = NULL,
  cols = NULL,
  fuzzy = TRUE,
  fuzzy_threshold = 0.2,
  verbose = TRUE
)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gcol33.github.io/taxify/reference/taxify.md).

- data:

  One of:

  - A **data.frame** already in R.

  - A **file path** to a `.csv`, `.csv.gz`, `.xlsx`, `.sqlite`/`.db`, or
    `.vtr` file (read via vectra).

- species_col:

  Character. Name of the column in `data` that contains species names.
  If `NULL` (default), auto-detected by matching `head(10)` of each
  character column against the backbone.

- table:

  Character. Required when `data` is a SQLite file — the table name to
  read.

- cols:

  Character vector of column names from `data` to join. If `NULL`
  (default), all columns except `species_col` are joined.

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
    [`taxify()`](https://gcol33.github.io/taxify/reference/taxify.md)
    call, obtaining `accepted_id` for each row.

4.  Check for conflicting duplicates: if multiple rows in `data` resolve
    to the same `accepted_id` with different values, an error is raised.
    Exact duplicates produce a warning and are deduplicated.

5.  Left-join on `accepted_id`.

### Auto-detection

When `species_col` is not specified, `add_data()` takes the first 10
rows of each character column and runs them through
[`taxify()`](https://gcol33.github.io/taxify/reference/taxify.md). The
column with the highest match rate is selected. If no column achieves at
least 50% matches, an error is raised asking the user to specify
`species_col` explicitly.

## Examples

``` r
if (FALSE) { # \dontrun{
result <- taxify(c("Quercus robur", "Pinus sylvestris"))

# From a CSV file (auto-detect species column)
result |> add_data("my_traits.csv")

# From a SQLite database
result |> add_data("traits.sqlite", table = "plant_traits")

# From a data.frame with explicit species column
traits <- data.frame(species = c("Quercus robur", "Pinus sylvestris"),
                      height = c(30, 25))
result |> add_data(traits, species_col = "species")

# Select specific columns
result |> add_data(traits, species_col = "species", cols = "height")
} # }
```
