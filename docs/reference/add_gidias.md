# Add invasive-species impact (EICAT / SEICAT, GIDIAS)

Joins per-species environmental- and socio-economic-impact aggregates
from GIDIAS (Bacher et al. 2025), the IPBES invasive-species
assessment's global impact compilation, to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. GIDIAS's individual impact records
are reduced to per-species indicators; the raw impact records are not
distributed.

## Usage

``` r
add_gidias(x, cols = NULL, verbose = TRUE)
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

The same data.frame with additional columns. The default set:

- gidias_eicat_category:

  EICAT environmental-impact category (`MC`/`MN`/`MO`/`MR`/`MV`/`DD`, or
  `NA` when no negative impact is recorded).

- gidias_eicat_mechanism:

  IUCN EICAT impact mechanism(s) behind the species' negative
  environmental impacts.

- gidias_seicat_category:

  SEICAT socio-economic-impact category (`MC`/`MN`/`MO`/`MR`/`DD`, or
  `NA`).

- gidias_ias_taxon:

  Functional group: `Plant`, `Invertebrate`, `Vertebrate`, or `Microbe`.

- gidias_realms:

  Realm(s) the impacts span: terrestrial, freshwater, and/or marine.

- gidias_n_records:

  Number of impact records for the species.

- gidias_n_sources:

  Number of distinct sources documenting the impacts.

`cols = "all"` additionally attaches the numeric EICAT/SEICAT magnitudes
(0-3), the affected well-being constituents, kingdom, the
negative-record count, and a global-extinction flag.

## Details

A species' EICAT category is the most severe magnitude among its
negative (harmful) environmental-impact records, on the IUCN scale
`"MC"` (Minimal Concern), `"MN"` (Minor), `"MO"` (Moderate), `"MR"`
(Major, local extinction), `"MV"` (Massive, global extinction), or
`"DD"` (Data Deficient); `gidias_seicat_category` applies the same rule
to socio-economic impact (SEICAT, `"MC"` to `"MR"`). For impact
reconciled across sources, use
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
with `"environmental_impact"` or `"socioeconomic_impact"`.

Source: GIDIAS (Bacher et al. 2025, Scientific Data; CC BY 4.0),
compiled for the IPBES thematic assessment report on invasive alien
species. Only the derived per-species aggregates are distributed here,
not the raw impact records.

## References

Bacher S et al. (2025) Global Impacts Dataset of Invasive Alien Species
(GIDIAS). Scientific Data 12:832.
[doi:10.1038/s41597-025-05184-5](https://doi.org/10.1038/s41597-025-05184-5)

## Examples

``` r
if (FALSE) { # \dontrun{
# Downloads the GIDIAS enrichment on first use.
taxify("Felis catus", backend = "gbif") |>
  add_gidias()
} # }
```
