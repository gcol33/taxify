# Choosing and combining backbones

This article shows how taxify decides which backbone resolves each name,
how to name the backbones yourself, how to compare their answers for the
same names, and how to download and pin backbone versions. It ends with
a list of backbone choices for common kinds of name lists. Installation
is covered in [Get
started](https://gillescolling.com/taxify/articles/taxify.md).

1.  **Match** with the default fallback chain, or name the backbones in
    `backbone`.

2.  **Compare** the backbones’ answers with `mode = "wide"` or
    `mode = "agreement"`.

3.  **Check** names a backbone does not cover with
    [`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md)
    and
    [`taxify_register_coverage()`](https://gillescolling.com/taxify/reference/taxify_register_coverage.md).

4.  **Download** and pin versions with
    [`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md),
    and list them with
    [`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md).

``` r

library(taxify)
```

## The default fallback chain

A backbone is a published taxonomic database stored as a file on your
disk. taxify supports 19 backbones of taxa, and two of vegetation units
described in [Matching vegetation
units](https://gillescolling.com/taxify/articles/vegetation-units.md).
[`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md)
reports each one’s scope, version, number of names and whether it is
installed:

``` r

bb <- list_backbones(verbose = FALSE)
bb[, c("name", "scope", "version", "n_names", "installed")]
#>           name                               scope version n_names installed
#> 1          wfo                     Vascular plants 2026.06 1664014      TRUE
#> 2          col                        All kingdoms 2026.09 5432444      TRUE
#> 3        colxr                        All kingdoms 2026.09 8479599      TRUE
#> 4         gbif                        All kingdoms 2023.08 6404001      TRUE
#> 5         itis         US focus, freshwater/marine 2026.09 1000552      TRUE
#> 6         ncbi                            All life 2026.09 2952424      TRUE
#> 7          ott                All life (synthetic) 2026.09 3690217      TRUE
#> 8        worms                      Marine/aquatic 2026.09 1565652      TRUE
#> 9      euromed       European/Mediterranean plants 2026.08  146922      TRUE
#> 10    fungorum                               Fungi 2026.08  315037      TRUE
#> 11   algaebase                               Algae 2026.09  172351      TRUE
#> 12    fishbase                              Fishes 2026.08  102703      TRUE
#> 13 sealifebase             Non-fish marine/aquatic 2026.08  134031      TRUE
#> 14   reptiledb                            Reptiles 2026.07   50043      TRUE
#> 15        lcvp                     Vascular plants 2026.08 1337891      TRUE
#> 16        wcvp                     Vascular plants 2026.06 1448984      TRUE
#> 17         mdd                             Mammals 2026.08   61862      TRUE
#> 18     avilist                               Birds 2026.08   40572      TRUE
#> 19        lpsn      Prokaryotes (Bacteria/Archaea) 2026.08   44885      TRUE
#> 20         evc European vegetation units (syntaxa)       4    7542      TRUE
#> 21       vegcz    Czech vegetation units (syntaxa) 2026.10    2258      TRUE
```

Without a `backbone` argument,
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) uses
every installed backbone of taxa as a fallback chain: each name is
matched against the first backbone, the names left unmatched go to the
second, and so on. The order is fixed by priority. The Catalogue of Life
(COL) and its Extended Release (COL XR) come first, then the backbones
of one group (marine species, plants, fungi, algae, fishes, reptiles,
mammals, birds, prokaryotes), then the broad compilations GBIF, ITIS,
NCBI and OTT. On a new setup the first call installs COL, GBIF and the
Integrated Taxonomic Information System (ITIS); every backbone
downloaded later joins the chain at its place in that order.

The list below mixes a plant, two animals renamed since their
description, a fungus, a fish, a bacterium and a brown alga:

``` r

mixed <- c(
  "Quercus robur", "Panthera leo", "Amanita muscaria", "Salmo trutta",
  "Escherichia coli", "Macropus rufus", "Fucus vesiculosus",
  "Parus caeruleus"
)
res <- taxify(mixed, verbose = FALSE)
res[, c("input_name", "accepted_name", "backbone")]
#>          input_name       accepted_name backbone
#> 1     Quercus robur       Quercus robur    colxr
#> 2      Panthera leo        Panthera leo    colxr
#> 3  Amanita muscaria    Amanita muscaria    colxr
#> 4      Salmo trutta        Salmo trutta    colxr
#> 5  Escherichia coli    Escherichia coli    colxr
#> 6    Macropus rufus    Osphranter rufus    colxr
#> 7 Fucus vesiculosus   Fucus vesiculosus    colxr
#> 8   Parus caeruleus Cyanistes caeruleus    colxr
#> Sources: COLXR 2026.08 | cite() for full citations
```

All 19 backbones are installed on the machine that built this page, so
the chain starts with COL XR. It resolves all eight names, and the other
18 backbones are skipped. The `backbone` column records which backbone
matched each row, and the line under the table names the backbones to
cite for this result: only those that matched a row. *Macropus rufus*
and *Parus caeruleus* are synonyms in COL XR, and their rows carry its
accepted names *Osphranter rufus* and *Cyanistes caeruleus*.

The first backbone that matches a name decides its accepted name. taxify
does not take a vote across backbones: several backbones copy their
treatment from one another, so a majority can follow the oldest
treatment. [Comparing backbones](#comparing-backbones) shows how to see
where they disagree.

`options(taxify.backbone_priority = )` changes the order for a session,
and `options(taxify.default_backbones = )` the set installed on first
use.

## Naming the backbones

A `backbone` vector replaces the default chain with your own. A plant
list resolved against World Flora Online (WFO) first, with COL for the
rest:

``` r

res <- taxify(mixed, backbone = c("wfo", "col"))
#> Matching 8 names against 2 backbones: wfo -> col
#>   [wfo] Matching 8 names...
#>   [col] Matching 6 remaining names...
res[, c("input_name", "accepted_name", "match_type", "backbone")]
#>          input_name       accepted_name   match_type backbone
#> 1     Quercus robur       Quercus robur        exact      wfo
#> 2      Panthera leo        Panthera leo        exact      col
#> 3  Amanita muscaria    Amanita muscaria        exact      col
#> 4      Salmo trutta        Salmo trutta        exact      col
#> 5  Escherichia coli    Escherichia coli        exact      col
#> 6    Macropus rufus    Osphranter rufus        exact      col
#> 7 Fucus vesiculosus                <NA> out_of_scope     <NA>
#> 8   Parus caeruleus Cyanistes caeruleus        exact      col
#> Sources: WFO + COL | cite() for full citations
```

The progress lines show the chain: WFO matched *Quercus robur*, and COL
received six of the seven remaining names. A name present in both
backbones takes the treatment of the one listed first, including its
accepted name, family and synonym resolution. Fuzzy matching runs inside
each backbone before the name moves on, so a misspelt plant name is
compared with WFO’s names before it reaches COL.

*Fucus vesiculosus* was not sent to COL. Its genus is in the genus
register, an index of the genera of every backbone, and the register
records that neither WFO nor COL holds it, so the row has
`match_type = "out_of_scope"`. The register is described in [How names
are
matched](https://gillescolling.com/taxify/articles/fuzzy-matching.md).
Adding AlgaeBase, the backbone for algae, resolves it:

``` r

res <- taxify(mixed, backbone = c("wfo", "algaebase", "col"),
              verbose = FALSE)
res[res$input_name == "Fucus vesiculosus",
    c("input_name", "accepted_name", "match_type", "backbone")]
#>          input_name     accepted_name match_type  backbone
#> 7 Fucus vesiculosus Fucus vesiculosus      exact algaebase
#> Sources: ALGAEBASE 2026.09 | cite() for full citations
```

## Checking names outside a backbone

[`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md)
returns the genus register’s entry for a genus, and
[`taxify_register_coverage()`](https://gillescolling.com/taxify/reference/taxify_register_coverage.md)
lists the backbones that hold it:

``` r

lookup_genus("Fucus")[, c("genus", "kingdom", "family", "life_form")]
#>        genus   kingdom   family  life_form
#> 176828 Fucus Chromista Fucaceae brown alga
taxify_register_coverage("Fucus")
#>   genus    backbone version date_added
#> 1 Fucus       worms 2026.09 2026-09-14
#> 2 Fucus sealifebase 2026.08 2026-08-27
#> 3 Fucus         ott 2026.09 2026-09-14
#> 4 Fucus        ncbi 2026.09 2026-09-14
#> 5 Fucus        itis 2026.09 2026-09-14
#> 6 Fucus        gbif 2023.08 2026-09-22
#> 7 Fucus       colxr 2026.08 2026-09-23
#> 8 Fucus   algaebase 2026.09 2026-09-14
```

*Fucus* is a brown alga, held by eight backbones. The COL release used
here is not one of them, while COL XR, which adds names from further
sources, is. An `out_of_scope` row therefore points to a backbone to add
to the chain, where `match_type = "none"` leaves open whether the name
is misspelt or exists in no backbone.

## Comparing backbones

`mode = "wide"` matches every name against every backbone in `backbone`
and adds one `accepted_<backbone>` column per backbone, plus
`all_agree`:

``` r

names3 <- c("Macropus rufus", "Parus caeruleus", "Quercus robur")
wide <- taxify(names3, backbone = c("col", "gbif", "itis"),
               mode = "wide", verbose = FALSE)
wide[, c("input_name", "accepted_col", "accepted_gbif", "accepted_itis",
         "all_agree")]
#>        input_name        accepted_col       accepted_gbif       accepted_itis
#> 1  Macropus rufus    Osphranter rufus      Macropus rufus    Osphranter rufus
#> 2 Parus caeruleus Cyanistes caeruleus Cyanistes caeruleus Cyanistes caeruleus
#> 3   Quercus robur       Quercus robur       Quercus robur       Quercus robur
#>   all_agree
#> 1     FALSE
#> 2      TRUE
#> 3      TRUE
#> Sources: COL + GBIF + ITIS | cite() for full citations
```

COL and ITIS place the red kangaroo in *Osphranter*; the GBIF Backbone
Taxonomy keeps it in *Macropus*. `accepted_name` is still the pick of
the fallback chain, here COL’s, so the result passes to the `add_*()`
functions unchanged.

`mode = "agreement"` reports the same comparison as counts:

``` r

agr <- taxify(names3, backbone = c("col", "gbif", "itis"),
              mode = "agreement", verbose = FALSE)
agr[, c("input_name", "n_backbones_matched", "n_distinct_accepted",
        "all_agree")]
#>        input_name n_backbones_matched n_distinct_accepted all_agree
#> 1  Macropus rufus                   3                   2     FALSE
#> 2 Parus caeruleus                   3                   1      TRUE
#> 3   Quercus robur                   3                   1      TRUE
#> Sources: COL + GBIF + ITIS | cite() for full citations
```

`all_agree` is `NA` when fewer than two backbones matched a name.

## Columns from one backbone

The output columns are the same for every backbone. Three functions add
the columns that only one backbone carries, and fill them on the rows
that backbone matched; other rows get `NA`:

- [`add_wfo_info()`](https://gillescolling.com/taxify/reference/add_wfo_info.md):
  the place of publication, the parent name and WFO’s higher
  classification.

- [`add_col_info()`](https://gillescolling.com/taxify/reference/add_col_info.md):
  COL’s classification from kingdom to order, nomenclatural code and
  status, and whether the species is extinct, marine, freshwater or
  terrestrial.

- [`add_gbif_info()`](https://gillescolling.com/taxify/reference/add_gbif_info.md):
  the hybrid type, nomenclatural status, basionym author and year, and
  how the name entered the GBIF backbone.

``` r

crab <- taxify(c("Carcinus maenas", "Quercus robur"), backbone = "col",
               verbose = FALSE)
crab <- add_col_info(crab)
crab[, c("input_name", "kingdom", "is_marine", "is_terrestrial")]
#>        input_name  kingdom is_marine is_terrestrial
#> 1 Carcinus maenas Animalia      TRUE          FALSE
#> 2   Quercus robur  Plantae        NA             NA
#> Sources: COL 2026.09 | cite() for full citations
```

COL records the shore crab as marine and not terrestrial. It records
neither for the oak, so both columns are `NA` there.

## How the backbones differ in output

The columns hold the same kind of value for every backbone, with these
differences:

- **Identifiers.** `taxon_id` and `accepted_id` use each backbone’s own
  system: WFO IDs, opaque COL IDs (`4R5YN` for *Quercus robur*), GBIF
  integer keys, ITIS TSNs, NCBI Taxonomy IDs, WoRMS AphiaIDs. An ID is
  meaningful only within its backbone.

- **Authorship.** NCBI and OTT record no authors, so `authorship` is
  `NA` on their rows.

- **Synonyms.** Each source encodes synonyms its own way; all are
  converted when the backbone is built to `is_synonym`, `accepted_name`
  and `accepted_id`. A synonym that points to another synonym is
  followed to the accepted name at build time.

The source, licence and citation of each backbone are listed in [The
backbones and
datasets](https://gillescolling.com/taxify/articles/articles/databases.md).

## Downloading and pinning versions

Each backbone is downloaded once, on first use, into
[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md),
and read from disk after that.
[`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md)
fetches backbones ahead of time, for a server or a session without
network access:

``` r

taxify_download(c("wfo", "worms"))
```

The download goes into a `latest` folder that is replaced when a newer
version is released. taxify compares the local versions with the
published ones once per session, at the first call, and updates `latest`
then; the version never changes during a session. Without network
access, or with `options(taxify.offline = TRUE)` or the environment
variable `TAXIFY_OFFLINE` set, it uses the files on disk.

A version string downloads into a folder of its own that is never
replaced:

``` r

taxify_download("wfo", version = "2024.01")
```

Every row records the backbone version that matched it:

``` r

unique(res$backbone_version)
#> [1] "wfo:2026.06 (2026-09-15)"       "col:2026.09 (2026-09-14)"      
#> [3] "algaebase:2026.09 (2026-09-14)"
```

[`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md)
writes these versions with a checksum of each file to a JSON file, and
`taxify_restore(install = TRUE)` reinstalls the same builds on another
machine, as shown in [Get
started](https://gillescolling.com/taxify/articles/taxify.html#recording-what-was-used).
[`taxify_build()`](https://gillescolling.com/taxify/reference/taxify_build.md)
builds a backbone from its source files instead of downloading it, which
needs the taxifydb package.

## Choosing backbones for a list

Lead with the backbone whose treatment you want for most of the names,
and add broader backbones after it for the rest:

- **Vascular plants**: `"wfo"`, or `c("wfo", "col")` for cultivars,
  names from older floras and recently moved genera that WFO lacks. The
  World Checklist of Vascular Plants (`"wcvp"`) and the Leipzig
  Catalogue of Vascular Plants (`"lcvp"`) are alternatives with their
  own treatment.

- **European vegetation data**: `c("euromed", "wfo")`. Euro+Med
  PlantBase covers the native and introduced vascular plants of Europe,
  the Mediterranean and the Caucasus, and WFO resolves the names outside
  it.

- **Marine and aquatic species**: `"worms"`, the World Register of
  Marine Species, with `"col"` after it for the terrestrial taxa of an
  estuarine list.

- **Fungi**: `c("fungorum", "col")`, Species Fungorum first.

- **Algae**: `c("algaebase", "col")`. AlgaeBase is licensed for
  non-commercial use only (CC BY-NC).

- **Fishes, reptiles, mammals, birds, prokaryotes**: `"fishbase"`,
  `"reptiledb"`, `"mdd"`, `"avilist"` or `"lpsn"`, each followed by
  `"col"`.

- **Sequence-linked lists** (metabarcoding, eDNA): `c("ncbi", "col")`.
  NCBI Taxonomy IDs link to GenBank records, and NCBI covers bacteria,
  archaea and viruses.

- **Phylogenetic work**: `"ott"`, the Open Tree of Life taxonomy, which
  cross-references NCBI, GBIF, WoRMS and other sources.

- **Lists of unknown composition**: the default chain, or
  `c("col", "gbif")`.

## Where next

- [How names are
  matched](https://gillescolling.com/taxify/articles/fuzzy-matching.md):
  the match stages, the fuzzy threshold and the genus register.

- [Matching within a
  region](https://gillescolling.com/taxify/articles/regions.md):
  restricting matches to species present in a region.

- [Matching large
  lists](https://gillescolling.com/taxify/articles/large-scale.md):
  timings and memory for lists of many names.

- [The backbones and
  datasets](https://gillescolling.com/taxify/articles/articles/databases.md):
  the source, size and licence of every backbone.
