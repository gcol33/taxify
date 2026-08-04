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
  mode = c("coalesce", "wide"),
  combine = NULL,
  priority = NULL,
  verbose = TRUE,
  aggregate_trait_fallback = getOption("taxify.aggregate_trait_fallback", TRUE)
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

  One of `"coalesce"` (default) or `"wide"`. `"coalesce"` reduces the
  sources to one value per row (see `combine`). `"wide"` attaches one
  harmonized column per source.

- combine:

  How `mode = "coalesce"` reduces the per-source values for a row.
  `NULL` (default) is method-aware: when the trait's sources agree in
  method it uses `"median"` for numeric traits and `"first"` for
  categorical traits; when sources measure the trait differently (a
  source carries a caution, e.g. maximum vs fine-root diameter) it uses
  `"complete"` instead of blending them. Numeric options: `"median"`,
  `"mean"`, `"first"` (highest-priority source that has a value),
  `"min"`, `"max"`, `"complete"` (the single most populated source,
  reported verbatim). Categorical options: `"first"`, `"vote"` (majority
  across sources, ties broken by priority), or `"complete"`. Median is
  the numeric default for concordant sources because trait values are
  skewed, so a single outlier should not decide the value; `"complete"`
  is the default for discordant sources because a median across methods
  matches no method. Passing `combine` explicitly overrides this and is
  applied to all sources.

- priority:

  Character vector of source names giving the priority order (highest
  priority first), used by `combine = "first"`, for tie-breaking
  `combine = "vote"`, and to break ties in `combine = "complete"`. Only
  used when `mode = "coalesce"`; defaults to the registered order for
  the trait (see
  [`trait_info()`](https://gillescolling.com/taxify/reference/trait_info.md)).

- verbose:

  Logical. Default `TRUE`.

- aggregate_trait_fallback:

  Logical. When an aggregate or hybrid name has no trait record of its
  own, fall back to the underlying binomial. Defaults to
  `getOption("taxify.aggregate_trait_fallback", TRUE)`, so it can be set
  per call or for the session. Grain-pinned sources are unaffected.

## Value

The same data.frame with added columns.

- `mode = "coalesce"`:

  `<trait>` (the reduced value); `<trait>_unit` (the canonical unit,
  numeric traits only); `<trait>_sources` (the source it came from, or
  the comma-separated contributing sources with an aggregating
  `combine`); `<trait>_n` (how many sources backed the value); for
  numeric traits, `<trait>_min` and `<trait>_max` (the range of values
  behind the headline – across the contributing sources, and across a
  source's own records where that spread was recorded at build time, so
  a life-stage or population span stays visible); and, only when a
  source measured the trait differently, `<trait>_caution` explaining
  the method difference. To inspect every source, use `mode = "wide"`.

- `mode = "wide"`:

  One column per source, `<trait>_<source>`, each harmonized to the
  trait's shared vocabulary (categorical) or unit (numeric);
  `<trait>_unit`; and `<trait>_caution` on rows where a cautioned source
  supplied a value.

Numeric traits are returned in the trait's canonical unit (see
[`trait_info()`](https://gillescolling.com/taxify/reference/trait_info.md));
rows absent from a source get `NA`.

## Details

Each source keeps its provenance. The default `"coalesce"` mode reduces
the sources to one value per row plus the columns that document it – its
unit, the sources that contributed, how many, and a caution when the
sources measure the trait by different methods. The opt-in `"wide"` mode
instead gives every source its own column (`<trait>_<source>`), so
per-source agreement and conflict stay fully visible.

Harmonization is per source: a categorical source is mapped to the
trait's shared vocabulary, and a numeric source is converted to the
trait's canonical unit. For example, GIFT seed mass (grams) and Diaz et
al. seed mass (milligrams) both arrive as milligrams. The mappings and
units for a trait are listed by
[`trait_info()`](https://gillescolling.com/taxify/reference/trait_info.md).

Some sources report the same trait in the right unit but under a
different definition (for example AusTraits root diameter is a maximum
including coarse roots, while GRooT is fine-root only). Such a source
carries a caution in the registry. In `mode = "coalesce"` with the
default `combine`, a trait whose sources disagree in method is not
blended: the most complete source is reported and `<trait>_caution`
records the difference.
[`trait_info()`](https://gillescolling.com/taxify/reference/trait_info.md)
lists each source's harmonization note and caution.

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

# One coalesced value plus its provenance (unit, sources, count):
taxify("Abies alba") |>
  add_trait("seed_mass")

# One column per source, to inspect agreement and conflict:
taxify("Abies alba") |>
  add_trait("woodiness", mode = "wide")

options(old)
```
