# Coming from taxize and WorldFlora

This article maps the name-resolution functions of
[taxize](https://docs.ropensci.org/taxize/),
[WorldFlora](https://cran.r-project.org/package=WorldFlora) and related
packages to their taxify counterparts, and runs a WorldFlora task side
by side. taxify performs the name-resolution step of taxize and
WorldFlora, run offline against local backbone files. It ends with the
tasks for which another package is the better choice. Installation is
covered in [Get
started](https://gillescolling.com/taxify/articles/taxify.md).

1.  **Map** each call to its taxify counterpart with the tables below.

2.  **Match** the names with
    [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md),
    naming the `backbone` the old call read.

3.  **Join** the data the old workflow attached with an `add_<source>()`
    function or
    [`add_data()`](https://gillescolling.com/taxify/reference/add_data.md).

``` r

library(taxify)
```

## How the packages differ

taxize queries web services, about twenty of them, one per call and at
the time of the call; version 0.10.1 is on CRAN. WorldFlora matches
names against a World Flora Online (WFO) table that the user downloads
and reads into memory; version 1.14-5 is on CRAN. taxify downloads each
backbone once as a file and matches against it on disk, for 19 backbones
of all groups of organisms, and returns one row per input name with the
same columns whichever backbone matched it.

A web service returns the current treatment of a name on the day of the
query, including names added to it since taxify’s copy was built. taxify
returns the treatment of the backbone version on disk, recorded in every
row, and the same answer on every run until the backbone is updated.

## From taxize

| taxize | taxify | Notes |
|----|----|----|
| `gnr_resolve()`, `gna_verifier()` | [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) | Best match per name, against any backbone |
| `get_tsn()`, `get_gbifid()` and the other `get_*id()` | [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) | The ID is in `taxon_id` and `accepted_id` |
| `classification()` | [`upstream()`](https://gillescolling.com/taxify/reference/upstream.md), [`add_classification()`](https://gillescolling.com/taxify/reference/add_classification.md) | One taxon as rows, or a result as columns |
| `tax_name()` | [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) | `family`, `genus` and `rank` are columns |
| [`synonyms()`](https://gillescolling.com/taxify/reference/synonyms.md) | [`synonyms()`](https://gillescolling.com/taxify/reference/synonyms.md) | Every synonym of the accepted taxon |
| [`children()`](https://gillescolling.com/taxify/reference/children.md) | [`children()`](https://gillescolling.com/taxify/reference/children.md) | Accepted taxa of a genus or family |
| [`downstream()`](https://gillescolling.com/taxify/reference/downstream.md) | [`downstream()`](https://gillescolling.com/taxify/reference/downstream.md) | Accepted taxa at any rank below a taxon |
| [`upstream()`](https://gillescolling.com/taxify/reference/upstream.md) | [`upstream()`](https://gillescolling.com/taxify/reference/upstream.md) | The ranks above a taxon |
| [`sci2comm()`](https://gillescolling.com/taxify/reference/sci2comm.md), [`comm2sci()`](https://gillescolling.com/taxify/reference/comm2sci.md) | [`sci2comm()`](https://gillescolling.com/taxify/reference/sci2comm.md), [`comm2sci()`](https://gillescolling.com/taxify/reference/comm2sci.md) | From the vernacular names of GBIF, NCBI and the Open Tree of Life |
| [`id2name()`](https://gillescolling.com/taxify/reference/id2name.md) | [`id2name()`](https://gillescolling.com/taxify/reference/id2name.md) | A backbone ID to its name and accepted name |
| [`class2tree()`](https://gillescolling.com/taxify/reference/class2tree.md) | [`class2tree()`](https://gillescolling.com/taxify/reference/class2tree.md) | A taxonomy tree from the classifications |
| [`lowest_common()`](https://gillescolling.com/taxify/reference/lowest_common.md) | [`lowest_common()`](https://gillescolling.com/taxify/reference/lowest_common.md) | The lowest rank a set of names shares |

The functions with the same name in both packages do the same task,
against a local backbone in taxify. They are shown in [Exploring the
backbone](https://gillescolling.com/taxify/articles/exploring.md).

## From WorldFlora

| WorldFlora | taxify | Notes |
|----|----|----|
| [`WFO.match()`](https://rdrr.io/pkg/WorldFlora/man/WFO.match.html), [`WFO.match.fuzzyjoin()`](https://rdrr.io/pkg/WorldFlora/man/WFO.match2.html) | `taxify(backbone = "wfo")` | Exact and fuzzy matching in one call |
| [`WFO.one()`](https://rdrr.io/pkg/WorldFlora/man/WFO.match.html) | [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) | [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) returns one row per name directly |
| [`WFO.synonyms()`](https://rdrr.io/pkg/WorldFlora/man/WFO.match.html) | `synonyms(backbone = "wfo")` | The synonyms of a taxon |

[`WFO.match()`](https://rdrr.io/pkg/WorldFlora/man/WFO.match.html)
returns the WFO columns under their WFO names (`scientificName`,
`taxonID`, `taxonomicStatus`, `acceptedNameUsageID`) and several
candidate rows per name, which
[`WFO.one()`](https://rdrr.io/pkg/WorldFlora/man/WFO.match.html) reduces
to one.
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
returns `matched_name`, `taxon_id`, `taxonomic_status` and `accepted_id`
with one row per name, and
[`add_wfo_info()`](https://gillescolling.com/taxify/reference/add_wfo_info.md)
adds WFO’s own further columns. A WorldFlora workflow reads the backbone
file first:

``` r

library(WorldFlora)
wfo_data <- data.table::fread("classification.csv", encoding = "UTF-8")
matched <- WFO.match(spec.data = names, WFO.data = wfo_data, Fuzzy = 0.1)
best <- WFO.one(matched)
```

In taxify the backbone is downloaded on the first call:

``` r

names <- c("Quercus robur", "Quercus pedonculata", "Pinus silvestris",
           "Rosa canina")
res <- taxify(names, backbone = "wfo", verbose = FALSE)
res[, c("input_name", "matched_name", "accepted_name", "match_type")]
#>            input_name        matched_name    accepted_name match_type
#> 1       Quercus robur       Quercus robur    Quercus robur      exact
#> 2 Quercus pedonculata Quercus pedunculata    Quercus robur      fuzzy
#> 3    Pinus silvestris    Pinus sylvestris Pinus sylvestris   exact_ci
#> 4         Rosa canina         Rosa canina      Rosa canina      exact
#> Sources: WFO 2026.06 | cite() for full citations
```

*Quercus pedonculata* is a misspelling of *Quercus pedunculata*, which
WFO treats as a synonym of *Quercus robur*: the fuzzy match finds the
synonym, and the row carries its accepted name. *Pinus silvestris* is a
spelling of the epithet that the exact stage reads as *sylvestris*.

### Timings

`scripts/benchmark-worldflora.R` in the taxify repository times both
packages on names drawn from the WFO backbone: accepted binomials, and
the same names with one letter of each epithet changed so that they need
fuzzy matching. The run recorded in
`scripts/benchmark-worldflora-results.json` used taxify 0.7.0, vectra
0.13.0 and WorldFlora 1.14.5 under R 4.6.0 on Windows 11 x64 (build
26200), on 2026-10-13. taxify read its WFO backbone 2026.06; WorldFlora
read the WFO classification file of the Zenodo release in the script.

| Task              | taxify (s) | WorldFlora (s) |
|-------------------|------------|----------------|
| Load the backbone | 1.6        | 14.0           |
| 1000 names, exact | 1.0        | 14.2           |
| 1000 names, fuzzy | 9.7        | 3881.9         |

WorldFlora’s fuzzy matching ran with `Fuzzy = 0.1`. The two packages
differ in more than speed: WorldFlora returns every candidate within the
threshold for a person to choose from, and taxify returns one pick per
name with the others listed in `accepted_ids`.

## From other packages

- [rgbif](https://docs.ropensci.org/rgbif/),
  [worrms](https://docs.ropensci.org/worrms/) and
  [ritis](https://docs.ropensci.org/ritis/) query the live services of
  GBIF, WoRMS and ITIS. `taxify(backbone = "gbif")`, `"worms"` and
  `"itis"` match against local copies of the same backbones.

- [taxadb](https://docs.ropensci.org/taxadb/) also keeps local snapshots
  of backbones and looks names up in them with `filter_name()` and IDs
  with `filter_id()`. Its fuzzy functions match names that start with or
  contain a string; taxify’s fuzzy matching measures the distance
  between spellings.

- lcvplants matches against the Leipzig Catalogue of Vascular Plants
  with `lcvp_search()`; `taxify(backbone = "lcvp")` matches against the
  same catalogue.

- rWCVP, archived on CRAN in 2025, matched names against the World
  Checklist of Vascular Plants; `taxify(backbone = "wcvp")` matches
  against it, and
  [`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md)
  attaches the native and introduced range by botanical region.

- Taxonstand, archived on CRAN in 2023 at its maintainer’s request,
  matched against The Plant List, which has not been updated since 2013.
  WFO and the World Checklist of Vascular Plants continue it:
  `taxify(backbone = c("wcvp", "wfo"))`.

## When another package fits better

- **Names added to a backbone since its last release.** taxify matches
  against the version on disk; a web service through taxize, rgbif,
  worrms or ritis has the current one.

- **Choosing among candidates by hand.** taxify picks one taxon per name
  and lists the others; WorldFlora and taxize show every candidate for a
  person to choose.

- **Distribution queries.**
  [`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md)
  attaches the range by region; checklists and occurrence matrices built
  from WCVP regions are outside taxify.

- **Phylogenies.**
  [`class2tree()`](https://gillescolling.com/taxify/reference/class2tree.md)
  builds a tree from the classification, without branch lengths;
  [rotl](https://docs.ropensci.org/rotl/) reads the synthetic tree of
  the Open Tree of Life.

- **Occurrence and sequence records.** taxify requests GBIF records by
  key, as shown in [Requesting GBIF data for a species
  list](https://gillescolling.com/taxify/articles/gbif-requests.md);
  rgbif covers the rest of GBIF’s interface, and other packages cover
  sequence databases.

## Where next

- [Get started](https://gillescolling.com/taxify/articles/taxify.md):
  matching, checking and joining data in one session.

- [Exploring the
  backbone](https://gillescolling.com/taxify/articles/exploring.md): the
  functions that correspond to taxize’s.

- [Choosing and combining
  backbones](https://gillescolling.com/taxify/articles/backbones.md):
  the backbones and the fallback chain.
