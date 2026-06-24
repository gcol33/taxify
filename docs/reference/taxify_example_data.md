# Path to the bundled example database

taxify ships a tiny example database (a handful of species per backbone
plus matching enrichment tables) so that examples and quick experiments
run offline, without downloading the full multi-million-row backbones.

## Usage

``` r
taxify_example_data()
```

## Value

Character string. Path to the bundled example database directory, or
`""` if it is not installed.

## Details

Point taxify at it for the current session by setting the
`taxify.data_dir` option:

    old <- options(taxify.data_dir = taxify_example_data())
    taxify("Quercus robur") |> add_woodiness()
    options(old)  # restore the real data directory

The example database is read-only and covers only the species used in
the package examples; use the full downloaded backbones for real work.

## See also

[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md)
