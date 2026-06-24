# Precompute matching keys at build time

Used by the `taxifydb` build pipeline and by taxify's own test fixtures.
Adds `key_ci`, `key_normalized`, `key_species`, and `fuzzy_block`
columns to the backbone data.frame for direct lookup at query time.

## Usage

``` r
precompute_keys(df, name_col, genus_col, epithet_col)
```

## Arguments

- df:

  The backbone data.frame.

- name_col:

  Name of the canonical name column.

- genus_col:

  Name of the genus column.

- epithet_col:

  Name of the specific epithet column.

## Value

The data.frame with added key columns.
