# Add phytoplankton cell metrics (Rimet & Druart)

Joins cell-level morphometrics for temperate-lake phytoplankton to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`.

## Usage

``` r
add_rimet_phyto(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with numeric columns `rimet_phyto_cell_length_um`,
`rimet_phyto_cell_width_um`, `rimet_phyto_cell_thickness_um`,
`rimet_phyto_cell_surface_area_um2`, `rimet_phyto_cell_biovolume_um3`.

## Details

Source: Rimet & Druart (2018) phytoplankton metrics database (Zenodo,
CC-BY 4.0).

## References

Rimet F, Druart JC (2018) A trait database for phytoplankton of
temperate lakes. Zenodo.
[doi:10.5281/zenodo.1164834](https://doi.org/10.5281/zenodo.1164834)

## Examples

``` r
# \donttest{
taxify("Asterionella formosa", backend = "gbif") |>
  add_rimet_phyto()
# }
```
