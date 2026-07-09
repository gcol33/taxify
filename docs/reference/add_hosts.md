# Add Lepidoptera hostplant breadth (NHM HOSTS)

Joins per-insect hostplant breadth from the Natural History Museum HOSTS
database to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Each moth or butterfly species is
summarised by how many distinct hostplants and hostplant families it has
been recorded feeding on.

## Usage

``` r
add_hosts(x, cols = NULL, verbose = TRUE)
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

- host_plant_count:

  Number of distinct hostplant species recorded.

- host_family_count:

  Number of distinct hostplant families recorded.

## Details

Source: Robinson et al. (2010) HOSTS, Natural History Museum, London
(CC0). Lepidoptera only; ~24k species with at least one recorded
hostplant.

## References

Robinson GS, Ackery PR, Kitching IJ, Beccaloni GW, Hernandez LM (2010)
HOSTS - a Database of the World's Lepidopteran Hostplants. Natural
History Museum, London. doi:10.5519/havt50xw

## Examples

``` r
# \donttest{
taxify("Papilio machaon", backend = "gbif") |>
  add_hosts()
# }
```
