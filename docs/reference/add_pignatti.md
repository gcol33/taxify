# Add Italian plant traits from Pignatti (on demand, via TR8)

Fetches Italian Ellenberg-type indicator values, life form, and
chorotype from Pignatti's Flora d'Italia (Pignatti, Menegoni &
Pietrosanti 2005) for the species in a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result, using the TR8 package, and joins them by `accepted_name`. TR8
ships these values bundled, so this works offline.

## Usage

``` r
add_pignatti(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- light_it, temperature_it, continentality_it, moisture_it, reaction_it,
  nutrients_it, salinity_it:

  Ellenberg-type indicator values calibrated for the Italian flora
  (codes; `X` = indifferent, `0` = not applicable).

- life_form_it:

  Life form for the Italian flora.

- chorotype_it:

  Chorological type (distribution).

## Details

These values originate in a copyrighted publication, so taxify does not
redistribute them. This function reads the copy bundled in the suggested
package TR8 (which redistributes it under TR8's GPL, with attribution);
taxify ships none of it and no internet access is required. For
European-calibration indicator values see
[`add_eive()`](https://gillescolling.com/taxify/reference/add_eive.md).

## References

Pignatti S, Menegoni P, Pietrosanti S (2005) Bioindicazione attraverso
le piante vascolari. Braun-Blanquetia 39. Bocci G (2015) TR8: an R
package for easily retrieving plant species traits. Methods in Ecology
and Evolution 6:347-350.

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data())

# \donttest{
# add_pignatti() fetches Italian trait data on demand via the TR8 package.
taxify("Abies alba") |>
  add_pignatti()
# }

options(old)
```
