# Add COL-specific columns

Joins extra Catalogue of Life columns to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `taxon_id` in the COL backbone. Only enriches rows
where `backend == "col"`.

## Usage

``` r
add_col_info(x)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  with `backend == "col"`.

## Value

The same data.frame with additional columns:

- notho:

  Hybrid type from COL: `"generic"`, `"specific"`, `"infrageneric"`, or
  `"infraspecific"`.

- nomenclaturalCode:

  Nomenclatural code (`"ICN"`, `"ICZN"`, etc.).

- nomenclaturalStatus:

  Nomenclatural status.

- namePublishedIn:

  Original publication reference.

- kingdom:

  Kingdom classification.

- phylum:

  Phylum classification.

- col_class:

  Class classification (renamed to avoid conflict with R's `class`
  function).

- order:

  Order classification.

- infraspecificEpithet:

  Infraspecific epithet.

- is_extinct:

  Logical. Whether the species is extinct (from SpeciesProfile, if
  available).

- is_marine:

  Logical. Whether the species is marine.

- is_freshwater:

  Logical. Whether the species is freshwater.

- is_terrestrial:

  Logical. Whether the species is terrestrial.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus robur", backend = "col") |>
  add_col_info()

options(old)
```
