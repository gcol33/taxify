# Add earthworm ecological groups (sWorm)

Joins the Bouche ecological group of an earthworm species to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by accepted name.

## Usage

``` r
add_sworm(x, cols = NULL, verbose = TRUE)
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

The same data.frame with `sworm_ecological_group`: one of `epigeic`,
`endogeic`, `anecic`, `epi-endogeic`.

## Details

Source: Phillips et al. (2021), 171 species. CC BY 4.0. Earthworms are
otherwise absent from the bundled trait sources.

The release is a community dataset covering 10,840 sites, and its one
species-level trait is the ecological group each earthworm was assigned
from feeding and burrowing behaviour. That assignment is constant within
a species across the whole compilation, so collapsing it to one row per
species loses nothing.

Abundance and wet biomass are not carried: both ship several units in
one column – individuals, individuals per m2 and per m3; grams, g/m2 and
mg/m2 – mixing a per-individual measure with a per-area density, so
neither survives aggregation to the species. The native/non-native flag
is a status at a site rather than a property of the species;
[`add_griis()`](https://gillescolling.com/taxify/reference/add_griis.md)
covers introduction status per country.

## References

Phillips HRP, Guerra CA, Bartz MLC, et al. (2021) Global data on
earthworm abundance, biomass, diversity and corresponding environmental
properties. Scientific Data 8:136.
[doi:10.1038/s41597-021-00912-z](https://doi.org/10.1038/s41597-021-00912-z)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify(c("Lumbricus terrestris", "Aporrectodea caliginosa")) |>
  add_sworm()
} # }
```
