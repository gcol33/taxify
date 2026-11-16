# Add woodiness (Zanne et al. 2014)

Joins the woody / herbaceous classification of Zanne et al. (2014) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. This function is named after its
source, the Zanne Global Woodiness Database; for woodiness reconciled
across every source that carries it (Zanne, GIFT), use
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
with `"zanne_woodiness"`.

## Usage

``` r
add_zanne(x, cols = NULL, verbose = TRUE)
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

The same data.frame with an additional column:

- zanne_woodiness:

  One of `"woody"`, `"herbaceous"`, `"variable"`, or `NA` if not in the
  dataset.

## Details

Source: Zanne et al. 2014, Nature (Dryad, CC0). Coverage: ~50k plant
species. Plants only.

## References

Zanne AE et al. (2014) Three keys to the radiation of angiosperms into
freezing environments. Nature 506:89-92.

## See also

[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
for woodiness harmonized across sources.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus robur") |>
  add_zanne()
#> Matching 1 names against 8 backbones: col -> wcvp -> lcvp -> wfo -> fishbase -> sealifebase -> reptiledb -> gbif
#>   [col] Matching 1 names...
#>   [wcvp] Skipped (all names matched)
#>   [lcvp] Skipped (all names matched)
#>   [wfo] Skipped (all names matched)
#>   [fishbase] Skipped (all names matched)
#>   [sealifebase] Skipped (all names matched)
#>   [reptiledb] Skipped (all names matched)
#>   [gbif] Skipped (all names matched)
#>      input_name  matched_name accepted_name   taxon_id accepted_id    rank
#> 1 Quercus robur Quercus robur Quercus robur col-ex-001  col-ex-001 species
#>     family   genus epithet authorship accepted_authorship is_synonym
#> 1 Fagaceae Quercus   robur         L.                  L.      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA      col
#>           backbone_version kingdom_group taxon_group  life_form qualifier
#> 1 col:example (2026-06-24)       plantae  angiosperm angiosperm      <NA>
#>   qualifier_position aggregate_fallback hybrid_type zanne_woodiness
#> 1               <NA>                 NA        <NA>           woody
#> Sources: COL example, Zanne et al. 2014 example | cite() for full citations

options(old)
```
