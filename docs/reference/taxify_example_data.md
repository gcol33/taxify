# Path to the bundled example database

taxify ships a tiny example database (a handful of species per backbone
plus matching enrichment tables) so that examples and quick experiments
run offline, without downloading the full multi-million-row backbones.

## Usage

``` r
taxify_example_data()
```

## Value

Character string. Path to the bundled example database directory, or
`""` if it is not installed.

## Details

Point taxify at it for the current session by setting the
`taxify.data_dir` option:

    old <- options(taxify.data_dir = taxify_example_data())
    taxify("Quercus robur") |> add_zanne()
    options(old)  # restore the real data directory

The example database is read-only and covers only the species used in
the package examples; use the full downloaded backbones for real work.

## See also

[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md)

Other Backbone data and cache:
[`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md),
[`taxify_build()`](https://gillescolling.com/taxify/reference/taxify_build.md),
[`taxify_clean()`](https://gillescolling.com/taxify/reference/taxify_clean.md),
[`taxify_clear_cache()`](https://gillescolling.com/taxify/reference/taxify_clear_cache.md),
[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md),
[`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md),
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
res <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
res[, c("input_name", "accepted_name")]
#>      input_name accepted_name
#> 1 Quercus robur Quercus robur
#> Sources: WFO example | cite() for full citations
options(old)
```
