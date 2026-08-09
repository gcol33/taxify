# Add mammal traits from COMBINE (reported values)

Joins the COMBINE mammal trait database to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`, attaching the **reported**
(directly measured or literature-compiled) trait values. COMBINE ships
two parallel tables over the same ~6.2k mammal species: the reported
table used here, and a phylogenetically imputed table with the missing
cells filled in by a model
([`add_combine_imputed()`](https://gillescolling.com/taxify/reference/add_combine_imputed.md)).
They are offered as two separate sources so the distinction between a
measured value and a model estimate stays explicit.

## Usage

``` r
add_combine_reported(x, cols = NULL, verbose = TRUE)
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

The same data.frame with additional columns (reported values):

- combine_adult_mass_g:

  Adult body mass (g).

- combine_adult_body_length_mm:

  Adult head-body length (mm).

- combine_litter_size_n:

  Litter size (count).

- combine_litters_per_year_n:

  Litters per year (count).

- combine_max_longevity_d:

  Maximum longevity (days).

- combine_gestation_length_d:

  Gestation length (days).

- combine_weaning_age_d:

  Weaning age (days).

- combine_generation_length_d:

  Generation length (days).

- combine_dispersal_km:

  Natal dispersal distance (km).

- combine_habitat_breadth_n:

  Number of IUCN habitats (count).

- combine_diet_breadth_n:

  Number of diet categories (count).

- combine_trophic_level:

  Trophic level (1 herbivore, 2 omnivore, 3 carnivore).

- combine_activity_cycle:

  Activity cycle (1 nocturnal, 2 cathemeral, 3 diurnal).

- combine_foraging_stratum:

  Foraging stratum (G/Ar/A/S/M).

- combine_biogeographical_realm:

  Biogeographical realm(s).

## Details

Source: COMBINE (Soria et al. 2021, Ecology, CC0), reported table.
Coverage: ~6.2k mammal species, keyed on the IUCN 2020 binomial. The
reported table leaves a cell missing when no source measured that trait
for a species; use
[`add_combine_imputed()`](https://gillescolling.com/taxify/reference/add_combine_imputed.md)
for the higher-coverage phylogenetically imputed values.

## References

Soria CD et al. (2021) COMBINE: a coalesced mammal database of intrinsic
and extrinsic traits. Ecology 102:e03344.
[doi:10.1002/ecy.3344](https://doi.org/10.1002/ecy.3344)

## See also

[`add_combine()`](https://gillescolling.com/taxify/reference/add_combine.md)
for reported values with imputed gaps filled and per-trait provenance;
[`add_combine_imputed()`](https://gillescolling.com/taxify/reference/add_combine_imputed.md)
for the imputed values;
[`add_pantheria()`](https://gillescolling.com/taxify/reference/add_pantheria.md),
[`add_anage()`](https://gillescolling.com/taxify/reference/add_anage.md)
for other mammal trait sources.

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Vulpes vulpes", backbone = "gbif") |>
  add_combine_reported()
} # }
```
