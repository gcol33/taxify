# Add cross-taxon body mass and metabolic rate (AnimalTraits)

Joins AnimalTraits body mass and metabolic rate data to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_animaltraits(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- animaltraits_body_mass_kg:

  Median body mass in kg.

- animaltraits_metabolic_rate_w:

  Median metabolic rate in watts.

## Details

Source: AnimalTraits (Hebert et al. 2022, CC0). Coverage: ~2k species
across arthropods, vertebrates, molluscs, and annelids. Individual-level
observations aggregated to species medians.

## References

Hebert K et al. (2022) AnimalTraits – a curated animal trait database
for body mass, metabolic rate and brain size. Scientific Data 9:265.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Drosophila melanogaster", backend = "gbif") |>
  add_animaltraits()

options(old)
```
