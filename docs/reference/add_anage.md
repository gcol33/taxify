# Add longevity and life-history traits (AnAge)

Joins AnAge (Animal Ageing and Longevity Database) traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_anage(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- max_longevity_yr:

  Maximum longevity in years.

- anage_body_mass_g:

  Adult body mass in grams.

- metabolic_rate_w:

  Basal metabolic rate in watts.

- female_maturity_d:

  Female age at sexual maturity in days.

- male_maturity_d:

  Male age at sexual maturity in days.

- gestation_incubation_d:

  Gestation or incubation length in days.

- anage_litter_size:

  Litter or clutch size.

- birth_mass_g:

  Mass at birth in grams.

- growth_rate:

  Growth rate (1/days).

- temperature_k:

  Body temperature in Kelvin.

## Details

Source: AnAge (de Magalhaes & Costa 2009, CC BY). Coverage: ~4.7k
vertebrate species (mammals, birds, reptiles, amphibians, fish).

## References

de Magalhaes JP, Costa J (2009) A database of vertebrate longevity
records and their relation to other life-history traits. Journal of
Evolutionary Biology 22:1770-1774.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Vulpes vulpes", backend = "gbif") |>
  add_anage()

options(old)
```
