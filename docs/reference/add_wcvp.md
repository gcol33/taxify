# Add WCVP native range status

Joins WCVP (World Checklist of Vascular Plants, Kew) native range data
to a [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result, filtered by TDWG botanical region.

## Usage

``` r
add_wcvp(x, region, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- region:

  Character. TDWG Level 3 region code(s), or `"all"`. See
  [`taxify_regions()`](https://gillescolling.com/taxify/reference/taxify_regions.md)
  for the full list of codes.

  - Single code (e.g., `"BGM"` for Belgium): adds `wcvp_native_status`
    column (no suffix).

  - Multiple codes (e.g., `c("BGM", "GER")`): adds `native_status_BGM`,
    `native_status_GER`.

  - `"all"`: adds one column per region in the dataset.

  List the region codes WCVP covers with `enrichment_groups("wcvp")`.

- cols:

  Which columns to attach. `NULL` (the default) attaches the curated
  set; a character vector of column names attaches just those, and
  `"all"` attaches every column the source carries (see
  [`enrichment_cols()`](https://gillescolling.com/taxify/reference/enrichment_cols.md)).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional column(s):

- wcvp_native_status:

  One of `"native"`, `"introduced"`, `"extinct"`, or `NA` if not
  recorded for that region.

## Details

Source: WCVP (Kew, CC BY). Coverage: ~340k plant species. Plants only.

The range reported is that of the taxon
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
matched, as its backbone circumscribes it: the matched name's own
records plus those of every name the backbone sinks into it. Where these
disagree on a region, `native` wins over `introduced`, and `introduced`
over `extinct`, since the taxon is native wherever any part of it is.

A region is left `NA` rather than filled from a broader taxon, or from
one the matched backbone accepts as separate, when that is the only name
another backbone offers for it. Those names are listed as `refused` in
the `wcvp` entry of `attr(x, "taxify_meta")$enrichments` (the queried
and refused name, the reason, the backbones offering it and the number
of regions it would have filled), and counted by
[`base::summary()`](https://rdrr.io/r/base/summary.html).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus robur") |>
  add_wcvp(region = "GER")
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
#>   qualifier_position aggregate_fallback hybrid_type wcvp_native_status
#> 1               <NA>                 NA        <NA>             native
#> Sources: COL example, WCVP (Kew) example | cite() for full citations

taxify("Quercus robur") |>
  add_wcvp(region = c("GER", "BGM"))
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
#>   qualifier_position aggregate_fallback hybrid_type wcvp_native_status_GER
#> 1               <NA>                 NA        <NA>                 native
#>   wcvp_native_status_BGM
#> 1                 native
#> Sources: COL example, WCVP (Kew) example | cite() for full citations

options(old)
```
