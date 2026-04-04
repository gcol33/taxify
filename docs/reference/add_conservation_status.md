# Add conservation status

Joins IUCN Red List conservation status to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name` in the conservation status
enrichment.

## Usage

``` r
add_conservation_status(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Show download progress if enrichment data needs to be
  fetched. Default `TRUE`.

## Value

The same data.frame with an additional column:

- conservation_status:

  IUCN category: `"LC"` (Least Concern), `"NT"` (Near Threatened),
  `"VU"` (Vulnerable), `"EN"` (Endangered), `"CR"` (Critically
  Endangered), `"EW"` (Extinct in the Wild), `"EX"` (Extinct), or `NA`
  if not assessed.

## Details

Conservation status values are compiled from publicly available sources
including GBIF and the IUCN Red List API. Coverage is global across all
taxonomic groups (~166k species).

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Panthera tigris") |>
  add_conservation_status()
} # }
```
