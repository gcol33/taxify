# Add British and Irish plant attributes (PLANTATT)

Joins attributes of British and Irish vascular plants (Hill et al. 2004)
to a [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_plantatt(x, cols = NULL, verbose = TRUE)
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

- plantatt_ellenberg_light, plantatt_ellenberg_moisture,
  plantatt_ellenberg_reaction, plantatt_ellenberg_nitrogen,
  plantatt_ellenberg_salt:

  Ellenberg indicator values calibrated for the British flora.

- plantatt_max_height_cm:

  Maximum height, cm.

- plantatt_life_form:

  Life-form code, kept verbatim (`Ch`, `Ph`, `Gn`, ...).

- plantatt_woodiness:

  Woodiness code, kept verbatim (`w` woody, `h` herbaceous, `sw`
  semi-woody).

- plantatt_native_status:

  Native-status code, kept verbatim (`N` native, `AN` alien naturalised,
  `AR` archaeophyte, ...).

## Details

1,887 taxa. For the German-flora equivalent see
[`add_floraweb()`](https://gillescolling.com/taxify/reference/add_floraweb.md),
for the British Ecoflora traits
[`add_ecoflora()`](https://gillescolling.com/taxify/reference/add_ecoflora.md),
and for European-calibration indicator values
[`add_eive()`](https://gillescolling.com/taxify/reference/add_eive.md).

This source states no licence (it is copyright the Biological Records
Centre), so taxify ships no pre-built copy of it. The first call builds
it from the original source on your own machine, which requires the
taxifydb package (`remotes::install_github("gcol33/taxifydb")`). taxify
redistributes none of the data. Cite Hill et al. (2004) when you use it.

## References

Hill MO, Preston CD, Roy DB (2004) PLANTATT: Attributes of British and
Irish Plants. Biological Records Centre, Centre for Ecology and
Hydrology.

## Examples

``` r
if (FALSE) { # \dontrun{
# Builds the enrichment on first use (needs taxifydb).
taxify("Bellis perennis", backbone = "gbif") |>
  add_plantatt()
} # }
```
