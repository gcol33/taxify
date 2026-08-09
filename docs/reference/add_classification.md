# Add the full higher classification to a taxify result

Attaches the Linnaean ranks above family (kingdom, phylum, class, order)
to a [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by joining each matched row back to its backbone. The core
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
output already carries `family` and `genus`; this fills the ranks above
them, for whichever ranks the matched backbone stores. Rows matched by
different backbones are each joined against their own backbone.

## Usage

``` r
add_classification(
  x,
  ranks = c("kingdom", "phylum", "class", "order"),
  verbose = TRUE
)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- ranks:

  Character vector of ranks to attach. Default
  `c("kingdom", "phylum", "class", "order")`.

- verbose:

  Logical. Default `TRUE`.

## Value

`x` with the requested rank columns added. A rank a backbone does not
store is left `NA` (WFO, for example, carries no ranks above family).

## See also

[`add_col_info()`](https://gillescolling.com/taxify/reference/add_col_info.md),
[`add_gbif_info()`](https://gillescolling.com/taxify/reference/add_gbif_info.md)
for backbone-specific extras.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Naja naja", backbone = "reptiledb") |>
  add_classification()

options(old)
```
