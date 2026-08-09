# Add Collembola traits (Lu et al. 2025)

Joins per-species springtail functional traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Output columns are prefixed
`betsi_ct_`.

## Usage

``` r
add_betsi_collembola_traits(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) the curated set, `"all"`
  every column the source carries, or a character vector of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- betsi_ct_body_length_mm:

  Maximum body length (mm).

- betsi_ct_antenna_body_ratio:

  Antenna to body length ratio.

- betsi_ct_ocelli_number:

  Number of ocelli.

- betsi_ct_furca:

  Furca (springing organ) development.

- betsi_ct_pigment_scaled:

  Pigmentation (scaled).

- betsi_ct_reproduction:

  Reproduction mode.

- betsi_ct_stratification_scaled:

  Vertical stratification (scaled).

- betsi_ct_trophic_position:

  Trophic position.

- betsi_ct_life_form:

  Life form (after Potapov et al. 2016).

## Details

Source: per-species Collembola traits from Lu et al. (2025), Appendix
S1. The morphological traits (body size, antenna/body ratio, furca,
pigmentation, ocelli, reproduction) are derived from the BETSI database
(Pey et al. 2014); vertical stratification and trophic position were
measured in that study and the life form assigned after Potapov et al.
(2016). Coverage: 26 species. Body length is also available through
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)`("body_length")`.

## References

Lu J-Z et al. (2025) Mixed forests with native species mitigate impacts
of introduced Douglas fir on soil decomposers (Collembola). Ecological
Applications 35:e70034.
[doi:10.1002/eap.70034](https://doi.org/10.1002/eap.70034)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Isotoma viridis", backbone = "gbif") |>
  add_betsi_collembola_traits()
} # }
```
