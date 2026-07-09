# Add bacterial and archaeal strain phenotypes (BacDive)

Joins per-species microbial phenotype and growth-condition traits from
BacDive, the Bacterial Diversity Metadatabase (DSMZ), to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Strain-level records are
aggregated to one row per species (categorical traits by mode, numeric
by median); temperature and pH prefer the optimum measurement, falling
back to the growth measurement.

## Usage

``` r
add_bacdive(x, cols = NULL, verbose = TRUE)
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

- gram_stain:

  Gram reaction (positive / negative / variable).

- cell_shape:

  Cell morphology (rod, coccus, ...).

- motility:

  motile / non-motile.

- oxygen_metabolism:

  Oxygen tolerance (aerobe, anaerobe, facultative anaerobe,
  microaerophile, ...).

- cell_length_um, cell_width_um:

  Cell dimensions in micrometres.

- optimal_growth_temp_c:

  Optimal (or reported growth) temperature, C.

- optimal_growth_ph:

  Optimal (or reported growth) pH.

## Details

Source: BacDive (Reimer et al.), DSMZ, CC BY 4.0. ~18.6k bacterial and
archaeal species with at least one phenotypic trait.

## References

Reimer LC et al. (2022) BacDive in 2022: the knowledge base for
standardized bacterial and archaeal data. Nucleic Acids Research
50:D741-D746. doi:10.1093/nar/gkab961

## Examples

``` r
# \donttest{
taxify("Escherichia coli", backend = "gbif") |>
  add_bacdive()
# }
```
