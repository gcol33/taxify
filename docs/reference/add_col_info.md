# Add COL-specific columns

Joins extra Catalogue of Life columns to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `taxon_id` in the COL backbone. Only enriches rows
where `backbone == "col"`.

## Usage

``` r
add_col_info(x)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  with `backbone == "col"`.

## Value

The same data.frame with additional columns:

- notho:

  Hybrid type from COL: `"generic"`, `"specific"`, `"infrageneric"`, or
  `"infraspecific"`.

- nomenclaturalCode:

  Nomenclatural code (`"ICN"`, `"ICZN"`, etc.).

- nomenclaturalStatus:

  Nomenclatural status.

- name_published_in:

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

taxify("Quercus robur", backbone = "col") |>
  add_col_info()
#> Matching 1 names...
#>      input_name  matched_name accepted_name   taxon_id accepted_id    rank
#> 1 Quercus robur Quercus robur Quercus robur col-ex-001  col-ex-001 species
#>     family   genus epithet authorship accepted_authorship is_synonym
#> 1 Fagaceae Quercus   robur         L.                  L.      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA      col
#>           backbone_version kingdom_group taxon_group  life_form qualifier
#> 1 col:example (2026-06-24)       plantae  angiosperm angiosperm      <NA>
#>   qualifier_position aggregate_fallback hybrid_type notho nomenclaturalCode
#> 1               <NA>                 NA        <NA>  <NA>              <NA>
#>   nomenclaturalStatus name_published_in kingdom phylum col_class order
#> 1                <NA>              <NA>    <NA>   <NA>      <NA>  <NA>
#>   infraspecificEpithet is_extinct is_marine is_freshwater is_terrestrial
#> 1                 <NA>         NA        NA            NA             NA
#> Sources: COL example | cite() for full citations

options(old)
```
