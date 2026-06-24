# Vectorized Latin orthographic normalization

Reduces common Latin spelling alternations to a canonical form so that
e.g. `hirtaeformis` and `hirtiformis` produce the same normalized key.
Applied identically to both query names and backbone names so the keys
line up on either side of the join.

## Usage

``` r
normalize_epithets(names)
```

## Arguments

- names:

  Character vector of cleaned taxonomic names (genus + epithet).

## Value

Character vector of normalized forms.

## Details

Pipeline:

1.  Lowercase.

2.  Strip Latin-1 diacritics and ligatures (e-acute to e, ae-ligature to
    ae, sharp-s to ss, etc.), applied to genus and epithet.

3.  Orthographic alternation on the epithet only: `ae`/`oe` -\> `i`,
    trailing `ii` -\> `i`, `y` -\> `i`, `ph` -\> `f`, `rh` -\> `r`, `th`
    -\> `t`.

Step 2 runs before step 3, so ae-ligature -\> `ae` -\> `i` and
oe-ligature -\> `oe` -\> `i` fold into the same key as the de-ligatured
forms.
