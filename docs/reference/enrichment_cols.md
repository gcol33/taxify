# Browse the columns a published dataset can attach

Lists the columns available from a published dataset's pre-built `.vtr`,
for choosing which to attach through the functions that accept a `cols`
argument (such as
[`add_gift()`](https://gillescolling.com/taxify/reference/add_gift.md)
and
[`add_floraweb()`](https://gillescolling.com/taxify/reference/add_floraweb.md)).
Read offline from the local `.vtr`; the first call may trigger the
one-time download.

## Usage

``` r
enrichment_cols(source)
```

## Arguments

- source:

  Character. An enrichment name (see
  [`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md)).

## Value

A data.frame with one row per column: `column` (source name), `output`
(attached name), and `type` (`"numeric"` or `"character"`).

## Details

Source outputs start with the source key followed by `_`. Common names
use `common_`. Names already carrying the prefix keep it once. The
`cols` selector accepts source names, output names, and output names
without the prefix. Grouped outputs append the group code when several
groups are requested. The grouping key is used for filtering and
reshaping; it is excluded from attached values. Other country, region,
or language fields receive the source prefix. `output` is `NA` for the
grouping key.

## See also

[`add_gift()`](https://gillescolling.com/taxify/reference/add_gift.md),
[`add_floraweb()`](https://gillescolling.com/taxify/reference/add_floraweb.md),
[`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md)

Other Browse and discover:
[`enrichment_groups()`](https://gillescolling.com/taxify/reference/enrichment_groups.md),
[`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md)

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data())
enrichment_cols("gift")
#>                                column                             output
#> 1                    gift_woodiness_1                   gift_woodiness_1
#> 2                  gift_growth_form_1                 gift_growth_form_1
#> 3                    gift_lifecycle_1                   gift_lifecycle_1
#> 4                    gift_life_form_1                   gift_life_form_1
#> 5                      gift_climber_1                     gift_climber_1
#> 6                     gift_epiphyte_1                    gift_epiphyte_1
#> 7                     gift_parasite_1                    gift_parasite_1
#> 8                      gift_aquatic_1                     gift_aquatic_1
#> 9               gift_plant_height_max              gift_plant_height_max
#> 10        gift_photosynthetic_pathway        gift_photosynthetic_pathway
#> 11                gift_seed_mass_mean                gift_seed_mass_mean
#> 12          gift_dispersal_syndrome_1          gift_dispersal_syndrome_1
#> 13               gift_flowering_start               gift_flowering_start
#> 14                 gift_flowering_end                 gift_flowering_end
#> 15               gift_deciduousness_1               gift_deciduousness_1
#> 16                      gift_sla_mean                      gift_sla_mean
#> 17            gift_woodiness_1_source            gift_woodiness_1_source
#> 18          gift_growth_form_1_source          gift_growth_form_1_source
#> 19            gift_lifecycle_1_source            gift_lifecycle_1_source
#> 20            gift_life_form_1_source            gift_life_form_1_source
#> 21              gift_climber_1_source              gift_climber_1_source
#> 22             gift_epiphyte_1_source             gift_epiphyte_1_source
#> 23             gift_parasite_1_source             gift_parasite_1_source
#> 24              gift_aquatic_1_source              gift_aquatic_1_source
#> 25       gift_plant_height_max_source       gift_plant_height_max_source
#> 26 gift_photosynthetic_pathway_source gift_photosynthetic_pathway_source
#> 27         gift_seed_mass_mean_source         gift_seed_mass_mean_source
#> 28   gift_dispersal_syndrome_1_source   gift_dispersal_syndrome_1_source
#> 29        gift_flowering_start_source        gift_flowering_start_source
#> 30          gift_flowering_end_source          gift_flowering_end_source
#> 31        gift_deciduousness_1_source        gift_deciduousness_1_source
#> 32               gift_sla_mean_source               gift_sla_mean_source
#>         type
#> 1  character
#> 2  character
#> 3  character
#> 4  character
#> 5  character
#> 6  character
#> 7  character
#> 8  character
#> 9    numeric
#> 10 character
#> 11   numeric
#> 12 character
#> 13 character
#> 14 character
#> 15 character
#> 16   numeric
#> 17 character
#> 18 character
#> 19 character
#> 20 character
#> 21 character
#> 22 character
#> 23 character
#> 24 character
#> 25 character
#> 26 character
#> 27 character
#> 28 character
#> 29 character
#> 30 character
#> 31 character
#> 32 character
options(old)
```
