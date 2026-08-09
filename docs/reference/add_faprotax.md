# Add prokaryote metabolic and ecological functions (FAPROTAX)

Joins the function groups a prokaryotic taxon is known to perform –
methanogenesis, denitrification, nitrogen fixation, chitinolysis, human
gut association and 87 others – to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result.

## Usage

``` r
add_faprotax(x, cols = NULL, verbose = TRUE)
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

The same data.frame with `faprotax_functions` (a `|`-delimited set) and
`faprotax_n_functions`.

## Details

Source: Louca et al. (2016), 92 function groups over 4470 taxa compiled
from IJSEM and Bergey's Manual. Redistributed under FAPROTAX's own
BSD-style terms; see
[`cite`](https://gillescolling.com/taxify/reference/cite.md) for the
notice that must travel with it.

FAPROTAX annotates a taxon at whatever rank the evidence supports, so
its entries are a mix of species and genera. The join follows: a
species-level entry matches the accepted name, and a taxon with no entry
of its own inherits its genus's. Group memberships are the source's;
taxifydb reshapes the grouped list into one row per taxon and reduces
each entry to the species or genus it names, which the licence requires
be stated as a modification.

Functions stay a set rather than one label because a prokaryote
genuinely performs several: *Escherichia coli* carries 17 of them.

## References

Louca S, Parfrey LW, Doebeli M (2016) Decoupling function and taxonomy
in the global ocean microbiome. Science 353:1272-1277.
[doi:10.1126/science.aaf4507](https://doi.org/10.1126/science.aaf4507)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify(c("Escherichia coli", "Nitrosomonas europaea")) |>
  add_faprotax()
} # }
```
