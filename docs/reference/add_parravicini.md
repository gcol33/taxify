# Add reef-fish trophic guild (Parravicini)

Joins the consensus reef-fish trophic-guild assignment to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`. The guild is the modal expert classification.

## Usage

``` r
add_parravicini(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with categorical `parravicini_trophic_guild`.

## Details

Source: Parravicini et al. (2020) reef-fish trophic guilds (PLoS
Biology, CC-BY 4.0).

## References

Parravicini V et al. (2020) Delineating reef fish trophic guilds with
global gut content data synthesis and phylogeny. PLoS Biology
18:e3000702.
[doi:10.1371/journal.pbio.3000702](https://doi.org/10.1371/journal.pbio.3000702)

## Examples

``` r
# \donttest{
taxify("Zebrasoma scopas", backend = "gbif") |>
  add_parravicini()
# }
```
