# Add freshwater invertebrate traits (US EPA)

Joins primary functional traits of freshwater macroinvertebrates from
the U.S. EPA Freshwater Biological Traits Database to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result. Records are reduced to per-taxon modes. The database records
each trait at the finest available resolution, so the join matches
`accepted_name` first and then fills any trait still missing from the
taxon's genus-level row; a species-level value is never overwritten.

## Usage

``` r
add_epa_freshwater(x, cols = NULL, verbose = TRUE)
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

- epa_feeding_mode:

  Functional feeding group.

- epa_habit:

  Primary habit (e.g. clinger, burrower, swimmer).

- epa_voltinism:

  Number of generations per year.

- epa_thermal_preference:

  Thermal preference.

- epa_body_size_class:

  Maximum body-size class.

`cols = "all"` also attaches body shape, rheophily, oviposition
behaviour, and diapause.

## Details

Source: U.S. EPA Freshwater Biological Traits Database (2012), a
public-domain U.S. Government work, compiled primarily from Vieira et
al. (2006).

## References

U.S. Environmental Protection Agency (2012) Freshwater Biological Traits
Database. Compiled from Vieira NKM et al. (2006) A database of lotic
invertebrate traits for North America, USGS Data Series 187.

## Examples

``` r
if (FALSE) { # \dontrun{
# Downloads the enrichment on first use.
taxify("Baetis", backend = "gbif") |>
  add_epa_freshwater()
} # }
```
