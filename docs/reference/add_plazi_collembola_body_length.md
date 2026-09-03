# Add Collembola body length (Plazi treatments)

Joins per-species springtail body length to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. The value is mined from Plazi
taxonomic treatments and aggregated per species: the median, with the
observed range and the measurement and treatment-paper counts.

## Usage

``` r
add_plazi_collembola_body_length(x, cols = NULL, verbose = TRUE)
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

- plazi_body_length_mm:

  Body length (mm), median of the mined measurements.

- plazi_body_length_min_mm:

  Smallest measurement (mm).

- plazi_body_length_max_mm:

  Largest measurement (mm).

- plazi_body_length_n:

  Number of measurements aggregated.

- plazi_body_length_sources:

  Number of distinct treatment papers.

## Details

Source: Plazi TreatmentBank (plazi.org), taxonomic treatments
republished as Darwin Core Archives through GBIF, CC0 1.0. Coverage: 998
species from 1,117 measurements. On the 35 species it shares with the
BETSI body-length floor the mined values track BETSI at Pearson r =
0.906 (Spearman 0.955), and it adds 963 species BETSI does not cover.
Cite the individual treatments for any species-level use. Body length is
also available through
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)`("body_length")`.

## References

Plazi TreatmentBank. <https://plazi.org/>

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Isotoma viridis", backbone = "gbif") |>
  add_plazi_collembola_body_length()
} # }
```
