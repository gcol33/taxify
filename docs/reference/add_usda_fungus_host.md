# Add fungal host breadth (USDA Fungus-Host Dataset)

Joins per-fungus host breadth from the USDA National Fungus Collections
Fungus-Host Dataset to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Each fungus species is summarised
by how many distinct host plants and host plant genera it has been
recorded on.

## Usage

``` r
add_usda_fungus_host(x, cols = NULL, verbose = TRUE)
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

The same data.frame with additional columns:

- fungus_host_count:

  Number of distinct host plant species recorded.

- fungus_host_genus_count:

  Number of distinct host plant genera recorded.

## Details

Source: Farr, Rossman & Castlebury (2021) United States National Fungus
Collections Fungus-Host Dataset, Ag Data Commons (U.S. Public Domain).
Fungi only; ~99k species with at least one recorded host.

## References

Farr DF, Rossman AY, Castlebury LA (2021) United States National Fungus
Collections Fungus-Host Dataset. Ag Data Commons.
doi:10.15482/USDA.ADC/1524414

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Puccinia graminis", backbone = "gbif") |>
  add_usda_fungus_host()
} # }
```
