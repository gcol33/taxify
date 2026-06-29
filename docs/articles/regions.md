# Constraining matches to a geographic region

## The problem

Fuzzy matching corrects a typo by finding the nearest real name. Most of
the time the nearest name is the one the recorder meant, but two species
can sit a single edit apart while living on different continents. A
recorder working in Belgium who writes a slightly misspelled name meant
a Belgian plant, not its one-letter neighbour from New Zealand. The
string distance alone cannot tell the two apart; the geography can.

[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) takes
a `region` argument for exactly this. When you set it,
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
prefers the fuzzy candidates that actually occur where you work and sets
the others aside. It never touches an exact match, so declaring a region
only ever changes which spelling correction wins, never a name that was
already right.

``` r

library(taxify)

# a small regional list, with a couple of misspellings to correct
field_names <- c(
  "Gentiana acaulis", "Primula veris", "Pulsatilla vulgaris",
  "Gentiana acaulary", "Primula elatour"
)
```

## How the constraint works

The filter rests on WCVP, the World Checklist of Vascular Plants, which
records where each accepted species occurs by TDWG botanical region.
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
resolves your `region` input to TDWG Level 3 codes, looks the candidate
fuzzy names up in WCVP, and drops an out-of-region candidate when a
better one survives. Three rules keep it conservative:

- It filters fuzzy candidates only. It trusts an exact or case-folded
  match as given.
- It never drops a candidate with no WCVP range data. Absence of data is
  not absence from the region, so a non-plant match (no WCVP record)
  passes through untouched.
- It keeps every candidate for a name when all of them are out of
  region. The filter refines a match; it does not refuse one.

So the constraint is a soft preference. It breaks ties toward local
species and otherwise stays out of the way.

## By region name

The clearest input is a name. The bundled WGSRPD crosswalk accepts
botanical regions at three levels, so a country, a sub-continental
region, or a continent all work, case- and accent-insensitively.

``` r

taxify("Gentiana acaulis", region = "Europe")
```

    #>         input_name    accepted_name       family match_type fuzzy_dist backend
    #> 1 Gentiana acaulis Gentiana acaulis Gentianaceae      exact         NA     WFO

The exact match comes back unchanged, since the region never touches
one. The constraint earns its keep on the fuzzy names in the same call:
when a typo has two corrections a single edit apart and only one of them
grows in Europe, the European one wins the tie. A name with no such
conflict resolves exactly as it would without a region.

`"Europe"` is a Level 1 region and expands to every European code;
`"Middle Europe"` is a Level 2 region; `"Belgium"` is a single Level 3
country. You can pass several, and they union:

``` r

taxify(field_names, region = c("Belgium", "Netherlands", "Germany"))
```

A three-letter token is read as a TDWG code directly, so
`region = "BGM"` (Belgium) and `region = "Belgium"` reach the same
place. An unrecognised region is dropped with a warning rather than
failing the call, and a code that matches no WCVP record simply makes
the filter a no-op, so a typo in the region degrades gracefully instead
of producing wrong matches.

## By coordinates

When the data carry coordinates, hand them over directly. A point is
mapped to its botanical region by point-in-polygon against the WGSRPD
Level 3 boundaries, and the resulting codes are used the same way a
region name would be.

``` r

# Brussels: c(longitude, latitude)
taxify(field_names, coords = c(4.35, 50.85))
```

The order is `c(lon, lat)`. A single point, a two-column matrix or
data.frame of points, or a point-geometry spatial object all work; an
`sf` object or a terra `SpatVector` is reprojected to longitude/latitude
on the way in. Points and a `region` name can be combined, and their
regions union.

``` r

occ <- data.frame(
  lon = c(4.35, 5.12, 4.40),
  lat = c(50.85, 51.21, 50.50)
)
taxify(field_names, coords = occ)
```

The boundary file downloads once and stays cached. By default the lookup
runs a native ray-casting test, so no spatial package is required. With
terra or sf installed taxify uses that instead, which is faster on large
point sets, and `options(taxify.pip_engine = "terra" | "sf" | "native")`
forces the choice.

## Native, introduced, or present

By default any WCVP record counts as in-region, native or introduced
alike. The `range` argument narrows that.

``` r

# only count regions where WCVP lists the species as native
taxify(field_names, region = "Europe", range = "native")

# only introduced occurrences
taxify(field_names, region = "Europe", range = "introduced")
```

`range = "present"` is the default and the most permissive. `"native"`
is stricter and suits work that should ignore naturalised populations; a
species present in your region only as an introduction will not satisfy
it, and its out-of-region native correction can lose the tie.
`"introduced"` is the mirror image, for invasion work that wants the
alien records specifically. The argument is ignored when no region is
set.

## Looking up regions

[`taxify_regions()`](https://gillescolling.com/taxify/reference/taxify_regions.md)
returns the crosswalk so you can find the right code or confirm a name
resolves. With no argument it lists every Level 3 region; with a search
term it filters, matching the code and the Level 1, 2, and 3 names.

``` r

taxify_regions("Belgium")
```

    #>   code    name  level2_name level1_name
    #> 1  BGM Belgium Middle Europe      EUROPE

``` r

# every code Europe expands to
nrow(taxify_regions("Europe"))
#> [1] 41

# browse the full table
head(taxify_regions())
```

The same crosswalk powers
[`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md),
so the codes here are the ones that appear in native-range enrichment
output.

## What it covers, and what it does not

WCVP is vascular plants. For names outside that scope there is no range
data, so the filter leaves them alone by design, which is why a mixed
plant-and-animal list can carry a region without harming the animal
matches. The constraint also acts on fuzzy candidates only, so it
changes nothing for a list that matches exactly throughout. It is most
useful on regional field lists with the usual crop of misspellings,
where the right correction and a plausible wrong one are a single edit
apart.

The related check in
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
looks at the other end of the pipeline. Rather than steering a
correction, it takes matched names and flags the ones WCVP does not
record in your region, surfacing a real but geographically out-of-place
species for review. The two share the `region`, `coords`, and `range`
arguments. See the [name inspection
vignette](https://gillescolling.com/taxify/articles/inspecting-names.html)
for that pass.

## Where to go next

- [Inspecting a name
  list](https://gillescolling.com/taxify/articles/inspecting-names.html)
  for the geographic outlier check that uses the same region inputs.

- [Fuzzy
  matching](https://gillescolling.com/taxify/articles/fuzzy-matching.html)
  for the candidate generation the region filter refines.

- [Enrichments](https://gillescolling.com/taxify/articles/enrichments.html)
  for
  [`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md),
  which attaches native range on the same TDWG codes. \`\`\`
