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

- leda_raunkiaer_life_form:

  Most frequent LEDA plant growth form: the Raunkiaer classes
  (Phanerophyte, Chamaephyte, Hemicryptophyte, Geophyte, Therophyte,
  Hydrophyte) plus Liana, Vascular semi-parasite and Vascular parasite.

- leda_raunkiaer_variable:

  1 if the species' records name more than one growth form, 0 otherwise.

- leda_dispersal_type:

  Most frequent dispersal type, as LEDA's -chor term (meteorochor,
  epizoochor, nautochor, ...).

- leda_terminal_velocity_ms:

  Diaspore terminal velocity in m/s (species median).

- leda_seed_mass_mg:

  Seed mass in mg (species median). Prefixed with `leda_` in the .vtr to
  avoid collision with Diaz traits.

- leda_canopy_height_m:

  Canopy height in metres (species median): the height of the highest
  photosynthetic tissue, which LEDA distinguishes from plant height.

- leda_leaf_mass_mg:

  Leaf dry mass in mg (species median).

- leda_sla_mm2_mg:

  Specific leaf area in mm\\^2\\/mg (species median).

- leda_clonal_growth_organ:

  Most frequent primary clonal growth organ (epigeogeneous stems,
  root-splitters, bulbs, ...).

- leda_floating_capacity_1week_pct:

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
#> Matching 1 names against 8 backbones: col -> wcvp -> lcvp -> wfo -> fishbase -> sealifebase -> reptiledb -> gbif
#>   [col] Matching 1 names...
#>   [wcvp] Matching 1 remaining names...
#>   [lcvp] Matching 1 remaining names...
#>   [wfo] Matching 1 remaining names...
#>   [fishbase] Skipped (all names matched)
#>   [sealifebase] Skipped (all names matched)
#>   [reptiledb] Skipped (all names matched)
#>   [gbif] Skipped (all names matched)
#> add_leda(): attaching 10 of 87 columns. Pass cols = "all" for all, or see enrichment_cols("leda").
#>              input_name          matched_name         accepted_name   taxon_id
#> 1 Arrhenatherum elatius Arrhenatherum elatius Arrhenatherum elatius wfo-ex-008
#>   accepted_id    rank  family         genus epithet
#> 1  wfo-ex-008 species Poaceae Arrhenatherum elatius
#>                           authorship                accepted_authorship
#> 1 (L.) P.Beauv. ex J.Presl & C.Presl (L.) P.Beauv. ex J.Presl & C.Presl
#>   is_synonym taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1      FALSE         ACCEPTED     FALSE      exact         NA      wfo
#>           backbone_version kingdom_group taxon_group  life_form qualifier
#> 1 wfo:example (2026-06-24)       plantae  angiosperm angiosperm      <NA>
#>   qualifier_position aggregate_fallback hybrid_type leda_raunkiaer_life_form
#> 1               <NA>                 NA        <NA>          Hemicryptophyte
#>   leda_raunkiaer_variable leda_dispersal_type leda_terminal_velocity_ms
#> 1                       0          epizoochor                     2.645
#>   leda_seed_mass_mg leda_canopy_height_m leda_leaf_mass_mg leda_sla_mm2_mg
#> 1             2.774                 1.35          30.65406          29.035
#>   leda_clonal_growth_organ leda_floating_capacity_1week_pct
#> 1      epigeogeneous stems                               25
#> Sources: WFO example, LEDA Traitbase example | cite() for full citations

options(old)
```
