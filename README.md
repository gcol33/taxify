# taxify

*offline taxonomic name resolution*

[![CRAN status](https://www.r-pkg.org/badges/version/taxify)](https://CRAN.R-project.org/package=taxify)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/grand-total/taxify)](https://cran.r-project.org/package=taxify)
[![Monthly downloads](https://cranlogs.r-pkg.org/badges/taxify)](https://cran.r-project.org/package=taxify)
[![R-CMD-check](https://github.com/gcol33/taxify/actions/workflows/R-CMD-check.yml/badge.svg)](https://github.com/gcol33/taxify/actions/workflows/R-CMD-check.yml)
[![Codecov test coverage](https://codecov.io/gh/gcol33/taxify/graph/badge.svg)](https://app.codecov.io/gh/gcol33/taxify)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Offline taxonomic name matching against local Darwin Core backbones, with matching done in C.**

Hand it a column of messy species names. `taxify` cleans them, matches them against
a backbone you already have on disk, resolves synonyms to accepted names, and returns
one standardized data.frame. Every step runs locally against a versioned snapshot, so
there are no API calls, no rate limits, and the same input gives the same output on any
machine. The matching engine is written in C through the [vectra](https://github.com/gcol33/vectra)
columnar engine.

```r
library(taxify)

# first call installs the default backbone set (COL + GBIF + ITIS, ~4 GB)
taxify(c(
  "Quercus robur",
  "Pinus abies",        # synonym, resolved to Picea abies
  "Quercus robus",      # typo, fuzzy-corrected to Q. robur
  "Taraxacum officinale"
))
```

## Local, not over the wire

The usual route for name resolution, `taxize`, calls out to around twenty web services
(NCBI, ITIS, GBIF, EOL, IUCN, WoRMS, Tropicos, ...). That covers everything, but it ties
each run to network latency, service uptime, and rate limits, and the answer can change
between runs as upstream services update. `taxify` ships the backbones as pre-built local
snapshots and matches against them in C, so a list of thousands resolves in seconds and a
result is reproducible from the recorded backbone version.

The closest local analogue is [taxadb](https://docs.ropensci.org/taxadb/), which also stores
backbone snapshots on disk; the [migration vignette](https://gillescolling.com/taxify/articles/migration.html)
walks through the differences in matching strategy, output schema, and enrichment.

## Fifteen backbones, one call

`taxify` ships fifteen backbones as compressed `.vtr` files, pre-built by the companion
[taxifydb](https://github.com/gcol33/taxifydb) package, downloaded once, and matched
locally. Pass several and they form a fallback chain: a name unmatched by the first
backbone cascades to the next.

```r
# WFO first (plants), then GBIF for whatever WFO doesn't cover
taxify(
  c("Quercus robur", "Panthera leo", "Amanita muscaria"),
  backend = c("wfo", "gbif")
)
```

<!-- manifest:backbone-table -->
| Backbone | Scope | Names | Download |
|---|---|---|---|
| [WFO](https://www.worldfloraonline.org/) | Vascular plants | 1.6M | 797 MB |
| [COL](https://www.catalogueoflife.org/) | All kingdoms | 5.3M | 2.0 GB |
| [GBIF](https://www.gbif.org/) | All kingdoms | 6.4M | 1.9 GB |
| [ITIS](https://www.itis.gov) | US focus, freshwater/marine | 992k | 205 MB |
| [NCBI](https://www.ncbi.nlm.nih.gov/taxonomy) | All life | 2.8M | 514 MB |
| [OTT](https://opentreeoflife.github.io/) | All life (synthetic) | 3.7M | 727 MB |
| [WoRMS](https://www.marinespecies.org/) | Marine/aquatic | 1.6M | 347 MB |
| [Euro+Med](https://europlusmed.org/) | European/Mediterranean plants | 147k | 35 MB |
| [Species Fungorum](https://www.speciesfungorum.org/) | Fungi | 315k | 71 MB |
| [AlgaeBase](https://www.algaebase.org/) | Algae | 172k | 36 MB |
| [FishBase](https://www.fishbase.org/) | Fishes | 103k | 19 MB |
| [SeaLifeBase](https://www.sealifebase.org/) | Non-fish marine/aquatic | 134k | 29 MB |
| [Reptile Database](http://www.reptile-database.org/) | Reptiles | 50k | 10 MB |
| [LCVP](https://github.com/idiv-biodiversity/LCVP) | Vascular plants | 1.3M | 252 MB |
| [WCVP](https://powo.science.kew.org/) | Vascular plants | 1.4M | 334 MB |
<!-- /manifest:backbone-table -->

`list_backbones()` returns this table live, with the installed and version status of
each. `taxify_databases()` adds the enrichment layers alongside it for the full picture.

## Names are cleaned before matching

Input names are normalized first, so the fuzzy pass only runs on names that genuinely
differ from the backbone rather than on names that just carry extra authorship or
qualifiers:

```r
"Quercus robur L."            ->  "Quercus robur"        # authorship stripped
"Pinus cf. sylvestris"        ->  "Pinus sylvestris"     # qualifier removed
"Nothofagus x alpina"         ->  "Nothofagus × alpina"  # hybrid sign normalized (x -> ×)
"Betula pendula (Roth) Doll"  ->  "Betula pendula"       # parenthesized author stripped
```

Fuzzy matching is configurable (Damerau-Levenshtein, Levenshtein, or Jaro-Winkler, with a
distance threshold), and runs genus-blocked so a typo only competes against names in the
same genus.

Both packages can read the same WFO snapshot, so the comparison below is between
the two matching implementations rather than between two versions of WFO. taxify
queries the columnar `.vtr` taxifydb builds from the Zenodo Darwin Core archive;
WorldFlora reads the classification table inside that same archive into RAM.

The corpus is 1,000 accepted binomials drawn from the backbone with a fixed seed.
The fuzzy corpus is those names with one substituted character in each epithet, so
every name has to be resolved by distance -- a deliberate worst case, not a mixed
list where most names still match exactly.

| | taxify | WorldFlora |
|---|---|---|
| Backbone load | 4.9 s | 20.1 s (CSV into RAM) |
| Exact match, 1,000 names | 2.2 s | 17.1 s |
| Fuzzy match, 1,000 names | 18.8 s | 4,192 s (70 min) |
| Fuzzy match, 5,000 names | 26.6 s | not measured |
| Peak R heap, fuzzy 1,000 | 678 MB | 4.0 GB |

`scripts/benchmark-worldflora.R` produces these numbers and
`scripts/benchmark-worldflora-results.json` records the run, including package
versions and the backbone snapshot. Both packages were measured back to back on
one machine (Windows 11, R 4.6.0, taxify 0.3.21, WorldFlora 1.14.5) that was
carrying other work at the time, so treat the ratios as the reliable figures and
the absolute times as an upper bound.

Where the gap comes from: taxify runs the fuzzy pass genus-blocked, so a typo
competes only against names in the same genus, and the comparison itself runs in
C. Scaling five times the names costs 1.4x the time, because the fixed cost of
opening the backbone dominates.

taxize is not in the table. It resolves names through the Global Names online
resolver rather than a local backbone, so its time is network-bound and varies
with service load; there is no way to measure it against a fixed snapshot the way
these two can be measured against each other.

## What you get back

`taxify()` returns one row per input name with a fixed schema: the matched and accepted
names with their IDs and authorship, rank, family, genus, epithet, synonym / hybrid /
ambiguity flags, any taxonomic qualifier, the match type (`exact`, `exact_ci`, `fuzzy`,
`abbrev`, `hybrid_formula`, `out_of_scope`, or `none`), the fuzzy distance, a coarse kingdom / taxon-group
label, the backend, and the backbone version used. `summary()` prints a compact digest of
how the batch resolved.

```r
result <- taxify(c("Quercus robur", "Pinus abies", "Quercus robus", "Taraxacum officinale"))
summary(result)
#> -- taxify results ----------------------------------------------------
#>   backend: WFO  |  4 names submitted
#>
#>   matched         4  (exact: 2, case-insensitive: 0, fuzzy: 2, abbrev: 0)
#>   --------------------------------------------------------------
#>   taxon groups: vascular plant: 4
```

## Navigate the backbone, not just match it

`taxify()` resolves a name to its accepted name. The same local backbone file
answers the related lookups too — synonyms, children, ancestors, descendants —
with nothing else to download:

```r
synonyms("Picea abies")                     # every synonym of an accepted name
children("Quercus")                         # accepted species in a genus
downstream("Fagaceae", downto = "genus")    # all genera under a family
upstream("Quercus robur", to = "family")    # the family a species sits in
```

Decompose a name without matching it, or go from a backend ID back to a name:

```r
parse_name("Quercus robur (L.) H.Karst.")   # genus / epithet / author / rank, no lookup
id2name("2878688", backend = "gbif")        # GBIF usage key -> name + classification
```

Cross the vernacular boundary in either direction, and shape a lineage into a tree:

```r
comm2sci("pedunculate oak")                 # common name -> scientific
sci2comm("Quercus robur")                   # scientific -> common names
class2tree(species)                         # taxonomy as a Newick / ape phylo tree
lowest_common(species)                      # deepest shared rank (the MRCA)
```

For migrating an old checklist and recording exactly what you matched against:

```r
reconcile(old_species_list)                 # how each name maps onto the current backbone
lock <- taxify_lock(result)                 # freeze the resolved backbone + enrichment versions
cite(result)                                # formatted citations for every source used
```

## Trait and status enrichment

Nearly ninety enrichment layers join published trait and status data to your results through
the backbone-resolved accepted name, so synonyms in either dataset land on the same key:

```r
# plants
taxify(plant_names) |>
  add_iucn() |>                  # IUCN Red List
  add_griis("AT") |>             # GRIIS
  add_zanne() |>                 # Zanne et al. woodiness
  add_eive()                     # EIVE indicator values

# fish
taxify(fish_names, backend = "col") |>
  add_fishbase() |>              # FishBase morphology & ecology
  add_fishmorph()                # FISHMORPH functional traits

# one trait, gathered across every source that has it
taxify(plant_names) |>
  add_trait("seed_mass")         # Diaz + GIFT, harmonized to mg
```

Sources span all kingdoms: IUCN, GRIIS, GBIF common names, WCVP, EIVE, Diaz et al., LEDA,
GIFT, FungalTraits, FUNGuild, AlgaeTraits, EltonTraits, AVONET, PanTHERIA, AmphiBIO, FISHMORPH,
FishBase, AnAge, GloNAF, LepTraits, AnimalTraits, and regional plant-trait sets for France
(Baseflor), Britain (Ecoflora), and Germany (FloraWeb), and more. The
[enrichments vignette](https://gillescolling.com/taxify/articles/enrichments.html) lists
the full set with references and licenses, and `list_enrichments()` returns it in R;
`list_traits()` browses the cross-source trait vocabulary that `add_trait()` draws on.

To join your own table, `add_data()` auto-detects the species column, matches it through
the same backbone(s) used in the original call, and left-joins. It accepts data.frames,
CSV, CSV.GZ, XLSX, SQLite, and `.vtr`.

```r
result |> add_data("TRY_traits.csv")
result |> add_data("TRY_traits.csv", cols = c("LeafArea", "SLA", "PlantHeight"))
```

## Check a list before you trust it

`inspect()` returns only the names that look wrong, each labelled with what
stands out and the name to use instead. It catches typos, retired synonyms,
made-up genera, near-duplicate spellings, and the lone animal in a list of
plants, and ranks them by whether they need a decision, a second look, or just
optional cleanup.

```r
inspect(field_names)                  # offline register and list checks
inspect(field_names, backbones = TRUE) # also typos, synonyms, ambiguity
```

For regional field lists, `region` steers a fuzzy correction toward species
that actually occur where you work, so a misspelling resolves to the plant that
grows there even when a one-letter neighbour from another continent sits just as
close in spelling. Pass a region name, a TDWG code, or coordinates.

```r
taxify(field_names, region = "Belgium")
taxify(field_names, coords = c(4.35, 50.85))
```

## Installation

```r
install.packages("taxify")
```

Or the development version from GitHub:

```r
install.packages("pak")
pak::pak("gcol33/taxify")          # vectra is installed automatically
```

## Documentation

- [Getting started](https://gillescolling.com/taxify/articles/quickstart.html)
- [Choosing and combining backends](https://gillescolling.com/taxify/articles/backends.html)
- [Fuzzy matching](https://gillescolling.com/taxify/articles/fuzzy-matching.html)
- [Constraining matches to a region](https://gillescolling.com/taxify/articles/regions.html)
- [Enrichments](https://gillescolling.com/taxify/articles/enrichments.html)
- [Custom data](https://gillescolling.com/taxify/articles/custom-data.html)
- [Inspecting a name list](https://gillescolling.com/taxify/articles/inspecting-names.html)
- [Hybrids and aggregates](https://gillescolling.com/taxify/articles/hybrids-and-aggregates.html)
- [Migrating from taxize, WorldFlora, and related tools](https://gillescolling.com/taxify/articles/migration.html)
- [Large-scale workflows](https://gillescolling.com/taxify/articles/large-scale.html)

## Support

> "Software is like sex: it's better when it's free." — Linus Torvalds

I'm a PhD student who builds R packages in my free time because I believe good tools
should be free and open. I started these projects for my own work and figured others
might find them useful too.

If this package saved you some time, buying me a coffee is a nice way to say thanks.
It helps with my coffee addiction.

[![Buy Me A Coffee](https://img.shields.io/badge/-Buy%20me%20a%20coffee-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/gcol33)

## License

MIT (see the LICENSE file)

## Citation

```bibtex
@software{taxify,
  author = {Colling, Gilles},
  title  = {taxify: Offline Taxonomic Name Matching Against Darwin Core Backbones},
  year   = {2026},
  url    = {https://github.com/gcol33/taxify}
}
```

Cite the backbones and enrichment layers you actually used with `cite(result)`,
which pulls each source's own reference from the manifest.
