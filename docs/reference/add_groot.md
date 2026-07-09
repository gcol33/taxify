# Add root traits (GRooT)

Joins species-level root traits from the Global Root Traits (GRooT)
database to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. GRooT aggregates root trait
records to per-species means. The `.vtr` carries the full GRooT trait
set (38 root traits); the default attaches the nine best-populated key
traits, and `cols = "all"` attaches every one. Run
`enrichment_cols("groot")` to list them.

## Usage

``` r
add_groot(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) the nine key traits below,
  `"all"` every GRooT trait, or a character vector of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns (per-species means). The
default set:

- root_diameter:

  Mean root diameter.

- specific_root_length:

  Specific root length.

- root_tissue_density:

  Root tissue density.

- root_n_concentration:

  Root nitrogen concentration.

- root_c_concentration:

  Root carbon concentration.

- root_mass_fraction:

  Root mass fraction.

- lateral_spread:

  Lateral spread.

- root_mycorrhizal_colonization:

  Root mycorrhizal colonization intensity.

- rooting_depth:

  Maximum rooting depth.

`cols = "all"` additionally attaches root chemistry (P/K/Ca/Mg/Mn
concentrations, C:N and N:P ratios), architecture (branching density and
ratio, stele diameter and fraction, cortex thickness, vessel diameter
and number), turnover (root lifespan, production, turnover rate, litter
mass-loss rate), and specific root area, respiration, and dry-matter
content, among others. Units follow the GRooT data paper; see the
reference below.

## Details

Source: GRooT database (Guerrero-Ramirez et al. 2021). Vascular plants.
GRooT data are publicly available and used here with the data-paper
citation requested by the authors.

## References

Guerrero-Ramirez NR et al. (2021) Global root traits (GRooT) database.
Global Ecology and Biogeography 30:25-37.
[doi:10.1111/geb.13179](https://doi.org/10.1111/geb.13179)

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Abies alba") |>
  add_groot()

options(old)
```
