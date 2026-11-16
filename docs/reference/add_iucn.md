# Add IUCN Red List conservation status

Joins IUCN Red List conservation status to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. This function is named after its
source, the IUCN Red List; for conservation status reconciled across
sources, use
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
once more than one source is registered for it.

## Usage

``` r
add_iucn(x, cols = NULL, verbose = TRUE)
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

  Logical. Show download progress if enrichment data needs to be
  fetched. Default `TRUE`.

## Value

The same data.frame with an additional column:

- iucn_conservation_status:

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
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Panthera tigris", backbone = "gbif") |>
  add_iucn()
#> Matching 1 names...
#>        input_name    matched_name   accepted_name    taxon_id accepted_id
#> 1 Panthera tigris Panthera tigris Panthera tigris gbif-ex-007 gbif-ex-007
#>      rank  family    genus epithet       authorship accepted_authorship
#> 1 species Felidae Panthera  tigris (Linnaeus, 1758)    (Linnaeus, 1758)
#>   is_synonym taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1      FALSE         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group life_form qualifier
#> 1 gbif:example (2026-06-24)      animalia     unknown   unknown      <NA>
#>   qualifier_position aggregate_fallback hybrid_type    iucn_conservation_status
#> 1               <NA>                 NA        <NA> example_conservation_status
#> Sources: GBIF example, IUCN Red List example | cite() for full citations

options(old)
```
