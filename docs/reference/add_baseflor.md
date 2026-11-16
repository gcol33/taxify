# Add plant traits from Baseflor (Catminat / Julve)

Joins Baseflor (Julve, Programme Catminat) plant traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Baseflor covers the vascular flora
of France and neighbouring regions, providing flowering phenology,
pollination and breeding biology, dispersal mode, and floral and fruit
morphology.

## Usage

``` r
add_baseflor(x, cols = NULL, verbose = TRUE)
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

- baseflor_flower_begin_month:

  First month of flowering (1-12).

- baseflor_flower_end_month:

  Last month of flowering (1-12). A value smaller than
  `flower_begin_month` denotes a flowering period that wraps across the
  new year (e.g. begin 10, end 6).

- baseflor_pollination_vector:

  Pollination vector(s): insect, wind, water, self, apogamy.
  Comma-separated when more than one applies.

- baseflor_dispersal_mode:

  Diaspore dispersal mode(s): anemochory, barochory, epizoochory,
  endozoochory, myrmecochory, hydrochory, autochory, dyszoochory.
  Comma-separated when more than one applies.

- baseflor_breeding_system:

  Sexual system: hermaphroditic, monoecious, dioecious, gynodioecious,
  androdioecious, gynomonoecious, polygamous.

- baseflor_flower_colour:

  Flower colour(s): white, yellow, pink, green, blue, brown, black.
  Comma-separated when more than one applies.

- baseflor_fruit_type:

  Fruit type: achene, capsule, caryopsis, drupe, legume, silique, berry,
  follicle, cone, samara, pyxid.

- baseflor_woody_growth_form:

  Woody growth form for woody taxa: tree, small tree, large tree, shrub,
  bush, subshrub, liana, parasite. NA for non-woody (herbaceous) taxa.

- baseflor_continentality:

  Ellenberg-style baseflor_continentality indicator value (1-9), the
  axis absent from EIVE.

- baseflor_salinity:

  Ellenberg-style baseflor_salinity indicator value (0-9), the axis
  absent from EIVE.

## Details

Source: Baseflor, Programme Catminat (Julve 1998 ff.). Coverage: ~7,000
vascular plant taxa of France and neighbouring regions. Data are
released under ODbL 1.0 / CC BY-SA 2.0.

For ecological indicator values on the light, temperature, moisture,
reaction, and nutrient axes, see
[`add_eive()`](https://gillescolling.com/taxify/reference/add_eive.md)
(European calibration). For Raunkiaer life form and seed, leaf, and
clonality traits of the Northwest European flora, see
[`add_leda()`](https://gillescolling.com/taxify/reference/add_leda.md).

## References

Julve, Ph. (1998 ff.) baseflor. Index botanique, ecologique et
chorologique de la Flore de France. Programme Catminat.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Bellis perennis") |>
  add_baseflor()
#> Matching 1 names against 8 backbones: col -> wcvp -> lcvp -> wfo -> fishbase -> sealifebase -> reptiledb -> gbif
#>   [col] Matching 1 names...
#>   [wcvp] Matching 1 remaining names...
#>   [lcvp] Matching 1 remaining names...
#>   [wfo] Matching 1 remaining names...
#>   [fishbase] Skipped (all names matched)
#>   [sealifebase] Skipped (all names matched)
#>   [reptiledb] Skipped (all names matched)
#>   [gbif] Skipped (all names matched)
#>        input_name    matched_name   accepted_name   taxon_id accepted_id
#> 1 Bellis perennis Bellis perennis Bellis perennis wfo-ex-009  wfo-ex-009
#>      rank     family  genus  epithet authorship accepted_authorship is_synonym
#> 1 species Asteraceae Bellis perennis         L.                  L.      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA      wfo
#>           backbone_version kingdom_group taxon_group life_form qualifier
#> 1 wfo:example (2026-06-24)       plantae     unknown   unknown      <NA>
#>   qualifier_position aggregate_fallback hybrid_type baseflor_flower_begin_month
#> 1               <NA>                 NA        <NA>  example_flower_begin_month
#>   baseflor_flower_end_month baseflor_pollination_vector baseflor_dispersal_mode
#> 1  example_flower_end_month  example_pollination_vector  example_dispersal_mode
#>   baseflor_breeding_system baseflor_flower_colour baseflor_fruit_type
#> 1  example_breeding_system  example_flower_colour  example_fruit_type
#>   baseflor_woody_growth_form baseflor_continentality baseflor_salinity
#> 1  example_woody_growth_form  example_continentality  example_salinity
#> Sources: WFO example, Baseflor (Catminat / Julve) example | cite() for full citations

options(old)
```
