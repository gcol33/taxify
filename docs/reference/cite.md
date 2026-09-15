# Cite data sources used in a taxify result

Prints formatted citations for the taxonomic backbone(s), enrichment
layers, and the taxify package itself. Optionally writes a BibTeX file.

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
  `"austraits"` for the `dispersal_syndrome_source` column of
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
returns with `provenance = TRUE` (`<trait>_refs`), or a door's
`<col>_source` column read with `source =`.

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data())

result <- taxify("Quercus robur", backbone = "wfo")
result |> cite()
result |> cite(file = tempfile(fileext = ".bib"))

options(old)
```
