# Add scleractinian coral traits (Coral Trait Database)

Joins species-level coral functional traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Values are aggregated from the
long-format Coral Trait Database (numeric traits by median, categorical
traits by mode).

## Usage

``` r
add_coral_traits(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- coral_symbiotic_state:

  Zooxanthellate / azooxanthellate.

- coral_growth_form:

  Typical growth form (massive/branching/...).

- coral_coloniality:

  Colonial / solitary.

- coral_substrate_attachment:

  Attached / unattached.

- coral_sexual_system:

  Hermaphrodite / gonochore.

- coral_larval_development_mode:

  Spawner / brooder.

- coral_symbiont_clade:

  Symbiodinium clade.

- coral_corallite_width_max_mm:

  Maximum corallite width (mm).

- coral_colony_max_diameter_cm:

  Maximum colony diameter (cm).

- coral_growth_rate_mm_yr:

  Linear extension rate (mm/year).

- coral_depth_lower_m:

  Lower depth limit (m).

- coral_depth_upper_m:

  Upper depth limit (m).

- coral_skeletal_density_g_cm3:

  Skeletal density (g/cm3).

## Details

Source: Coral Trait Database (Madin et al. 2016, Scientific Data, CC BY
4.0). Coverage: ~1.5k coral species.

## References

Madin JS et al. (2016) The Coral Trait Database, a curated database of
trait information for coral species from the global oceans. Scientific
Data 3:160017.
[doi:10.1038/sdata.2016.17](https://doi.org/10.1038/sdata.2016.17)

## Examples

``` r
# \donttest{
taxify("Acropora millepora", backend = "gbif") |>
  add_coral_traits()
# }
```
