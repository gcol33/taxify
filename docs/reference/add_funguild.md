# Add fungal functional guild data (FUNGuild)

Joins FUNGuild trophic mode, guild, growth morphology, and confidence
data to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Species-level matches take
priority; genus-level guild assignments are used as fallback for
unmatched species.

## Usage

``` r
add_funguild(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- trophic_mode:

  Trophic mode (e.g., Pathotroph, Saprotroph, Symbiotroph, or hyphenated
  combinations).

- guild:

  Functional guild (e.g., "Ectomycorrhizal", "Plant Pathogen", "Wood
  Saprotroph").

- funguild_growth_form:

  Growth morphology (e.g., "Agaricoid", "Microfungus"). Prefixed to
  avoid collision with FungalTraits.

- confidence_ranking:

  Confidence of the guild assignment (Possible, Probable, Highly
  Probable).

## Details

Source: FUNGuild (Nguyen et al. 2016, CC BY 4.0). Coverage: ~13k taxa.
Fungi only.

The enrichment first attempts species-level matching. For species
without a direct match, it falls back to genus-level guild assignments
from FUNGuild's genus-rank entries.

## References

Nguyen NH et al. (2016) FUNGuild: An open annotation tool for parsing
fungal community datasets by ecological guild. Fungal Ecology
20:241-248.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Amanita muscaria", backend = "gbif") |>
  add_funguild()

options(old)
```
