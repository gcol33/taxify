# Add GBIF-specific columns

Joins extra GBIF backbone columns to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `taxon_id` in the GBIF backbone. Only enriches rows
where `backbone == "gbif"`.

## Usage

``` r
add_gbif_info(x)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  with `backbone == "gbif"`.

## Value

The same data.frame with additional columns:

- notho_type:

  Hybrid type: `"GENERIC"`, `"SPECIFIC"`, or `"INFRASPECIFIC"`.

- nom_status:

  Nomenclatural status (may contain multiple values).

- bracket_authorship:

  Basionym author in parentheses.

- bracket_year:

  Basionym author year.

- gbif_year:

  Combining author year.

- name_published_in:

  Publication citation.

- origin:

  How the name entered the backbone.

- infra_specific_epithet:

  Infraspecific epithet.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus robur", backbone = "gbif") |>
  add_gbif_info()
#> Matching 1 names...
#>      input_name  matched_name accepted_name    taxon_id accepted_id    rank
#> 1 Quercus robur Quercus robur Quercus robur gbif-ex-001 gbif-ex-001 species
#>     family   genus epithet authorship accepted_authorship is_synonym
#> 1 Fagaceae Quercus   robur         L.                  L.      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group  life_form qualifier
#> 1 gbif:example (2026-06-24)       plantae  angiosperm angiosperm      <NA>
#>   qualifier_position aggregate_fallback hybrid_type notho_type nom_status
#> 1               <NA>                 NA        <NA>       <NA>       <NA>
#>   bracket_authorship bracket_year gbif_year name_published_in origin
#> 1               <NA>         <NA>      <NA>              <NA>   <NA>
#>   infra_specific_epithet
#> 1                   <NA>
#> Sources: GBIF example | cite() for full citations

options(old)
```
