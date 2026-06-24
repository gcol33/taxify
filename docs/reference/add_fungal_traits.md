# Add fungal lifestyle and trait data (FungalTraits)

Joins FungalTraits (Polme et al. 2020) genus-level trait data to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `genus`. Unlike other enrichments that join on
species-level `accepted_name`, FungalTraits is a genus-level database
and joins on the `genus` column already present in taxify output.

## Usage

``` r
add_fungal_traits(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- primary_lifestyle:

  Primary ecological role (e.g., saprotroph, mycorrhizal, pathogen,
  endophyte, lichenized, parasite).

- secondary_lifestyle:

  Secondary ecological role, if any.

- growth_form:

  Morphological growth form (e.g., agaricoid, corticioid, polyporoid,
  yeast).

- fruitbody_type:

  Fruiting body morphology (e.g., gasteroid, pileate, resupinate).

- decay_substrate:

  Substrate type for saprotrophic genera (e.g., wood, litter, dung,
  soil).

- plant_pathogenic_capacity:

  Capacity to cause plant disease (e.g., high, medium, low, none).

- animal_biotrophic_capacity:

  Capacity for animal biotrophy.

- endophytic_interaction_capability:

  Capacity for endophytic interactions with plants.

- ectomycorrhiza_exploration_type:

  Exploration type for ectomycorrhizal genera (e.g., contact, short,
  medium, long).

## Details

Source: FungalTraits (Polme et al. 2020, Fungal Diversity, CC BY 4.0).
Coverage: ~10k fungal genera. Genus-level only (not species-level).

## References

Polme S et al. (2020) FungalTraits: a user-friendly traits database of
fungi and fungus-like stramenopiles. Fungal Diversity 105:1-16.
doi:10.1007/s13225-020-00466-2

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Amanita muscaria", backend = "gbif") |>
  add_fungal_traits()

options(old)
```
