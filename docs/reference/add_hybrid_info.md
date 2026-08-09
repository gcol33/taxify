# Add hybrid parent and type information

Parses the `input_name` column from a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result to extract hybrid parent names and classify the hybrid type.

## Usage

``` r
add_hybrid_info(x)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

## Value

The same data.frame with additional columns:

- hybrid_parent_1:

  First parent (full binomial), `NA` if not a hybrid formula.

- hybrid_parent_2:

  Second parent (full binomial, abbreviated or omitted genus expanded),
  `NA` if not a hybrid formula.

- hybrid_parent_1_accepted, hybrid_parent_2_accepted:

  The accepted name each parent resolves to against the backbone(s) used
  for `x` (from the result's metadata), or `NA` if the parent did not
  match.

- hybrid_parent_1_id, hybrid_parent_2_id:

  The backbone `taxon_id` of the accepted taxon each parent resolves to,
  usable directly with
  [`id2name()`](https://gillescolling.com/taxify/reference/id2name.md),
  or `NA` if the parent did not match. An unresolved hybrid formula
  carries `NA` in the result's own `taxon_id` (it has no single backbone
  record); these two columns are where the component IDs live.

- hybrid_type:

  One of `"nothogenus"`, `"nothospecies"`, `"formula"`, or `NA` if not a
  hybrid (same value as the `hybrid_type` column already on a
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  result).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus pyrenaica x Q. petraea") |>
  add_hybrid_info()

options(old)
```
