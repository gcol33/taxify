# taxify

> Small exact engines for scientific computing in R.

*the species names never quite match*

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

# match against WFO (downloads the backbone on first use, ~120 MB)
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

## Ten backbones, one call

`taxify` ships ten backbones as compressed `.vtr` files, downloaded once and matched
locally. Pass several and they form a fallback chain: a name unmatched by the first
backbone cascades to the next.

```r
# WFO first (plants), then GBIF for whatever WFO doesn't cover
taxify(
  c("Quercus robur", "Panthera leo", "Amanita muscaria"),
  backend = c("wfo", "gbif")
)
```

| Backend | Scope | Approx. names |
|---------|-------|---------------|
| [WFO](https://www.worldfloraonline.org/) | Vascular plants | ~400k |
| [COL](https://www.catalogueoflife.org/) | All kingdoms | ~4.5M |
| [GBIF](https://www.gbif.org/) | All kingdoms | ~10M |
| [ITIS](https://www.itis.gov/) | US focus, freshwater/marine | ~900k |
| [NCBI Taxonomy](https://www.ncbi.nlm.nih.gov/taxonomy) | All life | ~2.5M |
| [Open Tree of Life](https://opentreeoflife.github.io/) | All life (synthetic) | ~4M |
| [WoRMS](https://www.marinespecies.org/) | Marine/aquatic | ~600k |
| [Euro+Med](https://europlusmed.org/) | European/Mediterranean plants | ~132k |
| [Species Fungorum](https://www.speciesfungorum.org/) | Fungi | ~329k |
| [AlgaeBase](https://www.algaebase.org/) | Algae | ~172k |

## Names are cleaned before matching

Input names are normalized first, so the fuzzy pass only runs on names that genuinely
differ from the backbone rather than on names that just carry extra authorship or
qualifiers:

```r
"Quercus robur L."            ->  "Quercus robur"      # authorship stripped
"Pinus cf. sylvestris"        ->  "Pinus sylvestris"   # qualifier removed
"Nothofagus x alpina"         ->  "Nothofagus alpina"  # hybrid marker normalized
"Betula pendula (Roth) Doll"  ->  "Betula pendula"     # parenthesized author stripped
```

Fuzzy matching is configurable (Damerau-Levenshtein, Levenshtein, or Jaro-Winkler, with a
distance threshold), and runs genus-blocked so a typo only competes against names in the
same genus.

On the same WFO backbone and the same 5,000 plant names (Windows, R 4.5.2), matching
against the local snapshot in C avoids the per-name cost of the CSV-into-RAM approach:

| | taxify | WorldFlora |
|---|---|---|
| Exact match (1,000 names) | 0.1 s | 1.3 s |
| Fuzzy match (1,000 names) | 1.0 s | 1,862 s (31 min) |
| Fuzzy match (5,000 names) | 1.1 s | ~83 min (extrapolated) |
| Backbone load | ~3 s (first call) | 33 s (CSV into RAM) |

## What you get back

`taxify()` returns one row per input name with a fixed 16-column schema: the matched and
accepted names, IDs, rank, family, genus, epithet, authorship, synonym and hybrid flags,
the match type (`exact`, `exact_ci`, `fuzzy`, or `none`), the fuzzy distance, the backend,
and the backbone version used. `summary()` prints a compact digest of how the batch resolved.

```r
result <- taxify(c("Quercus robur", "Pinus abies", "Quercus robus", "Taraxacum officinale"))
summary(result)
#> -- taxify results ----------------------------------------------------
#>   backend: WFO  |  4 names submitted
#>
#>   matched         4  (exact: 2, case-insensitive: 0, fuzzy: 2)
#>   unmatched       0
```

## Trait and status enrichment

Twenty-two enrichment layers join published trait and status data to your results through
the backbone-resolved accepted name, so synonyms in either dataset land on the same key:

```r
# plants
taxify(plant_names) |>
  add_conservation_status() |>   # IUCN Red List
  add_invasive_status("AT") |>   # GRIIS
  add_woodiness() |>             # Zanne et al.
  add_eive()                     # EIVE indicator values

# fish
taxify(fish_names, backend = "col") |>
  add_fishbase() |>              # FishBase morphology & ecology
  add_fish_traits()              # FISHMORPH functional traits
```

Sources span all kingdoms: IUCN, GRIIS, GBIF common names, WCVP, EIVE, Diaz et al., LEDA,
FungalTraits, FUNGuild, AlgaeTraits, EltonTraits, AVONET, PanTHERIA, AmphiBIO, FISHMORPH,
FishBase, AnAge, GloNAF, LepTraits, AnimalTraits, and more. The
[enrichments vignette](https://gillescolling.com/taxify/articles/enrichments.html) lists
the full set with references and licenses.

To join your own table, `add_data()` auto-detects the species column, matches it through
the same backbone(s) used in the original call, and left-joins. It accepts data.frames,
CSV, CSV.GZ, XLSX, SQLite, and `.vtr`.

```r
result |> add_data("TRY_traits.csv")
result |> add_data("TRY_traits.csv", cols = c("LeafArea", "SLA", "PlantHeight"))
```

## Installation

```r
install.packages("pak")
pak::pak("gcol33/taxify")          # vectra is installed automatically
```

## Documentation

- [Getting started](https://gillescolling.com/taxify/articles/quickstart.html)
- [Choosing and combining backends](https://gillescolling.com/taxify/articles/backends.html)
- [Fuzzy matching](https://gillescolling.com/taxify/articles/fuzzy-matching.html)
- [Enrichments](https://gillescolling.com/taxify/articles/enrichments.html)
- [Custom data](https://gillescolling.com/taxify/articles/custom-data.html)
- [Hybrid names](https://gillescolling.com/taxify/articles/hybrid-names.html)
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

MIT (see the LICENSE.md file)
