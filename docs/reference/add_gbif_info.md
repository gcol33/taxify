# Add GBIF-specific columns

Joins extra GBIF backbone columns to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `taxon_id` in the GBIF backbone. Only enriches rows
where `backend == "gbif"`.

## Usage

``` r
add_gbif_info(x)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  with `backend == "gbif"`.

## Value

The same data.frame with additional columns:

- notho_type:

  Hybrid type: `"GENERIC"`, `"SPECIFIC"`, or `"INFRASPECIFIC"`.

- nom_status:

  Nomenclatural status (may contain multiple values).

- bracket_authorship:

  Basionym author in parentheses.

- bracket_year:

  Basionym author year.

- gbif_year:

  Combining author year.

- name_published_in:

  Publication citation.

- origin:

  How the name entered the backbone.

- infra_specific_epithet:

  Infraspecific epithet.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus robur", backend = "gbif") |>
  add_gbif_info()

options(old)
```
