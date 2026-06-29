# Add elasmobranch life-history traits (Sharkipedia)

Joins Sharkipedia shark and ray life-history traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`. Long-format observations are reduced to one
value per species (numeric traits by median) at build time.

## Usage

``` r
add_sharkipedia(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- sharkipedia_lmax_cm:

  Maximum observed length (cm).

- sharkipedia_vbgf_linf_cm:

  von Bertalanffy asymptotic length Linf (cm).

- sharkipedia_vbgf_k:

  von Bertalanffy growth coefficient k (per year).

- sharkipedia_vbgf_t0:

  von Bertalanffy t0 (years).

- sharkipedia_length_first_maturity_cm:

  Length at first maturity (cm).

- sharkipedia_length_birth_cm:

  Length at birth (cm).

- sharkipedia_amax_observed_yr:

  Maximum observed age (years).

- sharkipedia_age_first_maturity_yr:

  Age at first maturity (years).

- sharkipedia_uterine_fecundity:

  Uterine fecundity.

- sharkipedia_gestation_length:

  Gestation length.

- sharkipedia_natural_mortality:

  Natural mortality M.

## Details

Source: Sharkipedia (Mull et al. 2022, Scientific Data, CC-BY 4.0).

## References

Mull CG et al. (2022) Sharkipedia: a curated open access database of
shark and ray life history traits and abundance time-series. Scientific
Data 9:559.
[doi:10.1038/s41597-022-01655-1](https://doi.org/10.1038/s41597-022-01655-1)

## Examples

``` r
# \donttest{
taxify("Carcharodon carcharias", backend = "gbif") |>
  add_sharkipedia()
# }
```
