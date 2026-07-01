# Add plant traits from GIFT

Joins species-level plant traits from GIFT, the Global Inventory of
Floras and Traits (Weigelt et al. 2020), to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`. GIFT aggregates published trait records to
one value per species (mean for numeric traits, most frequent entry for
categorical ones). You choose which traits to attach with `cols`; browse
the available columns with
[`gift_traits()`](https://gillescolling.com/taxify/reference/gift_traits.md).

## Usage

``` r
add_gift(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which GIFT trait columns to attach. One of: `NULL` (the default) for a
  convenient set of well-populated traits; the string `"all"` for every
  bundled trait; or a character vector of `gift_` column names (e.g.
  `"plant_height_max"`, with or without the `gift_` prefix). See
  [`gift_traits()`](https://gillescolling.com/taxify/reference/gift_traits.md).
  When left `NULL`, a one-time message notes the default set and how to
  request all traits.

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with one added column per requested trait, named
`gift_<trait>`. Numeric traits (heights, masses, areas) are doubles, the
rest character. Rows with no value in GIFT get `NA`. With the default
`cols`, the added columns are `gift_woodiness_1`, `gift_growth_form_1`,
`gift_lifecycle_1`, `gift_life_form_1`, `gift_climber_1`,
`gift_epiphyte_1`, `gift_parasite_1`, `gift_aquatic_1`,
`gift_plant_height_max`, `gift_photosynthetic_pathway`,
`gift_seed_mass_mean`, `gift_dispersal_syndrome_1`,
`gift_flowering_start`, `gift_flowering_end`, `gift_deciduousness_1`,
and `gift_sla_mean`.

## Details

The GIFT trait table is bundled as a pre-built `.vtr` and joined
offline, so no internet access is needed once it is present (the first
use downloads it, or builds it from source if `taxifydb` is installed).
GIFT's API exposes only the redistributable subset of its data (CC BY
4.0; references whose underlying source is restricted are excluded), and
that subset is what is bundled here. Cite GIFT and, where applicable,
the underlying references
([`GIFT::GIFT_references()`](https://biogeomacro.github.io/GIFT/reference/GIFT_references.html))
when you use the values.

## References

Weigelt P, Konig C, Kreft H (2020) GIFT - A Global Inventory of Floras
and Traits for macroecology and biogeography. Journal of Biogeography
47:16-43. [doi:10.1111/jbi.13623](https://doi.org/10.1111/jbi.13623)
Denelle P, Weigelt P, Kreft H (2023) GIFT: an R package to access the
Global Inventory of Floras and Traits. Methods in Ecology and Evolution
14:2738-2748.
[doi:10.1111/2041-210X.14213](https://doi.org/10.1111/2041-210X.14213)

## See also

[`gift_traits()`](https://gillescolling.com/taxify/reference/gift_traits.md)
to browse the available columns.

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data())

taxify("Abies alba") |>
  add_gift()

options(old)
```
