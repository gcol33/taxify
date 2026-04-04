# Add plant traits from LEDA Traitbase

Joins LEDA Traitbase (Kleyer et al. 2008) plant functional traits to a
[`taxify()`](https://gcol33.github.io/taxify/reference/taxify.md) result
by looking up `accepted_name`. LEDA provides species-level trait data
for NW European plant species, covering life form, dispersal, seed,
leaf, and clonality traits.

## Usage

``` r
add_leda(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gcol33.github.io/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- raunkiaer_life_form:

  Primary Raunkiaer life form classification (phanerophyte, chamaephyte,
  hemicryptophyte, geophyte, therophyte, helophyte, hydrophyte).

- raunkiaer_variable:

  1 if species assigned to multiple Raunkiaer forms, 0 otherwise.

- dispersal_type:

  Primary dispersal type (anemochory, zoochory, hydrochory, autochory,
  barochory, dysochory).

- terminal_velocity_ms:

  Seed terminal velocity in m/s (species median).

- seed_mass_mg:

  Seed mass in mg (species median). Prefixed with `leda_` in the .vtr to
  avoid collision with Diaz traits.

- canopy_height_m:

  Canopy height in meters (species median).

- leaf_mass_mg:

  Leaf dry mass in mg (species median).

- sla_mm2_mg:

  Specific leaf area in mm\\^2\\/mg (species median).

- clonal_growth:

  Capable of clonal growth (1 = yes, 0 = no).

- buoyancy:

  Seed buoyancy classification.

## Details

Source: LEDA Traitbase (Kleyer et al. 2008). Coverage: ~8,000 NW
European plant species.

The Raunkiaer life form is a bud-position classification system:
phanerophyte = buds \>25 cm above soil, chamaephyte = buds near soil
surface, hemicryptophyte = buds at soil surface, geophyte (cryptophyte)
= buds below soil, therophyte = annual that survives as seed.

## References

Kleyer M et al. (2008) The LEDA Traitbase: a database of life-history
traits of the Northwest European flora. Journal of Ecology 96:1266-1274.

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Arrhenatherum elatius") |>
  add_leda()
} # }
```
