# Add fungal functional guild data (FUNGuild)

Joins FUNGuild trophic mode, guild, growth morphology, and confidence
data to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Species-level matches take
priority; genus-level guild assignments are used as fallback for
unmatched species.

## Usage

``` r
add_funguild(x, cols = NULL, verbose = TRUE)
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

The same data.frame with additional columns:

- funguild_trophic_mode:

  Trophic mode (e.g., Pathotroph, Saprotroph, Symbiotroph, or hyphenated
  combinations).

- funguild_guild:

  Functional funguild_guild (e.g., "Ectomycorrhizal", "Plant Pathogen",
  "Wood Saprotroph").

- funguild_growth_form:

  Growth morphology (e.g., "Agaricoid", "Microfungus"). Prefixed to
  avoid collision with FungalTraits.

- funguild_confidence_ranking:

  Confidence of the funguild_guild assignment (Possible, Probable,
  Highly Probable).

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

taxify("Amanita muscaria", backbone = "gbif") |>
  add_funguild()
#> Matching 1 names...
#>         input_name     matched_name    accepted_name    taxon_id accepted_id
#> 1 Amanita muscaria Amanita muscaria Amanita muscaria gbif-ex-013 gbif-ex-013
#>      rank      family   genus  epithet authorship accepted_authorship
#> 1 species Amanitaceae Amanita muscaria  (L.) Lam.           (L.) Lam.
#>   is_synonym taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1      FALSE         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group life_form qualifier
#> 1 gbif:example (2026-06-24)         fungi      fungus    fungus      <NA>
#>   qualifier_position aggregate_fallback hybrid_type funguild_trophic_mode
#> 1               <NA>                 NA        <NA>  example_trophic_mode
#>   funguild_guild      funguild_growth_form funguild_confidence_ranking
#> 1  example_guild example_growth_morphology  example_confidence_ranking
#> Sources: GBIF example, FUNGuild example | cite() for full citations

options(old)
```
