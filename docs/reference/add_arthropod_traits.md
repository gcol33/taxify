# Add arthropod life-history traits (NW European Arthropods)

Joins the Northwestern European Arthropod Life Histories dataset to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_arthropod_traits(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- arthropod_body_size_mm:

  Body size in mm.

- arthropod_dispersal:

  Dispersal ability (0–1 ratio within order).

- arthropod_voltinism:

  Mean number of generations per year.

- arthropod_fecundity:

  Fecundity (number of eggs/offspring).

- arthropod_development_d:

  Development time in days.

- arthropod_lifespan_d:

  Adult lifespan in days.

- arthropod_thermal_mean:

  Mean thermal niche (degrees C).

- arthropod_diurnality:

  Activity period (diurnal/nocturnal/both).

- arthropod_feeding_guild:

  Feeding guild of adult.

- arthropod_trophic_range:

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

taxify("Abax parallelepipedus", backend = "gbif") |>
  add_arthropod_traits()

options(old)
```
