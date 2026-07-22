# Add phytoplankton nutrient-uptake traits (Edwards et al.)

Joins species-level phytoplankton nutrient physiology (Droop/Monod
uptake and growth parameters for ammonium, nitrate and phosphorus, plus
cell size and carbon content) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_edwards_phyto(x, cols = NULL, verbose = TRUE)
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

The same data.frame with additional columns. The curated set:

- edwards_taxon_group:

  Coarse phytoplankton group (diatom, green, ...).

- edwards_habitat_system:

  Habitat (marine/freshwater).

- edwards_cell_volume:

  Cell volume (micron^3).

- edwards_carbon_per_cell:

  Carbon content per cell (pg C).

- edwards_mu_inf_nit:

  Maximum growth rate on nitrate (per day).

- edwards_k_nit:

  Half-saturation constant for growth on nitrate.

- edwards_qmin_nit:

  Minimum cell nitrogen quota.

- edwards_mu_inf_p:

  Maximum growth rate on phosphorus (per day).

- edwards_k_p:

  Half-saturation constant for growth on phosphorus.

- edwards_qmin_p:

  Minimum cell phosphorus quota.

With `cols = "all"` the full set of ammonium/nitrate/phosphorus uptake
and quota parameters (`vmax_amm`, `mu_nit`, `vmax_p`, `qmax_p`, ...) is
attached under their source names. All uptake/quota traits are joined on
`accepted_name`.

## Details

Source: Edwards et al. (2015, Ecology, CC BY 4.0), a compilation of
phytoplankton nutrient-utilization traits for ~130 species.
Single-source physiological data with no cross-source analogue, so it is
surfaced through this door rather than the cross-source
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
verb.

## References

Edwards KF, Thomas MK, Klausmeier CA, Litchman E (2015) Phytoplankton
growth and the interaction of light and temperature: A synthesis at the
species and community level. Ecology 96(9):2554-2564.
[doi:10.1890/14-2252.1](https://doi.org/10.1890/14-2252.1)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Thalassiosira pseudonana", backbone = "gbif") |>
  add_edwards_phyto()
} # }
```
