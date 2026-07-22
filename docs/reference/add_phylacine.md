# Add mammal traits including extinct species (PHYLACINE)

Joins PHYLACINE mammal traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. PHYLACINE covers extant plus
recently and prehistorically extinct mammals; it is offered alongside
[`add_pantheria()`](https://gillescolling.com/taxify/reference/add_pantheria.md)
and
[`add_combine()`](https://gillescolling.com/taxify/reference/add_combine.md),
not as a replacement.

## Usage

``` r
add_phylacine(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) the curated set, `"all"`
  every column the source carries, or a character vector of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- phylacine_mass_g:

  Body mass (g).

- phylacine_diet_plant_pct:

  Percent of diet that is plant.

- phylacine_diet_vertebrate_pct:

  Percent of diet that is vertebrate.

- phylacine_diet_invertebrate_pct:

  Percent of diet that is invertebrate.

- phylacine_terrestrial:

  Terrestrial habit (0/1).

- phylacine_marine:

  Marine habit (0/1).

- phylacine_freshwater:

  Freshwater habit (0/1).

- phylacine_aerial:

  Aerial habit (0/1).

- phylacine_island_endemicity:

  Island endemicity class.

- phylacine_iucn_status:

  IUCN status (includes EP = extinct in prehistory, EX, EW).

- phylacine_mass_method:

  How the body mass was obtained (the PHYLACINE `Mass.Method` field,
  verbatim): `Reported`, `Imputed`, or an allometric estimate (e.g.
  "Assumed isometric based on head-body length").

- phylacine_mass_method_class:

  Coarse provenance of the body mass: `reported` (measured/compiled),
  `estimated` (allometric or same-size analogy), or `imputed`
  (phylogenetic gap-fill). Only `reported` is an observation; the others
  are model estimates.

## Details

Source: PHYLACINE v1.2 (Faurby et al. 2018, Ecology, CC0). Coverage:
~5.8k mammal species including extinct taxa. `Mass.g` is partly modelled
(PHYLACINE gap-fills data-poor and extinct species);
`phylacine_mass_method` / `phylacine_mass_method_class` record how each
mass was derived, so a modelled mass is not mistaken for a measurement
where PHYLACINE is the only source.

## References

Faurby S et al. (2018) PHYLACINE 1.2: The Phylogenetic Atlas of Mammal
Macroecology. Ecology 99:2626.
[doi:10.1002/ecy.2443](https://doi.org/10.1002/ecy.2443)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Mammuthus primigenius", backbone = "gbif") |>
  add_phylacine()
} # }
```
