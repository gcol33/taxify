# Add North American ground-beetle elytra measurements (Imageomics / NEON)

Joins per-species elytra measurements, taken from images of pinned NEON
specimens, to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by accepted name.

## Usage

``` r
add_imageomics_neon(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) all of them, or a character
  vector of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with `neon_` columns: numeric `elytra_length_mm`,
`elytra_width_mm`, and `measurement_n` (the number of individual
measurements behind the median).

## Details

Source: the Imageomics `2018-NEON-beetles` dataset, 39,064 measurements
of pinned individuals across 30 NEON sites, reduced to a per-species
median over 75 named species.

This is the only North American ground-beetle morphometry taxify
carries, and the only carabid measurement source independent of
carabids.org, whose values every European carabid table inherits.

The source measures the elytron rather than the whole animal, in
centimetres; values here are millimetres. Measurements of specimens
photographed at an angle (`lying_flat = "No"`) are excluded, since a
projected length is foreshortened. The length-to-width ratio has a
median of 1.79 across species, the shape of a carabid elytron, and
*Carabus nemoralis* reads 14.87 mm against the 23.4 mm body length that
[`add_finand()`](https://gillescolling.com/taxify/reference/add_finand.md)
measured on European specimens.

## References

Imageomics Institute. 2018-NEON-beetles. Hugging Face.
<https://huggingface.co/datasets/imageomics/2018-NEON-beetles>

## Examples

``` r
if (FALSE) { # \dontrun{
taxify(c("Carabus nemoralis", "Pasimachus californicus")) |>
  add_imageomics_neon()
} # }
```
