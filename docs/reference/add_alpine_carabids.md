# Add Alpine ground-beetle traits (Chamberlain et al.)

Joins body size and wing morphology for the carabid fauna of the Italian
Alps to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by accepted name.

## Usage

``` r
add_alpine_carabids(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) both, or a character vector
  of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with `alpine_` columns: numeric `body_length_mm`,
categorical `wing_morph`.

## Details

Source: Chamberlain et al. (2020), 185 species recorded at 416 sites
between 697 and 2840 m in the Italian Alps. CC0.

The widest European carabid trait table after
[`add_chowdhury()`](https://gillescolling.com/taxify/reference/add_chowdhury.md),
and the one that reaches the Alpine fauna the lowland compilations miss.
Like every European carabid source its body sizes trace back to
carabids.org, so agreement with those is not corroboration; it runs 1.03
against them, the same quantity without being the verbatim copy
[`add_eberswalde()`](https://gillescolling.com/taxify/reference/add_eberswalde.md)
is.

`wing_morph` arrives as bare letters with no legend in the file. The
codes were read off the data rather than assumed: crossed against
[`add_chowdhury()`](https://gillescolling.com/taxify/reference/add_chowdhury.md)'s
words, `b` is short-winged, `m` long-winged and `d` dimorphic.

## References

Chamberlain D, Gobbi M, Negro M, et al. (2020) Trait-modulated decline
of carabid beetle occurrence along elevation gradients across the
European Alps. Journal of Biogeography 47:1030-1041.
[doi:10.1111/jbi.13792](https://doi.org/10.1111/jbi.13792)

Data:
[doi:10.5061/dryad.fn2z34tq1](https://doi.org/10.5061/dryad.fn2z34tq1)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify(c("Abax exaratus", "Carabus depressus")) |>
  add_alpine_carabids()
} # }
```
