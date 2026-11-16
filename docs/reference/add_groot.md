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

- groot_root_diameter:

  Mean root diameter.

- groot_specific_root_length:

  Specific root length.

- groot_root_tissue_density:

  Root tissue density.

- groot_root_n_concentration:

  Root nitrogen concentration.

- groot_root_c_concentration:

  Root carbon concentration.

- groot_root_mass_fraction:

  Root mass fraction.

- groot_lateral_spread:

  Lateral spread.

- groot_root_mycorrhizal_colonization:

  Root mycorrhizal colonization intensity.

- groot_rooting_depth:

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
#> Matching 1 names against 8 backbones: col -> wcvp -> lcvp -> wfo -> fishbase -> sealifebase -> reptiledb -> gbif
#>   [col] Matching 1 names...
#>   [wcvp] Matching 1 remaining names...
#>   [lcvp] Matching 1 remaining names...
#>   [wfo] Matching 1 remaining names...
#>   [fishbase] Skipped (all names matched)
#>   [sealifebase] Skipped (all names matched)
#>   [reptiledb] Skipped (all names matched)
#>   [gbif] Skipped (all names matched)
#>   input_name matched_name accepted_name   taxon_id accepted_id    rank   family
#> 1 Abies alba   Abies alba    Abies alba wfo-ex-005  wfo-ex-005 species Pinaceae
#>   genus epithet authorship accepted_authorship is_synonym taxonomic_status
#> 1 Abies    alba      Mill.               Mill.      FALSE         ACCEPTED
#>   is_hybrid match_type fuzzy_dist backbone         backbone_version
#> 1     FALSE      exact         NA      wfo wfo:example (2026-06-24)
#>   kingdom_group taxon_group  life_form qualifier qualifier_position
#> 1       plantae  gymnosperm gymnosperm      <NA>               <NA>
#>   aggregate_fallback hybrid_type groot_root_diameter groot_specific_root_length
#> 1                 NA        <NA>                  11                         11
#>   groot_root_tissue_density groot_root_n_concentration
#> 1                        11                         11
#>   groot_root_c_concentration groot_root_mass_fraction groot_lateral_spread
#> 1                         11                       11                   11
#>   groot_root_mycorrhizal_colonization groot_rooting_depth
#> 1                                  11                  11
#> Sources: WFO example, GRooT example | cite() for full citations

options(old)
```
