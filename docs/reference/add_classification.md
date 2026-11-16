# Add the full higher classification to a taxify result

Attaches the Linnaean ranks above family (kingdom, phylum, class, order)
to a [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by joining each matched row back to its backbone. The core
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
output already carries `family` and `genus`; this fills the ranks above
them, for whichever ranks the matched backbone stores. Rows matched by
different backbones are each joined against their own backbone.

## Usage

``` r
add_classification(
  x,
  ranks = c("kingdom", "phylum", "class", "order"),
  verbose = TRUE
)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- ranks:

  Character vector of ranks to attach. Default
  `c("kingdom", "phylum", "class", "order")`.

- verbose:

  Logical. Default `TRUE`.

## Value

`x` with the requested rank columns added. A rank a backbone does not
store is left `NA` (WFO, for example, carries no ranks above family).

## See also

[`add_col_info()`](https://gillescolling.com/taxify/reference/add_col_info.md),
[`add_gbif_info()`](https://gillescolling.com/taxify/reference/add_gbif_info.md)
for backbone-specific extras.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Naja naja", backbone = "reptiledb") |>
  add_classification()
#> Matching 1 names...
#>   input_name matched_name accepted_name         taxon_id      accepted_id
#> 1  Naja naja    Naja naja     Naja naja reptiledb-ex-003 reptiledb-ex-003
#>      rank   family genus epithet authorship accepted_authorship is_synonym
#> 1 species Elapidae  Naja    naja       <NA>                <NA>      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist  backbone
#> 1         ACCEPTED     FALSE      exact         NA reptiledb
#>                 backbone_version kingdom_group taxon_group life_form qualifier
#> 1 reptiledb:example (2026-06-24)      animalia      animal    animal      <NA>
#>   qualifier_position aggregate_fallback hybrid_type  kingdom   phylum    class
#> 1               <NA>                 NA        <NA> Animalia Chordata Reptilia
#>       order
#> 1 Serpentes
#> Sources: REPTILEDB example | cite() for full citations

options(old)
```
