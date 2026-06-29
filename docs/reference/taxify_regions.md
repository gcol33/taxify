# List TDWG botanical regions

Returns the bundled WGSRPD (World Geographical Scheme for Recording
Plant Distributions) Level 3 crosswalk: the botanical-country codes and
names used by the `region` argument of
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) and
by
[`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md).
Optionally filtered by a search term matched (case- and
accent-insensitively) against the code and the Level 1, 2, and 3 names.

## Usage

``` r
taxify_regions(search = NULL)
```

## Arguments

- search:

  Optional character string. If supplied, only regions whose code or
  name contains it are returned.

## Value

A data.frame with columns `code`, `name`, `level2_name`, and
`level1_name`, one row per Level 3 region.

## Examples

``` r
head(taxify_regions())
taxify_regions("belgium")
taxify_regions("Europe")
```
