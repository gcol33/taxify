# Cite data sources used in a taxify result

Prints formatted citations for the taxonomic backbone(s), enrichment
layers, and the taxify package itself. Optionally writes a BibTeX file.

## Usage

``` r
cite(x, file = NULL)
```

## Arguments

- x:

  A `taxify_result` object.

- file:

  Optional file path. If provided, BibTeX entries are written to this
  file (extension should be `.bib`).

## Value

`x`, invisibly (pipe-friendly).

## Examples

``` r
# \donttest{
result <- taxify("Quercus robur", backend = "wfo")
result |> cite()
result |> cite(file = tempfile(fileext = ".bib"))
# }
```
