# Add plant traits from LEDA Traitbase

Joins LEDA Traitbase (Kleyer et al. 2008) plant functional traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. LEDA provides species-level trait
data for NW European plant species, covering life form, dispersal, seed,
leaf, and clonality traits.

## Usage

``` r
add_leda(x, cols = NULL, verbose = TRUE)
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

The same data.frame with additional columns:

- raunkiaer_life_form:

  Most frequent LEDA plant growth form: the Raunkiaer classes
  (Phanerophyte, Chamaephyte, Hemicryptophyte, Geophyte, Therophyte,
  Hydrophyte) plus Liana, Vascular semi-parasite and Vascular parasite.

- raunkiaer_variable:

  1 if the species' records name more than one growth form, 0 otherwise.

- dispersal_type:

  Most frequent dispersal type, as LEDA's -chor term (meteorochor,
  epizoochor, nautochor, ...).

- terminal_velocity_ms:

  Diaspore terminal velocity in m/s (species median).

- seed_mass_mg:

  Seed mass in mg (species median). Prefixed with `leda_` in the .vtr to
  avoid collision with Diaz traits.

- canopy_height_m:

  Canopy height in metres (species median): the height of the highest
  photosynthetic tissue, which LEDA distinguishes from plant height.

- leaf_mass_mg:

  Leaf dry mass in mg (species median).

- sla_mm2_mg:

  Specific leaf area in mm\\^2\\/mg (species median).

- clonal_growth_organ:

  Most frequent primary clonal growth organ (epigeogeneous stems,
  root-splitters, bulbs, ...).

- floating_capacity_1week_pct:

  Percentage of diaspores still floating after one week (species
  median).

## Details

Source: LEDA Traitbase (Kleyer et al. 2008). Coverage: ~12,500 NW
European plant taxa. `cols = "all"` adds the remaining LEDA traits and,
for each, a `<col>_source` column of the references behind the value
(resolve with
[`cite()`](https://gillescolling.com/taxify/reference/cite.md) and
`source = "leda"`).

The Raunkiaer life form is a bud-position classification system:
phanerophyte = buds \>25 cm above soil, chamaephyte = buds near soil
surface, hemicryptophyte = buds at soil surface, geophyte (cryptophyte)
= buds below soil, therophyte = annual that survives as seed.

## References

Kleyer M et al. (2008) The LEDA Traitbase: a database of life-history
traits of the Northwest European flora. Journal of Ecology 96:1266-1274.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Arrhenatherum elatius") |>
  add_leda()

options(old)
```
