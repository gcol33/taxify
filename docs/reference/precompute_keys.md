# Precompute matching keys at build time

Used by the `taxifydb` build pipeline and by taxify's own test fixtures.
Adds `key_ci`, `key_normalized`, `key_species`, and `fuzzy_block`
columns to the backbone data.frame for direct lookup at query time. For
a syntaxon backbone (`code = "syntaxon"`) it adds `key_ci`,
`key_normalized` (from
[`normalize_syntaxon_name()`](https://gillescolling.com/taxify/reference/normalize_syntaxon_name.md)),
`block_key`, the name's first word, which the fuzzy pass groups
candidates by, and `key_stem`, the name's plant-name stems without their
epithets, which resolves a unit written in short form; a syntaxon has no
genus or epithet.

## Usage

``` r
precompute_keys(
  df,
  name_col,
  genus_col = NULL,
  epithet_col = NULL,
  code = "taxon"
)
```

## Arguments

- df:

  The backbone data.frame.

- name_col:

  Name of the canonical name column.

- genus_col:

  Name of the genus column (taxon code only).

- epithet_col:

  Name of the specific epithet column (taxon code only).

- code:

  Nomenclature code of the backbone: `"taxon"` (default) or
  `"syntaxon"`.

## Value

The data.frame with added key columns.
