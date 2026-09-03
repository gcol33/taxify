# Download one or more enrichment .vtr files

Downloads pre-built enrichment `.vtr` files from the taxify manifest.

## Usage

``` r
taxify_download_enrichment(
  enrichment,
  version = "latest",
  content_id = NULL,
  verbose = TRUE
)
```

## Arguments

- enrichment:

  Character. One or more enrichment names (e.g., `"iucn"`, `"griis"`,
  `"zanne"`).

- version:

  Character. `"latest"` (default) or a specific version string.

- content_id:

  Character or `NULL` (default). The content id of one exact build – the
  md5 of its `.vtr`, as recorded by
  [`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md)
  and by the manifest. Given one, taxify fetches that build from the
  immutable copy published beside the rolling asset, verifies the bytes
  hash back to the id, and makes it the active build; the build it
  replaces is kept on disk under its own content id. This is what turns
  a lockfile's recorded id back into bytes. Pass one id per
  `enrichment`, or one shared by all of them.

- verbose:

  Logical. Default `TRUE`.

## Value

The path(s) to the downloaded `.vtr` file(s) (invisibly).

## Details

Available enrichments:

- iucn:

  IUCN conservation status (LC/NT/VU/EN/CR/EW/EX)

- griis:

  GRIIS invasive species status by country

- zanne:

  Zanne et al. 2014 woody/herbaceous classification

- wcvp:

  WCVP native range by TDWG botanical region

- eive:

  EIVE 1.0 ecological indicator values (European plants)

- diaz_traits:

  Diaz et al. 2022 seed mass and plant height

- elton_traits:

  EltonTraits 1.0 diet and foraging (birds + mammals)

- avonet:

  AVONET bird morphology and migration

- pantheria:

  PanTHERIA mammal life-history traits

- common_names:

  GBIF vernacular names (multi-language)

- amphibio:

  AmphiBIO amphibian life-history and ecological traits

- leda:

  LEDA Traitbase NW European plant traits (Kleyer et al. 2008)

## See also

[`taxify_store()`](https://gillescolling.com/taxify/reference/taxify_store.md)
for the builds already on disk,
[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md)
to reinstall everything a lockfile pins.
