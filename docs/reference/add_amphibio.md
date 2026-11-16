# Add amphibian life-history traits (AmphiBIO)

Joins AmphiBIO amphibian life-history and ecological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_amphibio(x, cols = NULL, verbose = TRUE)
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

- amphibio_body_size_mm:

  Maximum body size in mm (snout-vent length).

- amphibio_age_maturity_y:

  Age at maturity in years.

- amphibio_longevity_yr:

  Maximum longevity in years.

- amphibio_litter_size:

  Clutch/litter size.

- amphibio_reproductive_output:

  Reproductive output per year.

- amphibio_offspring_size_mm:

  Offspring size in mm.

- amphibio_direct_development:

  Direct development (0/1).

- amphibio_larval:

  Has amphibio_larval stage (0/1).

- amphibio_aquatic:

  Aquatic habitat (0/1).

- amphibio_fossorial:

  Fossorial habitat (0/1).

- amphibio_arboreal:

  Arboreal habitat (0/1).

- amphibio_diurnal:

  Diurnal activity (0/1).

- amphibio_nocturnal_amphibio:

  Nocturnal activity (0/1). Named `nocturnal_amphibio` to avoid
  collision with EltonTraits' `nocturnal` column.

## Details

Source: AmphiBIO (Oliveira et al. 2017, CC BY 4.0). Coverage: ~6,800
amphibian species. Amphibians only.

## References

Oliveira BF, Sao-Pedro VA, Santos-Barrera G, Penone C, Costa GC (2017)
AmphiBIO, a global database for amphibian ecological traits. Scientific
Data 4:170123.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Bufo bufo", backbone = "gbif") |>
  add_amphibio()
#> Matching 1 names...
#>   input_name matched_name accepted_name    taxon_id accepted_id    rank
#> 1  Bufo bufo    Bufo bufo     Bufo bufo gbif-ex-003 gbif-ex-003 species
#>      family genus epithet       authorship accepted_authorship is_synonym
#> 1 Bufonidae  Bufo    bufo (Linnaeus, 1758)    (Linnaeus, 1758)      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group life_form qualifier
#> 1 gbif:example (2026-06-24)      animalia      animal    animal      <NA>
#>   qualifier_position aggregate_fallback hybrid_type amphibio_body_size_mm
#> 1               <NA>                 NA        <NA>  example_body_size_mm
#>   amphibio_age_maturity_y amphibio_longevity_yr amphibio_litter_size
#> 1                       2                    40  example_litter_size
#>   amphibio_reproductive_output amphibio_offspring_size_mm
#> 1  example_reproductive_output  example_offspring_size_mm
#>   amphibio_direct_development amphibio_larval amphibio_aquatic
#> 1  example_direct_development  example_larval  example_aquatic
#>   amphibio_fossorial amphibio_arboreal amphibio_diurnal
#> 1  example_fossorial  example_arboreal  example_diurnal
#>   amphibio_nocturnal_amphibio
#> 1  example_nocturnal_amphibio
#> Sources: GBIF example, AmphiBIO example | cite() for full citations

options(old)
```
