# Load the unified genus register into memory

Reads `genus_register.vtr` from disk and caches it as a data.frame in
`.taxify_env$register`. Subsequent calls reuse the cached version unless
`force = TRUE`.

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

The register data.frame (invisibly).

## Details

The register contains one row per genus with columns: `genus`,
`kingdom`, `phylum`, `class`, `order`, `family`, `life_form`.
