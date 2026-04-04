# Export a taxify result to file

Writes a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result (with any enrichments) to disk in one of several formats. The
default `.vtr` format preserves column types and is fast to re-read with
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md).

## Usage

``` r
export_data(x, path, overwrite = FALSE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- path:

  Character. Output file path. The format is inferred from the
  extension: `.vtr`, `.csv`, `.tsv`, or `.xlsx`.

- overwrite:

  Logical. Overwrite an existing file? Default `FALSE`.

## Value

Invisibly returns `path`.

## Examples

``` r
if (FALSE) { # \dontrun{
result <- taxify(c("Quercus robur", "Pinus sylvestris"))
result |> add_conservation_status() |> export_data("my_results.vtr")
result |> export_data("my_results.csv")
result |> export_data("my_results.tsv")
} # }
```
