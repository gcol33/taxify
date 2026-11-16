# Download pre-built backbones or published datasets

Downloads pre-built `.vtr` files from GitHub Releases using the taxify
manifest. This needs no build tools and does not require `taxifydb`; it
is the fast path
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) uses
internally on first use. Call it directly to pre-fetch backbones and
enrichment datasets before an offline session. No prompts are shown, so
calling this function is consent.

## Usage

``` r
taxify_download(
  name = "wfo",
  kind = c("backbone", "enrichment"),
  version = "latest",
  content_id = NULL,
  force = FALSE,
  verbose = TRUE
)
```

## Arguments

- name:

  Character. One or more names from
  [`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md)
  or
  [`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md),
  according to `kind`. With `kind = "backbone"`, `"register"` resolves
  the genus register and its coverage table.

- kind:

  Character. `"backbone"` (default) or `"enrichment"`. Selects the
  catalogue, including names present in both, such as WCVP.

- version:

  Character. `"latest"` (default) downloads into the asset's `latest/`
  directory and will be overwritten on future updates. A specific
  version string (e.g., `"2024.01"`) downloads into a pinned folder
  retained until explicitly refreshed with `force = TRUE`.

- content_id:

  Character or `NULL` (default). The content id of one exact build, the
  md5 of its `.vtr`, as recorded by
  [`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md)
  and by the manifest. Given one, taxify fetches that build from the
  immutable copy published beside the rolling asset, verifies the bytes
  hash back to the id, and makes it the active build; the build it
  replaces is kept under its own content id. Pass one id per `name`, or
  one shared by all of them.

- force:

  Logical. Re-download an existing version when `TRUE`. Default `FALSE`.
  An exact `content_id` identifies immutable bytes.

- verbose:

  Logical. Default `TRUE`.

## Value

Invisibly, a character vector of file paths, named by `name` and in the
requested order. `"register"` returns the genus-register path after
resolving both the register and its coverage table.

## Details

If no pre-built `.vtr` is available for a backbone, it falls back to
building from source via
[`taxify_build()`](https://gillescolling.com/taxify/reference/taxify_build.md)
(which requires `taxifydb`).

## See also

[`taxify_build()`](https://gillescolling.com/taxify/reference/taxify_build.md)
to build a backbone from source via `taxifydb`,
[`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md)
for published datasets,
[`taxify_store()`](https://gillescolling.com/taxify/reference/taxify_store.md)
for the builds already on disk.

Other Backbone data and cache:
[`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md),
[`taxify_build()`](https://gillescolling.com/taxify/reference/taxify_build.md),
[`taxify_clean()`](https://gillescolling.com/taxify/reference/taxify_clean.md),
[`taxify_clear_cache()`](https://gillescolling.com/taxify/reference/taxify_clear_cache.md),
[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md),
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
path <- taxify_download("register", verbose = FALSE)
file.exists(path)
#> [1] TRUE
options(old)
```
