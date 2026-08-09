# Add Collembola traits (Ellers et al. 2018)

Joins European springtail functional traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`: vertical stratification, body
size, reproduction mode and climatic preferences.

## Usage

``` r
add_ellers_collembola(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) all, or a character vector
  of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- ellers_vertical_distribution:

  Vertical stratification (soil depth class).

- ellers_body_size_mm:

  Body size (mm).

- ellers_reproduction:

  Reproduction mode (sexual or asexual).

- ellers_moisture_pref:

  Moisture preference.

- ellers_temperature_pref:

  Temperature preference.

- ellers_thermal_niche_breadth:

  Thermal niche breadth.

## Details

Source: Collembola trait table from Ellers et al. (2018), Dryad, CC0.
Coverage: 278 European Collembola species; taxonomy follows the
Checklist of the Collembola of the World. The openly licensed analogue
of the BETSI multi-trait matrices; its body size agrees with the BETSI
body-length floor at Pearson r = 0.96 over 262 shared species. The body
size is also available through
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)`("body_length")`.

## References

Ellers J, Berg MP, Dias ATC, Fontana S, Ooms A, Moretti M (2018)
Diversity in form and function: vertical distribution of soil fauna
mediates multidimensional trait variation. Journal of Animal Ecology
87:933-944.
[doi:10.1111/1365-2656.12838](https://doi.org/10.1111/1365-2656.12838)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Isotoma viridis", backbone = "gbif") |>
  add_ellers_collembola()
} # }
```
