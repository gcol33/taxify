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
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

result <- taxify(c("Quercus robur", "Pinus sylvestris"))
result |> export_data(tempfile(fileext = ".vtr"))
result |> export_data(tempfile(fileext = ".csv"))
result |> export_data(tempfile(fileext = ".tsv"))

options(old)
```
