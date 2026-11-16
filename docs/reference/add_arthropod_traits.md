# Add arthropod life-history traits (NW European Arthropods)

Joins the Northwestern European Arthropod Life Histories dataset to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_arthropod_traits(x, cols = NULL, verbose = TRUE)
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

- arthropod_traits_arthropod_body_size_mm:

  Body size in mm.

- arthropod_traits_arthropod_dispersal:

  Dispersal ability (0–1 ratio within order).

- arthropod_traits_arthropod_voltinism:

  Mean number of generations per year.

- arthropod_traits_arthropod_fecundity:

  Fecundity (number of eggs/offspring).

- arthropod_traits_arthropod_development_d:

  Development time in days.

- arthropod_traits_arthropod_lifespan_d:

  Adult lifespan in days.

- arthropod_traits_arthropod_thermal_mean:

  Mean thermal niche (degrees C).

- arthropod_traits_arthropod_diurnality:

  Activity period (diurnal/nocturnal/both).

- arthropod_traits_arthropod_feeding_guild:

  Feeding guild of adult.

- arthropod_traits_arthropod_trophic_range:

  Trophic range of adult (specialist/generalist).

## Details

Source: Logghe et al. (2025, CC BY-NC). Coverage: ~4.9k arthropod
species from NW Europe across 10 orders (Coleoptera, Hemiptera,
Orthoptera, Araneae, Diptera, Hymenoptera, Lepidoptera, etc.).

## References

Logghe A et al. (2025) An in-depth dataset of northwestern European
arthropod life histories and ecological traits. Biodiversity Data
Journal 13:e146785.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Abax parallelepipedus", backbone = "gbif") |>
  add_arthropod_traits()
#> Matching 1 names...
#>              input_name          matched_name         accepted_name    taxon_id
#> 1 Abax parallelepipedus Abax parallelepipedus Abax parallelepipedus gbif-ex-006
#>   accepted_id    rank    family genus          epithet
#> 1 gbif-ex-006 species Carabidae  Abax parallelepipedus
#>                      authorship           accepted_authorship is_synonym
#> 1 (Piller & Mitterpacher, 1783) (Piller & Mitterpacher, 1783)      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group life_form qualifier
#> 1 gbif:example (2026-06-24)      animalia     unknown   unknown      <NA>
#>   qualifier_position aggregate_fallback hybrid_type
#> 1               <NA>                 NA        <NA>
#>   arthropod_traits_arthropod_body_size_mm arthropod_traits_arthropod_dispersal
#> 1                    example_body_size_mm                    example_dispersal
#>   arthropod_traits_arthropod_voltinism arthropod_traits_arthropod_fecundity
#> 1                    example_voltinism                    example_fecundity
#>   arthropod_traits_arthropod_development_d
#> 1                    example_development_d
#>   arthropod_traits_arthropod_lifespan_d arthropod_traits_arthropod_thermal_mean
#> 1                    example_lifespan_d                    example_thermal_mean
#>   arthropod_traits_arthropod_diurnality
#> 1                    example_diurnality
#>   arthropod_traits_arthropod_feeding_guild
#> 1                    example_feeding_guild
#>   arthropod_traits_arthropod_trophic_range
#> 1                    example_trophic_range
#> Sources: GBIF example, NW European Arthropods example | cite() for full citations

options(old)
```
