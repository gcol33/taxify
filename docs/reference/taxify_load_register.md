# Load the unified genus register into memory

Reads the published genus index and caches it for the session,
downloading it on first use. Subsequent calls reuse the cached version
unless `force = TRUE`.

## Usage

``` r
taxify_load_register(force = FALSE, verbose = TRUE)
```

## Arguments

- force:

  Logical. If `TRUE`, reloads from disk even if already cached. Default
  `FALSE`.

- verbose:

  Logical. Print progress messages. Default `TRUE`.

## Value

Invisibly, the full register data.frame, with the classification and
group columns described above. Missing classifications are `NA`.

## Details

The register contains one row per genus with columns `genus`, `kingdom`,
`phylum`, `class`, `order`, `family`, `kingdom_group`, `taxon_group` and
`life_form`, plus `multi_kingdom` when supplied by the build. The latter
flags genera recorded in more than one kingdom.

## See also

[`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md),
[`taxify_register_coverage()`](https://gillescolling.com/taxify/reference/taxify_register_coverage.md),
[`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md)
with `name = "register"`.

Other Backbone data and cache:
[`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md),
[`taxify_build()`](https://gillescolling.com/taxify/reference/taxify_build.md),
[`taxify_clean()`](https://gillescolling.com/taxify/reference/taxify_clean.md),
[`taxify_clear_cache()`](https://gillescolling.com/taxify/reference/taxify_clear_cache.md),
[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md),
[`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md),
[`taxify_example_data()`](https://gillescolling.com/taxify/reference/taxify_example_data.md),
[`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md),
[`taxify_refresh_manifest()`](https://gillescolling.com/taxify/reference/taxify_refresh_manifest.md),
[`taxify_register_coverage()`](https://gillescolling.com/taxify/reference/taxify_register_coverage.md),
[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md),
[`taxify_store()`](https://gillescolling.com/taxify/reference/taxify_store.md)

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data(),
               taxify.offline = TRUE)
reg <- taxify:::taxify_load_register(force = TRUE, verbose = FALSE)
head(reg[, c("genus", "kingdom", "family")])
#>         genus  kingdom         family
#> 1        Abax Animalia      Carabidae
#> 2       Abies  Plantae       Pinaceae
#> 3 Abietinella Animalia Zygophylacidae
#> 4        Abra Animalia      Semelidae
#> 5   Accipiter Animalia   Accipitridae
#> 6        Acer  Plantae    Sapindaceae
options(old)
```
