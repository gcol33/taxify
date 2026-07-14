# Add plant genome size (Kew Plant DNA C-values)

Joins plant genome-size data from the Kew Plant DNA C-values database
(Pellicer & Leitch 2020) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Records are reduced to per-species
medians.

## Usage

``` r
add_kew_cvalues(x, cols = NULL, verbose = TRUE)
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

The same data.frame with additional columns. The default set:

- cval_genome_size_1c_pg:

  Genome size (1C DNA amount, picograms).

- cval_chromosome_2n:

  Somatic chromosome number (2n).

- cval_ploidy_x:

  Ploidy level.

`cols = "all"` also attaches the per-species min/max/n spread of each
value.

## Details

Source: Kew Plant DNA C-values database, release 7.1 (Royal Botanic
Gardens Kew), CC BY. Vascular plants.

## References

Pellicer J, Leitch IJ (2020) The Plant DNA C-values database (release
7.1): an updated online repository of plant genome size data for
comparative studies. New Phytologist 226:301-305.

## Examples

``` r
if (FALSE) { # \dontrun{
# Downloads the enrichment on first use.
taxify("Zea mays", backend = "gbif") |>
  add_kew_cvalues()
} # }
```
