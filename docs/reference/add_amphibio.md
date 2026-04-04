# Add amphibian life-history traits (AmphiBIO)

Joins AmphiBIO amphibian life-history and ecological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_amphibio(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- body_size_mm:

  Maximum body size in mm (snout-vent length).

- age_maturity_d:

  Age at maturity in days.

- longevity_d:

  Maximum longevity in days.

- litter_size:

  Clutch/litter size.

- reproductive_output:

  Reproductive output per year.

- offspring_size_mm:

  Offspring size in mm.

- direct_development:

  Direct development (0/1).

- larval:

  Has larval stage (0/1).

- aquatic:

  Aquatic habitat (0/1).

- fossorial:

  Fossorial habitat (0/1).

- arboreal:

  Arboreal habitat (0/1).

- diurnal:

  Diurnal activity (0/1).

- nocturnal_amphibio:

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
if (FALSE) { # \dontrun{
taxify("Bufo bufo") |>
  add_amphibio()
} # }
```
