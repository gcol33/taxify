# Add British and Irish bryophyte attributes (BRYOATT)

Joins attributes of British and Irish mosses, liverworts and hornworts
(Hill et al. 2007) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Bryophytes are otherwise almost
absent from the bundled trait databases.

## Usage

``` r
add_bryoatt(x, cols = NULL, verbose = TRUE)
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

- bryoatt_ellenberg_light, bryoatt_ellenberg_moisture,
  bryoatt_ellenberg_reaction, bryoatt_ellenberg_nitrogen,
  bryoatt_ellenberg_salt:

  Ellenberg indicator values calibrated for British and Irish
  bryophytes.

- bryoatt_life_form:

  Life-form code, kept verbatim (`Ts`, `Mr`, `Ms`, ...).

- bryoatt_plant_group:

  Plant group: `M` moss, `L` liverwort, `H` hornwort.

- bryoatt_status:

  Status code, kept verbatim (`N` native, `AN` alien naturalised, `AR`
  archaeophyte).

## Details

1,194 taxa. The vascular-plant companion is
[`add_plantatt()`](https://gillescolling.com/taxify/reference/add_plantatt.md).

This source states no licence (it is copyright the Biological Records
Centre), so taxify ships no pre-built copy of it. The first call builds
it from the original source on your own machine, which requires the
taxifydb package (`remotes::install_github("gcol33/taxifydb")`). taxify
redistributes none of the data. Cite Hill et al. (2007) when you use it.

## References

Hill MO, Preston CD, Bosanquet SDS, Roy DB (2007) BRYOATT: Attributes of
British and Irish Mosses, Liverworts and Hornworts. NERC Centre for
Ecology and Hydrology.

## Examples

``` r
if (FALSE) { # \dontrun{
# Builds the enrichment on first use (needs taxifydb).
taxify("Polytrichum commune", backbone = "gbif") |>
  add_bryoatt()
} # }
```
