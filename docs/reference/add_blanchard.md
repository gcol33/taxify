# Add ant genus defensive traits (Blanchard & Moreau)

Joins genus-level ant defensive and ecological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `genus`.

## Usage

``` r
add_blanchard(x, cols = NULL, verbose = TRUE)
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

The same data.frame with `blanchard_` columns: categorical `subfamily`,
`spines`, `sting`, `diet`, `nesting`, `foraging`; numeric
`colony_size_workers` (joined on genus).

## Details

Source: Blanchard & Moreau (2017) ant defensive traits (Dryad, CC0).
Joins on genus because the database is genus-resolved.

## References

Blanchard BD, Moreau CS (2017) Defensive traits in the ant genera
database. Dryad.
[doi:10.5061/dryad.st6sc](https://doi.org/10.5061/dryad.st6sc)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Camponotus pennsylvanicus", backbone = "gbif") |>
  add_blanchard()
} # }
```
