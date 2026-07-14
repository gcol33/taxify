# Add United States freshwater fish traits (FishTraits)

Joins ecological and life-history traits of United States freshwater
fishes from FishTraits (Frimpong & Angermeier 2009) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_fishtraits(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) the curated set, `"all"`
  every column the source carries, or a character vector of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns. The default set:

- ft_common_name:

  Common name.

- ft_native:

  Whether native to the contiguous United States.

- ft_max_length_cm:

  Maximum total length (cm).

- ft_longevity_yr:

  Maximum reported age (years).

- ft_maturity_age_yr:

  Age at maturity (years).

- ft_fecundity_max:

  Maximum fecundity.

- ft_repro_guild:

  Reproductive guild.

- ft_min_temp_c:

  Lower temperature tolerance (deg C).

- ft_max_temp_c:

  Upper temperature tolerance (deg C).

- ft_extinct:

  Whether recorded as extinct.

`cols = "all"` also attaches the ten diet-category flags, salinity
tolerance, flow preferences, migratory strategy, listing status, and the
ITIS TSN.

## Details

Source: FishTraits v14.3 (USGS ScienceBase), a public-domain U.S.
Government work. North American freshwater fishes.

## References

Frimpong EA, Angermeier PL (2009) FishTraits: a database of ecological
and life-history traits of freshwater fishes of the United States.
Fisheries 34:487-495.

## Examples

``` r
if (FALSE) { # \dontrun{
# Downloads the enrichment on first use.
taxify("Micropterus salmoides", backend = "gbif") |>
  add_fishtraits()
} # }
```
