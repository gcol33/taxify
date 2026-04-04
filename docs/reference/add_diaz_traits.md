# Add seed mass and plant height (Diaz et al. 2022)

Joins species-level mean seed mass and plant height from Diaz et al.
(2022) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_diaz_traits(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- seed_mass_mg:

  Seed mass in milligrams (species-level mean).

- plant_height_m:

  Plant height in metres (species-level mean).

## Details

Source: Diaz et al. 2022, TRY File Archive (CC BY 3.0). Coverage: ~46k
plant species. Plants only.

## References

Diaz S et al. (2022) The global spectrum of plant form and function:
enhanced species-level trait data. TRY File Archive.

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Quercus robur") |>
  add_diaz_traits()
} # }
```
