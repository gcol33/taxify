# Parse taxonomic names into their structural parts

Decomposes each name into genus, specific epithet, infraspecific rank
and epithet, authorship, hybrid status, and any open-nomenclature
qualifier, without matching against a backbone. Where
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
cleans a name and then resolves it, `parse_name()` returns the cleaning
step itself – the parts of the name – for callers who need the
decomposition rather than a match (the role
[`rgbif::name_parse()`](https://docs.ropensci.org/rgbif/reference/name_parse.html)
or gnparser fill). The same cleaning pipeline the matcher uses drives
the parse, so a name breaks apart the way it matches.

## Usage

``` r
parse_name(x)
```

## Arguments

- x:

  Character vector of taxonomic names.

## Value

A data.frame with one row per input name and columns:

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

  The cleaned name used for matching (genus plus epithets, qualifiers
  and authorship removed, hybrid sign dropped). `NA` for a hybrid
  formula, which is not a single taxon.

## See also

[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) to
match a name; `parse_name()` exposes the same internal cleaning pipeline
the matcher runs.

## Examples

``` r
parse_name(c("Quercus robur L.",
             "Poa annua var. annua",
             "Q. robur",
             "Pinus cf. sylvestris",
             "Salix alba x Salix fragilis"))
```
