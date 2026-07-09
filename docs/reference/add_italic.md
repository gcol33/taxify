# Add Italian-lichen taxon-page traits (ITALIC)

Joins per-species morphological and ecological descriptors from ITALIC,
the Information System on Italian Lichens, to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. One row per species, scraped from
the ITALIC 8.0 taxon pages.

## Usage

``` r
add_italic(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) or `"all"` attaches every
  column the source carries, or a character vector of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- growth_form:

  Thallus growth form (crustose, foliose, fruticose, ...).

- substrata:

  Substrata the species grows on.

- photobiont:

  Photosynthetic partner.

- reproductive_strategy:

  Reproductive strategy.

## Details

Source: ITALIC 8.0 (Nimis; Univ. of Trieste), taxon-page descriptors, CC
BY-SA 4.0. Lichens are otherwise almost absent from the bundled trait
databases.

## References

Nimis PL. ITALIC - The Information System on Italian Lichens, Version
8.0. University of Trieste, Dept. of Biology (https://italic.units.it),
accessed 2026-07. System paper: Martellos S, Conti M, Nimis PL (2023)
Aggregation of Italian Lichen Data in ITALIC 7.0. Journal of Fungi
9(5):556. doi:10.3390/jof9050556

## Examples

``` r
# \donttest{
taxify("Xanthoria parietina", backend = "gbif") |>
  add_italic()
# }
```
