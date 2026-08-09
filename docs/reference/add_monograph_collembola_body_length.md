# Add Collembola body length (monographs)

Joins per-species springtail body length to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. The value is mined from three
primary Collembola monographs and aggregated per species: the median of
the per-monograph medians, with the observed range and the measurement
and monograph counts.

## Usage

``` r
add_monograph_collembola_body_length(x, cols = NULL, verbose = TRUE)
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

- monograph_body_length_mm:

  Body length (mm), median of the per-monograph medians.

- monograph_body_length_min_mm:

  Smallest measurement (mm).

- monograph_body_length_max_mm:

  Largest measurement (mm).

- monograph_body_length_n:

  Number of measurements aggregated.

- monograph_body_length_sources:

  Number of monographs contributing.

## Details

Source: body length mined from three primary Collembola monographs,
Stach (1957, Neelidae and Dicyrtomidae), Hopkin (2007, Britain and
Ireland) and Bretfeld (1999, Symphypleona). The source monographs are
copyright their publishers; only the extracted measurements are
redistributed, for non-commercial scientific use. Coverage: 481 species
from 679 measurements. A re-extraction independent of BETSI, more
complete than BETSI on the shared books (210 vs 145 species from
Bretfeld 1999) and reaching Stach's Neelidae and Dicyrtomidae, which
fall outside BETSI's Collembola coverage. Body length is also available
through
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)`("body_length")`.

## References

Hopkin SP (2007) A Key to the Collembola (Springtails) of Britain and
Ireland. FSC Publications, Shrewsbury.

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Isotoma viridis", backbone = "gbif") |>
  add_monograph_collembola_body_length()
} # }
```
