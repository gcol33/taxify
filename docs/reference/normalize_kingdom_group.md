# Normalize a kingdom string to the coarse kingdom-group vocabulary

Case-insensitive; also folds the NCBI clade and OTT kingdom names
(Pseudomonadati, Archaeplastida, ...). Unrecognised, empty, or
explicitly unknown values return `NA`, so an unknown kingdom is never a
reason to reject a row. The coarse vocabulary is `animalia`, `plantae`,
`fungi`, `bacteria`, `archaea`, `chromista`, `protozoa` and `viruses`;
taxifydb uses it to check enrichment name expansion against a source's
declared kingdoms.

## Usage

``` r
normalize_kingdom_group(x)
```

## Arguments

- x:

  Character vector.

## Value

Character vector of coarse kingdom groups (or `NA`).

## Examples

``` r
normalize_kingdom_group(c("Animalia", "Viridiplantae", "plants", "unknown"))
```
