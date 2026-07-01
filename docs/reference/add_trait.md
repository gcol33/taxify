# Add a trait from every source that carries it

Attaches a single harmonized trait (e.g. woodiness, plant height) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result, pulling from every enrichment source that provides it and
reconciling their differing vocabularies and units. Where the per-source
`add_*()` doors each join one dataset, `add_trait()` is the cross-source
verb: you name the trait, it gathers the sources.

## Usage

``` r
add_trait(
  x,
  trait,
  sources = "all",
  mode = c("wide", "coalesce"),
  priority = NULL,
  verbose = TRUE
)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- trait:

  Character. A single trait name; see
  [`list_traits()`](https://gillescolling.com/taxify/reference/list_traits.md)
  for the available traits and
  [`trait_info()`](https://gillescolling.com/taxify/reference/trait_info.md)
  for a trait's sources and units.

- sources:

  Which sources to use. Either the string `"all"` (the default) for
  every source registered for the trait, or a character vector of source
  names (see
  [`trait_info()`](https://gillescolling.com/taxify/reference/trait_info.md)).

- mode:

  One of `"wide"` (default) or `"coalesce"`. `"wide"` attaches one
  harmonized column per source. `"coalesce"` attaches one value per row,
  taken from the highest-priority source that has one.

- priority:

  Character vector of source names giving the coalesce order (highest
  priority first). Only used when `mode = "coalesce"`; defaults to the
  registered order for the trait (see
  [`trait_info()`](https://gillescolling.com/taxify/reference/trait_info.md)).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with added columns.

- `mode = "wide"`:

  One column per source, `<trait>_<source>`, each harmonized to the
  trait's shared vocabulary (categorical) or unit (numeric).

- `mode = "coalesce"`:

  Three columns: `<trait>` (the coalesced value), `<trait>_source`
  (which source it came from), and `<trait>_n` (how many sources had any
  value for that row). To inspect conflicts between sources, use
  `mode = "wide"`.

Numeric traits are returned in the trait's canonical unit (see
[`trait_info()`](https://gillescolling.com/taxify/reference/trait_info.md));
rows absent from a source get `NA`.

## Details

Each source keeps its provenance. In the default `"wide"` mode every
source becomes its own column (`<trait>_<source>`), so agreement and
conflict stay visible; sources are never silently collapsed. The opt-in
`"coalesce"` mode adds a single best-available value together with the
source that supplied it.

Harmonization is per source: a categorical source is mapped to the
trait's shared vocabulary, and a numeric source is converted to the
trait's canonical unit. For example, GIFT seed mass (grams) and Diaz et
al. seed mass (milligrams) both arrive as milligrams. The mappings and
units for a trait are listed by
[`trait_info()`](https://gillescolling.com/taxify/reference/trait_info.md).

A source enrichment that is not installed and cannot be downloaded or
built is skipped with a warning, and the trait is assembled from the
sources that are available.

## See also

[`list_traits()`](https://gillescolling.com/taxify/reference/list_traits.md)
to see available traits,
[`trait_info()`](https://gillescolling.com/taxify/reference/trait_info.md)
for a trait's sources and units. The per-source doors
([`add_zanne()`](https://gillescolling.com/taxify/reference/add_zanne.md),
[`add_gift()`](https://gillescolling.com/taxify/reference/add_gift.md),
[`add_diaz_traits()`](https://gillescolling.com/taxify/reference/add_diaz_traits.md),
[`add_leda()`](https://gillescolling.com/taxify/reference/add_leda.md))
join one dataset each.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

# One column per source, harmonized:
taxify("Abies alba") |>
  add_trait("woodiness")

# Numeric trait, coalesced to one value plus its provenance:
taxify("Abies alba") |>
  add_trait("seed_mass", mode = "coalesce")

options(old)
```
