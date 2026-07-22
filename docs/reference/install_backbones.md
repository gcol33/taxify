# Install taxonomic backbones for offline matching

Downloads the pre-built `.vtr` for each named backbone into the taxify
data directory
([`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md)),
so subsequent
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) calls
match against them offline. taxify installs its default set
automatically on first use (COL, GBIF, ITIS); call this to pre-install a
specific set, add a backbone to the default, or refresh to the latest
release. Already-current backbones are skipped.

## Usage

``` r
install_backbones(backbones = NULL, verbose = TRUE)
```

## Arguments

- backbones:

  Character vector of backbone names (see
  [`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md)).
  `NULL` (default) installs taxify's first-run set: COL, GBIF, and ITIS.

- verbose:

  Logical. Default `TRUE`.

## Value

Invisibly, the backbones now installed (those that downloaded
successfully), in priority order.

## See also

[`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md)
for the full set with sizes,
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

## Examples

``` r
if (FALSE) { # \dontrun{
# Pre-install a marine-focused set before matching:
install_backbones(c("col", "worms"))
} # }
```
