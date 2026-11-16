# Parse taxonomic names into their structural parts

Decomposes each name into genus, specific epithet, infraspecific rank
and epithet, authorship, hybrid status, and any open-nomenclature
qualifier, without matching against a backbone. Where
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
cleans a name and then resolves it, `parse_name()` returns the cleaning
step itself (the parts of the name) for callers who need the
decomposition rather than a match (the role
[`rgbif::name_parse()`](https://docs.ropensci.org/rgbif/reference/name_parse.html)
or gnparser fill). The same cleaning pipeline the matcher uses drives
the parse, so a name breaks apart the way it matches.

## Usage

``` r
parse_name(x, code = c("taxon", "syntaxon"))
```

## Arguments

- x:

  Character vector of taxonomic names.

- code:

  Character. The nomenclature the names follow: `"taxon"` (default;
  botanical and zoological names) or `"syntaxon"` (vegetation units
  under the International Code of Phytosociological Nomenclature, the
  names a syntaxon backbone such as `"evc"` matches; see
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)).

## Value

For `code = "taxon"`, a data.frame with one row per input name and
columns:

- input_name:

  The original name as supplied.

- genus:

  The genus (first token), or a single-letter initial for an abbreviated
  genus (`"Q. robur"`). `NA` for an unresolvable hybrid formula.

- specific_epithet:

  The specific epithet, or `NA` for a bare genus.

- infrasp_rank:

  The infraspecific rank marker (`"subsp."`, `"var."`, `"f."`, ...) when
  the name has one, else `NA`.

- infrasp_epithet:

  The infraspecific epithet, else `NA`.

- authorship:

  The authorship the name carries (trailing form, e.g.
  `"(L.) H.Karst."`), or `NA`.

- qualifier:

  Any open-nomenclature / uncertainty qualifier (`"cf."`, `"aff."`,
  `"sp."`, `"agg."`, `"s.l."`, ...), canonicalized, or `NA`.
  Infraspecific rank markers are reported in `infrasp_rank`, not here.

- is_hybrid:

  Logical. Was a hybrid marker detected?

- hybrid_type:

  `"nothogenus"`, `"nothospecies"`, `"formula"`, or `NA`.

- rank:

  `"genus"`, `"species"`, `"infraspecies"`, `"hybrid_formula"`, or `NA`
  for an empty input.

- canonical:

  The cleaned name used for matching (genus plus epithets and any
  infraspecific rank marker in its canonical spelling, qualifiers and
  authorship removed, hybrid sign dropped). `NA` for a hybrid formula,
  which is not a single taxon.

For `code = "syntaxon"`, a data.frame with one row per input name and
columns:

- input_name:

  The original name as supplied.

- code:

  A national or database code written in front of the name
  (`"TDA - Arrhenatherion elatioris"`, `"41BB03 - Tilio-Carpinetum"`),
  or `NA`.

- name:

  The syntaxon name without author or annotations, the form the matcher
  looks up. Where a record names several units, the most specific
  rank-labelled one (`"all. X, ord. Y"`), else the first.

- authorship:

  The author citation (`"(Oberd. 1957) Passarge 1964"`), or `NA`.

- rank:

  The rank the name's suffix denotes: `"class"` (-etea), `"order"`
  (-etalia), `"alliance"` (-ion), `"suballiance"` (-enion),
  `"association"` (-etum), `"subassociation"` (a trailing -etosum),
  `"subclass"`, `"suborder"`, or `NA`.

- qualifier:

  `"?"` for a doubtful assignment, `"cf."`, `"s.l."`, `"s.str."`, or
  `NA`.

- name_status:

  Nomenclatural annotations after the citation (`"nom. inval. (5a)"`,
  `"(syntax.syn.)"`, `"(Regionalverband)"`), or `NA`.

## See also

[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) to
match a name; `parse_name()` exposes the same internal cleaning pipeline
the matcher runs.

Other Match and inspect names:
[`cite()`](https://gillescolling.com/taxify/reference/cite.md),
[`comm2sci()`](https://gillescolling.com/taxify/reference/comm2sci.md),
[`id2name()`](https://gillescolling.com/taxify/reference/id2name.md),
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md),
[`reconcile()`](https://gillescolling.com/taxify/reference/reconcile.md),
[`sci2comm()`](https://gillescolling.com/taxify/reference/sci2comm.md)

## Examples

``` r
parse_name(c("Quercus robur L.",
             "Poa annua var. annua",
             "Q. robur",
             "Pinus cf. sylvestris",
             "Salix alba x Salix fragilis"))
#>                    input_name   genus specific_epithet infrasp_rank
#> 1            Quercus robur L. Quercus            robur         <NA>
#> 2        Poa annua var. annua     Poa            annua         var.
#> 3                    Q. robur      Q.            robur         <NA>
#> 4        Pinus cf. sylvestris   Pinus       sylvestris         <NA>
#> 5 Salix alba x Salix fragilis    <NA>             <NA>         <NA>
#>   infrasp_epithet authorship qualifier is_hybrid hybrid_type           rank
#> 1            <NA>         L.      <NA>     FALSE        <NA>        species
#> 2           annua       <NA>      <NA>     FALSE        <NA>   infraspecies
#> 3            <NA>       <NA>      <NA>     FALSE        <NA>        species
#> 4            <NA>       <NA>       cf.     FALSE        <NA>        species
#> 5            <NA>       <NA>      <NA>      TRUE     formula hybrid_formula
#>              canonical
#> 1        Quercus robur
#> 2 Poa annua var. annua
#> 3             Q. robur
#> 4     Pinus sylvestris
#> 5                 <NA>

parse_name(c("Caricenion gracilis (Neuhausl 1959) Oberd. et al. 1967",
             "TDA - Arrhenatherion elatioris",
             "Conioselinion tatarici Golub et al. 2003 nom. inval. (5a)"),
           code = "syntaxon")
#>                                                  input_name code
#> 1    Caricenion gracilis (Neuhausl 1959) Oberd. et al. 1967 <NA>
#> 2                            TDA - Arrhenatherion elatioris  TDA
#> 3 Conioselinion tatarici Golub et al. 2003 nom. inval. (5a) <NA>
#>                       name                         authorship        rank
#> 1      Caricenion gracilis (Neuhausl 1959) Oberd. et al. 1967 suballiance
#> 2 Arrhenatherion elatioris                               <NA>    alliance
#> 3   Conioselinion tatarici                  Golub et al. 2003    alliance
#>   qualifier      name_status
#> 1      <NA>             <NA>
#> 2      <NA>             <NA>
#> 3      <NA> nom. inval. (5a)
```
