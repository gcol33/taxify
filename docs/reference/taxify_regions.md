# List the regions accepted by `region=`

Returns every region code and name the `region` argument of
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
resolves, across both vocabularies it accepts, optionally filtered by a
search term matched (case- and accent-insensitively) against the code
and all three level names.

## Usage

``` r
taxify_regions(search = NULL, scheme = c("all", "wgsrpd", "meow"))
```

## Arguments

- search:

  Optional character string. If supplied, only regions whose code or
  name contains it are returned.

- scheme:

  Which vocabulary to list: `"all"` (the default), `"wgsrpd"` for the
  botanical regions, or `"meow"` for the marine ones.

## Value

A data.frame with columns `code`, `name`, `level2_name`, `level1_name`,
and `scheme`, one row per region.

## Details

Botanical regions (`scheme = "wgsrpd"`) come from the bundled WGSRPD
(World Geographical Scheme for Recording Plant Distributions) Level 3
crosswalk, and are also the codes
[`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md)
uses. Marine regions (`scheme = "meow"`) are the Marine Ecoregions of
the World, listed only when the `marine_distribution` asset is
installed, since that is also when `region=` resolves them. The two
schemes nest the same way, so they share the three name columns: a MEOW
ecoregion is the `name`, its province the `level2_name`, and its realm
the `level1_name`.

## Examples

``` r
head(taxify_regions())
taxify_regions("belgium")
taxify_regions("Europe")
```
