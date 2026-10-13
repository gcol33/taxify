# Add Euro+Med PlantBase distribution status

Joins the per-area status Euro+Med PlantBase states for a taxon (native,
naturalised, introduced, casual, ...) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result, for the areas or countries asked for. The names and the ids of
the `euromed` backbone are the same taxa the status is recorded on, so a
result matched against any backbone joins through its accepted name.

## Usage

``` r
add_euromed_distribution(x, region, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- region:

  Character. ISO 3166-1 alpha-2 country code(s), Euro+Med area code(s),
  or `"all"`. A code that is an ISO code of a Euro+Med area is read as
  the country; anything else must be an area code, as listed by
  [`euromed_areas()`](https://gillescolling.com/taxify/reference/euromed_areas.md).

  - Single region: adds `euromed_status` (no suffix).

  - Several regions: adds `euromed_status_<code>` per region.

  - `"all"`: one column per area.

- cols:

  Which columns to attach. `NULL` (the default) attaches
  `euromed_status`; a character vector attaches just those, and `"all"`
  attaches every column the source carries (see
  [`enrichment_cols()`](https://gillescolling.com/taxify/reference/enrichment_cols.md)),
  among them `euromed_status_detail`, `euromed_status_source`,
  `area_name`, `iso2` and the taxon's Euro+Med UUID, `taxon_id`.

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with `euromed_status`, one of `"native"`,
`"naturalised"`, `"introduced"`, `"casual"`, `"cultivated"`,
`"doubtful"` or `"extinct"`, and `NA` where Euro+Med states nothing for
the region. `euromed_status_detail` carries the term as Euro+Med words
it (`"endemic"`, `"introduced: uncertain degree of naturalisation"`).
`euromed_status_source` holds the ids of the citing references; resolve
them with
`cite(x$euromed_status_source, source = "euromed_distribution")`.

## Details

Source: Euro+Med PlantBase (CC BY-SA), European and Mediterranean
vascular plants, bryophytes and some fungi and algae. A report Euro+Med
marks as made in error is not carried; a former presence is `"extinct"`.
Where the records of one taxon and area disagree, the stronger claim
wins in the order given above (a taxon is native wherever a record says
so), and the references are those of the records stating it. The country
of an area comes from its own name, so a combined area has none and its
countries are read from the level-2 areas.

## See also

[`euromed_areas()`](https://gillescolling.com/taxify/reference/euromed_areas.md),
[`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md)

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Solidago canadensis") |>
  add_euromed_distribution(region = "DE")

options(old)
```
