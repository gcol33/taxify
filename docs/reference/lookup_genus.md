# Look up a genus in the register

Returns the register row for the given genus, or `NULL` if not found.
Auto-loads the register on first call.

## Usage

``` r
lookup_genus(genus)
```

## Arguments

- genus:

  Character scalar. The genus name to look up, with the same
  capitalization as in the register (for example `"Quercus"`).

## Value

A one-row data.frame, or `NULL` if the genus is not in the register
(including `NA`). Columns include `genus`, `kingdom`, `phylum`, `class`,
`order`, `family`, `kingdom_group`, `taxon_group` and `life_form`;
builds may also supply `multi_kingdom`. Missing classification values
are `NA`.

## See also

[`taxify_load_register()`](https://gillescolling.com/taxify/reference/taxify_load_register.md),
[`taxify_register_coverage()`](https://gillescolling.com/taxify/reference/taxify_register_coverage.md)

Other Backbone data and cache:
[`taxify_build()`](https://gillescolling.com/taxify/reference/taxify_build.md),
[`taxify_clean()`](https://gillescolling.com/taxify/reference/taxify_clean.md),
[`taxify_clear_cache()`](https://gillescolling.com/taxify/reference/taxify_clear_cache.md),
[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md),
[`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md),
[`taxify_example_data()`](https://gillescolling.com/taxify/reference/taxify_example_data.md),
[`taxify_load_register()`](https://gillescolling.com/taxify/reference/taxify_load_register.md),
[`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md),
[`taxify_refresh_manifest()`](https://gillescolling.com/taxify/reference/taxify_refresh_manifest.md),
[`taxify_register_coverage()`](https://gillescolling.com/taxify/reference/taxify_register_coverage.md),
[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md),
[`taxify_store()`](https://gillescolling.com/taxify/reference/taxify_store.md)

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data(),
               taxify.offline = TRUE)
taxify:::taxify_load_register(force = TRUE, verbose = FALSE)
lookup_genus("Quercus")
#>       genus kingdom phylum class   order   family kingdom_group taxon_group
#> 185 Quercus Plantae   <NA>  <NA> Fagales Fagaceae       plantae  angiosperm
#>      life_form
#> 185 angiosperm
lookup_genus(NA_character_)
#> NULL
options(old)
```
