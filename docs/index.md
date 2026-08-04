# taxify

*offline taxonomic name resolution*

[![CRAN
status](https://www.r-pkg.org/badges/version/taxify)](https://CRAN.R-project.org/package=taxify)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/grand-total/taxify)](https://cran.r-project.org/package=taxify)
[![Monthly
downloads](https://cranlogs.r-pkg.org/badges/taxify)](https://cran.r-project.org/package=taxify)
[![R-CMD-check](https://github.com/gcol33/taxify/actions/workflows/R-CMD-check.yml/badge.svg)](https://github.com/gcol33/taxify/actions/workflows/R-CMD-check.yml)
[![Codecov test
coverage](https://codecov.io/gh/gcol33/taxify/graph/badge.svg)](https://app.codecov.io/gh/gcol33/taxify)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

Hand `taxify` a column of messy species names. It cleans them, matches
them against a Darwin Core backbone on your disk, resolves synonyms to
accepted names, and returns one standardized data.frame. Every step runs
locally against a versioned snapshot, so there are no API calls, no rate
limits, and the same input gives the same output on any machine. A list
of thousands resolves in seconds, with the matching engine written in C
through the [vectra](https://github.com/gcol33/vectra) columnar engine.

## Installation

``` r

install.packages("taxify")
```

Or the development version from GitHub:

``` r

install.packages("pak")
pak::pak("gcol33/taxify")          # vectra is installed automatically
```

## Usage

``` r

library(taxify)

# the first call installs the default backbone set (COL + GBIF + ITIS, ~4 GB)
taxify(c(
  "Quercus robur",
  "Pinus abies",        # synonym, resolved to Picea abies
  "Quercus robus",      # typo, fuzzy-corrected to Q. robur
  "Taraxacum officinale"
))
```

You get one row per input name on a fixed schema: the matched and
accepted names with their IDs and authorship, rank, family, genus,
epithet, synonym / hybrid / ambiguity flags, the match type, the fuzzy
distance, a coarse kingdom and taxon-group label, and the backbone and
version used. [`summary()`](https://rdrr.io/r/base/summary.html) prints
how the batch resolved.

``` r

result <- taxify(c("Quercus robur", "Pinus abies", "Quercus robus", "Taraxacum officinale"))
summary(result)
#> -- taxify results ----------------------------------------------------
#>   backbone: COL  |  4 names submitted
#>
#>   matched         4  (exact: 2, case-insensitive: 0, fuzzy: 2, abbrev: 0)
#>   --------------------------------------------------------------
#>   taxon groups: vascular plant: 4
```

## Backbones

taxify ships 18 backbones as compressed `.vtr` files, pre-built by the
companion [taxifydb](https://github.com/gcol33/taxifydb) package and
downloaded once. Pass several and they form a fallback chain, where a
name unmatched by the first cascades to the next.

``` r

# COL first (all kingdoms), then GBIF for whatever COL leaves open
taxify(c("Quercus robur", "Panthera leo", "Amanita muscaria"), backbone = c("col", "gbif"))
```

Pass no `backbone` and every installed backbone forms one chain in a
fixed priority order: COL, then the domain authorities (marine, plants,
fungi, algae, fishes, reptiles, mammals, birds, prokaryotes), then the
broad aggregators GBIF, ITIS, NCBI, and OTT.

| Backbone | Scope | Names | Download |
|----|----|----|----|
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
| [Mammal Diversity Database](https://www.mammaldiversity.org/) | Mammals | 62k | 11 MB |
| [AviList](https://www.avilist.org/) | Birds | 41k | 8 MB |
| [LPSN](https://lpsn.dsmz.de) | Prokaryotes (Bacteria/Archaea) | 45k | 12 MB |

[`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md)
returns this table live, with the installed and version status of each.
[`taxify_databases()`](https://gillescolling.com/taxify/reference/taxify_databases.md)
adds the enrichment layers alongside it.

## Matching

Input names are normalized first, so the fuzzy pass runs only on names
that genuinely differ from the backbone:

``` r

"Quercus robur L."            ->  "Quercus robur"        # authorship stripped
"Pinus cf. sylvestris"        ->  "Pinus sylvestris"     # qualifier removed
"Nothofagus x alpina"         ->  "Nothofagus × alpina"  # hybrid sign normalized (x -> ×)
"Betula pendula (Roth) Doll"  ->  "Betula pendula"       # parenthesized author stripped
```

Fuzzy matching takes Damerau-Levenshtein, Levenshtein, or Jaro-Winkler
with a distance threshold, and runs genus-blocked, so a typo competes
against names in its own genus.

taxify and [WorldFlora](https://cran.r-project.org/package=WorldFlora)
both read the same WFO snapshot, which isolates the two matching
implementations on identical data. The corpus is 1,000 accepted
binomials drawn from the backbone with a fixed seed; the fuzzy corpus is
those names with one substituted character in each epithet, so every one
has to resolve by distance.

|                          | taxify | WorldFlora            |
|--------------------------|--------|-----------------------|
| Backbone load            | 4.9 s  | 20.1 s (CSV into RAM) |
| Exact match, 1,000 names | 2.2 s  | 17.1 s                |
| Fuzzy match, 1,000 names | 18.8 s | 4,192 s (70 min)      |
| Fuzzy match, 5,000 names | 26.6 s | not measured          |
| Peak R heap, fuzzy 1,000 | 678 MB | 4.0 GB                |

`scripts/benchmark-worldflora.R` produces these numbers and
`scripts/benchmark-worldflora-results.json` records the run, including
package versions and the backbone snapshot. Both packages were measured
back to back on one machine (Windows 11, R 4.6.0, taxify 0.3.21,
WorldFlora 1.14.5) that was carrying other work at the time, so the
ratios are the reliable figures.

## Beyond matching

[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
resolves a name to its accepted name. The same local backbone file
answers the related lookups, with nothing else to download:

``` r

synonyms("Picea abies")                     # every synonym of an accepted name
children("Quercus")                         # accepted species in a genus
downstream("Fagaceae", downto = "genus")    # all genera under a family
upstream("Quercus robur", to = "family")    # the family a species sits in
class2tree(species)                         # a lineage as a Newick / ape phylo tree
lowest_common(species)                      # the deepest shared rank (the MRCA)
parse_name("Quercus robur (L.) H.Karst.")   # genus / epithet / author, no lookup
id2name("2878688", backbone = "gbif")       # GBIF usage key -> name + classification
comm2sci("pedunculate oak")                 # common name -> scientific
sci2comm("Quercus robur")                   # scientific -> common names
reconcile(old_species_list)                 # how a checklist maps onto the backbone
taxify_lock(result)                         # freeze the backbone + enrichment versions
cite(result)                                # citations for every source used
```

## Traits and status

100 enrichment layers join published trait and status data to a result
through the backbone-resolved accepted name, so synonyms in either
dataset land on the same key.

``` r

taxify(plant_names) |>
  add_iucn() |>                  # IUCN Red List
  add_griis("AT") |>             # GRIIS invasive status
  add_zanne() |>                 # Zanne et al. woodiness
  add_eive()                     # EIVE indicator values

taxify(fish_names) |>
  add_fishbase() |>              # FishBase morphology and ecology
  add_fishmorph()                # FISHMORPH functional traits

taxify(plant_names) |>
  add_trait("seed_mass")         # every source that carries it, harmonized to mg
```

Sources span all kingdoms: IUCN, GRIIS, GBIF common names, WCVP, EIVE,
Diaz et al., LEDA, GIFT, FungalTraits, FUNGuild, AlgaeTraits,
EltonTraits, AVONET, PanTHERIA, AmphiBIO, FISHMORPH, FishBase, AnAge,
GloNAF, LepTraits, AnimalTraits, and regional plant-trait sets for
France (Baseflor), Britain (Ecoflora), and Germany (FloraWeb), among
others.
[`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md)
returns the full set in R,
[`list_traits()`](https://gillescolling.com/taxify/reference/list_traits.md)
browses the cross-source trait vocabulary behind
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md),
and the [enrichments
vignette](https://gillescolling.com/taxify/articles/enrichments.html)
lists every source with its reference and license.

[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
joins your own table the same way, auto-detecting the species column and
matching it through the backbones used in the original call. It reads
data.frames, CSV, CSV.GZ, XLSX, SQLite, and `.vtr`.

``` r

result |> add_data("TRY_traits.csv")
result |> add_data("TRY_traits.csv", cols = c("LeafArea", "SLA", "PlantHeight"))
```

## Checking a list

[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
returns only the names that look wrong, each labelled with what stands
out and the name to use instead: typos, retired synonyms, made-up
genera, near-duplicate spellings, and the lone animal in a list of
plants. Each label is ranked by whether it needs a decision, a second
look, or optional cleanup.

``` r

inspect(field_names)                   # offline register and list checks
inspect(field_names, backbones = TRUE) # also typos, synonyms, ambiguity
```

For a regional field list, `region` steers fuzzy correction toward
species that occur where you work, so a misspelling resolves to the
plant that grows there. Pass a region name, a TDWG code, or coordinates.

``` r

taxify(field_names, region = "Belgium")
taxify(field_names, coords = c(4.35, 50.85))
```

## Documentation

- [Getting
  started](https://gillescolling.com/taxify/articles/quickstart.html)
- [Choosing and combining
  backbones](https://gillescolling.com/taxify/articles/backbones.html)
- [Fuzzy
  matching](https://gillescolling.com/taxify/articles/fuzzy-matching.html)
- [Constraining matches to a
  region](https://gillescolling.com/taxify/articles/regions.html)
- [Enrichments](https://gillescolling.com/taxify/articles/enrichments.html)
- [Custom
  data](https://gillescolling.com/taxify/articles/custom-data.html)
- [Inspecting a name
  list](https://gillescolling.com/taxify/articles/inspecting-names.html)
- [Hybrids and
  aggregates](https://gillescolling.com/taxify/articles/hybrids-and-aggregates.html)
- [Migrating from taxize, WorldFlora, and related
  tools](https://gillescolling.com/taxify/articles/migration.html)
- [Large-scale
  workflows](https://gillescolling.com/taxify/articles/large-scale.html)

Bug reports and questions go to the [issue
tracker](https://github.com/gcol33/taxify/issues).

## Support

> “Software is like sex: it’s better when it’s free.” — Linus Torvalds

I’m a PhD student who builds R packages in my free time because I
believe good tools should be free and open. I started these projects for
my own work and figured others might find them useful too.

If this package saved you some time, buying me a coffee is a nice way to
say thanks. It helps with my coffee addiction.

[![Buy Me A
Coffee](https://img.shields.io/badge/-Buy%20me%20a%20coffee-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/gcol33)

## License

MIT (see the LICENSE file)

## Citation

``` bibtex
@software{taxify,
  author = {Colling, Gilles},
  title  = {taxify: Offline Taxonomic Name Matching Against Darwin Core Backbones},
  year   = {2026},
  url    = {https://github.com/gcol33/taxify}
}
```

Cite the backbones and enrichment layers you actually used with
`cite(result)`, which pulls each source’s own reference from the
manifest.
