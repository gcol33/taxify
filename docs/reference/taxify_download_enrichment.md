# Download one or more enrichment .vtr files

Downloads pre-built enrichment `.vtr` files from the taxify manifest.

## Usage

``` r
taxify_download_enrichment(enrichment, version = "latest", verbose = TRUE)
```

## Arguments

- enrichment:

  Character. One or more enrichment names (e.g.,
  `"conservation_status"`, `"griis"`, `"woodiness"`).

- version:

  Character. `"latest"` (default) or a specific version string.

- verbose:

  Logical. Default `TRUE`.

## Value

The path(s) to the downloaded `.vtr` file(s) (invisibly).

## Details

Available enrichments:

- conservation_status:

  IUCN conservation status (LC/NT/VU/EN/CR/EW/EX)

- griis:

  GRIIS invasive species status by country

- woodiness:

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
