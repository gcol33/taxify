# List every accepted ID of each matched name

[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
returns one accepted ID per name, and, when any name has several,
records in `accepted_ids` every accepted taxon the backbone files the
name under: a homonym published by two authors, or a name held twice,
once accepted and once as a doubtful or duplicate record. This verb lays
those out one row per (name, accepted ID), resolved against the
backbone, with the ID
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
picked marked. On the GBIF backbone each ID carries its occurrence
count, so the IDs to request occurrence data with can be read off
directly.

## Usage

``` r
taxify_ids(x, verbose = TRUE)
```

## Arguments

- x:

  A [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  result.

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame with one row per (matched input row, accepted ID), in input
order and, within a name, in the order of `accepted_ids` (the pick
first):

- input_name:

  The queried name.

- backbone:

  Backbone that matched the name.

- accepted_id:

  An accepted ID the name resolves to.

- accepted_name:

  The name of that accepted taxon.

- authorship:

  Its authorship.

- rank:

  Its rank.

- taxonomic_status:

  Its status in the backbone (`"ACCEPTED"`, GBIF's `"DOUBTFUL"`, WFO's
  `"UNCHECKED"`, ...).

- family:

  Its family.

- n_occurrences:

  GBIF occurrence records under this ID, including those of its synonyms
  and descendants (what a GBIF download by this key returns), as counted
  when the backbone was built. `NA` on a backbone without counts, and
  for an ID whose count was not taken.

- is_pick:

  Logical. Is this the `accepted_id`
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  reported?

Unmatched names contribute no rows.

## See also

[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md),
[`synonyms()`](https://gillescolling.com/taxify/reference/synonyms.md).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify(c("Quercus robur", "Pinus sylvestris")) |>
  taxify_ids()

options(old)
```
