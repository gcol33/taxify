# Euro+Med areas and their country codes

Lists the areas Euro+Med PlantBase states a taxon's status for, with the
ISO 3166-1 alpha-2 country code of the areas that are one country. Areas
are not countries: some combine several ("Italy, with San Marino and
Vatican City"), some are part of one (a region of European Russia, an
island group), and the level-2 areas split a combined area into its
countries (`Au(A)` Austria and `Au(L)` Liechtenstein under `Au`). Only
an area that is exactly one country carries an `iso2`.

## Usage

``` r
euromed_areas()
```

## Value

A data.frame with `area_code`, `area_name`, `area_level` and `iso2`.

## See also

[`add_euromed_distribution()`](https://gillescolling.com/taxify/reference/add_euromed_distribution.md)

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data())
euromed_areas()
#>   area_code                   area_name             area_level iso2
#> 1        Au Austria, with Liechtenstein Euro+Med 1. area level <NA>
#> 2     Au(A)                     Austria Euro+Med 2. area level   AT
#> 3     Au(L)               Liechtenstein Euro+Med 2. area level   LI
#> 4     Ga(F)                      France Euro+Med 2. area level   FR
#> 5        Ge                     Germany Euro+Med 1. area level   DE
options(old)
```
