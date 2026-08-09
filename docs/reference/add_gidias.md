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
add_gidias(x, group = "Any", cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- group:

  Character. Which affected native taxon the impact is measured against:

  - `"Any"` (default): every impact record for the species, the
    species-level summary.

  - One of `"Plant"`, `"Invertebrate"`, `"Vertebrate"`, `"Microbe"`,
    `"Fungi"`: only the impacts recorded against that group.

  - Several (e.g. `c("Plant", "Vertebrate")`): adds columns with a group
    suffix (e.g. `gidias_eicat_category_Plant`).

  - `"all"`: one column set per group, `"Any"` included.

  List them with `enrichment_groups("gidias")`.

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

- gidias_ncp_direction:

  Direction of the species' impact on nature's contributions to people:
  `"Negative"`, `"Positive"`, `"Neutral"`, or a combination
  (`"Negative; Positive"`) where the records disagree. GIDIAS scores no
  magnitude for this block, so there is no category to report.

- gidias_ias_taxon:

  Functional group: `Plant`, `Invertebrate`, `Vertebrate`, or `Microbe`.

- gidias_realms:

  Realm(s) the impacts span: terrestrial, freshwater, and/or marine.

- gidias_n_records:

  Number of impact records for the species.

- gidias_n_sources:

  Number of distinct sources documenting the impacts.

`cols = "all"` additionally attaches the numeric EICAT/SEICAT magnitudes
(0-3), the affected well-being constituents and contributions to people
(`gidias_ncp_affected`), kingdom, the negative-record count, and a
global-extinction flag.

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

## What a species impacts

GIDIAS records the affected native taxon per impact record, so `group`
asks the question at that grain: `add_gidias(group = "Invertebrate")`
scores *Felis catus* `"MO"` (reduced populations) where the default
`"Any"` scores it `"MV"`, the global extinctions it drove among
vertebrates. 28% of species with a recorded affected taxon impact two or
more of the five groups, so for those the species-level category is the
most severe impact on anything, not the impact on each thing.

The vocabulary is the coarse one GIDIAS controls: `"Vertebrate"`, not
`"Aves"`. `"Any"` is the only group carrying the impact records with no
affected taxon recorded (12% of the negative ones) and the two
people-facing blocks, so `gidias_seicat_category` and
`gidias_ncp_direction` are `NA` on every other group: impact on people
is not a question the affected-native-taxon axis can answer.

## References

Bacher S et al. (2025) Global Impacts Dataset of Invasive Alien Species
(GIDIAS). Scientific Data 12:832.
[doi:10.1038/s41597-025-05184-5](https://doi.org/10.1038/s41597-025-05184-5)

## Examples

``` r
if (FALSE) { # \dontrun{
# Downloads the GIDIAS enrichment on first use.
taxify("Felis catus", backbone = "gbif") |>
  add_gidias()

# What the cat does to invertebrates, rather than to anything at all.
taxify("Felis catus", backbone = "gbif") |>
  add_gidias(group = "Invertebrate")

taxify("Felis catus", backbone = "gbif") |>
  add_gidias(group = c("Invertebrate", "Vertebrate"))
} # }
```
