# Cite data sources used in a taxify result

Prints formatted citations for the taxonomic backbone(s), enrichment
datasets, and the taxify package itself. Optionally writes a BibTeX
file.

## Usage

``` r
cite(x, ...)

# Default S3 method
cite(x, file = NULL, ...)

# S3 method for class 'character'
cite(x, file = NULL, source = NULL, ...)
```

## Arguments

- x:

  A `taxify_result` object, or a character vector of reference ids
  (cells of `<enrichment>:<id>` joined by `|`, as in `<trait>_refs`).

- ...:

  Unused.

- file:

  Optional file path. If provided, BibTeX entries are written to this
  file (extension should be `.bib`).

- source:

  For a character `x` only: `NULL` (default) when the ids carry their
  enrichment prefix, or the enrichment the bare ids belong to (e.g.
  `"austraits"` for the `austraits_dispersal_syndrome_source` column of
  `add_austraits(cols = "all")`).

## Value

For a `taxify_result`, `x`, invisibly (pipe-friendly). For reference
ids, invisibly, a data.frame with one row per distinct id: `ref` (the
qualified id), `source`, `ref_id`, `citation`, `doi`, and any further
columns the source's reference table carries.

## Details

Given reference ids instead of a result, `cite()` resolves them to the
works a trait value was taken from: the per-value references
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
returns with `provenance = TRUE` (`<trait>_refs`), or the `<col>_source`
column of an `add_<source>()` function read with `source =`.

## See also

Other Match and inspect names:
[`comm2sci()`](https://gillescolling.com/taxify/reference/comm2sci.md),
[`id2name()`](https://gillescolling.com/taxify/reference/id2name.md),
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md),
[`parse_name()`](https://gillescolling.com/taxify/reference/parse_name.md),
[`reconcile()`](https://gillescolling.com/taxify/reference/reconcile.md),
[`sci2comm()`](https://gillescolling.com/taxify/reference/sci2comm.md)

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data())

result <- taxify("Quercus robur", backbone = "wfo")
#> Matching 1 names...
result |> cite()
#> ── taxify citations ────────────────────────────────────────────────────────────
#>   [1] Colling G (2026). taxify: Offline Taxonomic Name Matching Against Darwin Core Backbones (version 0.7.1). doi:10.32614/CRAN.package.taxify
#>   [2] Borsch T, Berendsohn W, Dalcin E, Delmas M, Demissew S, Elliott A, Fritsch P, Fuchs A, Geltman D, Guner A, et al. (2020). World Flora Online: Placing taxonomists at the heart of a definitive and comprehensive global resource on the world's plants. Taxon 69:1311-1341. doi:10.1002/tax.12373
#>   ────────────────────────────────────────────────────────────
result |> cite(file = tempfile(fileext = ".bib"))
#> ── taxify citations ────────────────────────────────────────────────────────────
#>   [1] Colling G (2026). taxify: Offline Taxonomic Name Matching Against Darwin Core Backbones (version 0.7.1). doi:10.32614/CRAN.package.taxify
#>   [2] Borsch T, Berendsohn W, Dalcin E, Delmas M, Demissew S, Elliott A, Fritsch P, Fuchs A, Geltman D, Guner A, et al. (2020). World Flora Online: Placing taxonomists at the heart of a definitive and comprehensive global resource on the world's plants. Taxon 69:1311-1341. doi:10.1002/tax.12373
#>   ────────────────────────────────────────────────────────────
#>   BibTeX written to: C:\Users\GILLES~1\AppData\Local\Temp\RtmpCocUuZ\file1df8f275cfb.bib

options(old)
```
