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

## See also

Other Low-level building blocks:
[`basionym_placement()`](https://gillescolling.com/taxify/reference/basionym_placement.md),
[`candidate_order()`](https://gillescolling.com/taxify/reference/candidate_order.md),
[`embed_accepted()`](https://gillescolling.com/taxify/reference/embed_accepted.md),
[`enrichment_authorship_col()`](https://gillescolling.com/taxify/reference/enrichment_authorship_col.md),
[`is_aggregate_name()`](https://gillescolling.com/taxify/reference/is_aggregate_name.md),
[`normalize_aggregate_name()`](https://gillescolling.com/taxify/reference/normalize_aggregate_name.md),
[`precompute_keys()`](https://gillescolling.com/taxify/reference/precompute_keys.md),
[`score_candidates()`](https://gillescolling.com/taxify/reference/score_candidates.md)

## Examples

``` r
taxify:::normalize_epithets(c("Pinus sylvestris", "Pinus silvestris", NA))
#> [1] "pinus silvestris" "pinus silvestris" NA                
```
