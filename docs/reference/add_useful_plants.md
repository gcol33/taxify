# Add human-use categories (World Checklist of Useful Plant Species)

Joins plant human-use categories to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Each of the ten Level-1 use
categories is a 0/1 flag, plus a crop-wild-relative flag.

## Usage

``` r
add_useful_plants(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- useful_animal_food:

  Animal food (0/1).

- useful_environmental_uses:

  Environmental uses (0/1).

- useful_fuels:

  Fuels (0/1).

- useful_gene_sources:

  Gene sources (0/1).

- useful_human_food:

  Human food (0/1).

- useful_invertebrate_food:

  Invertebrate food (0/1).

- useful_materials:

  Materials (0/1).

- useful_medicines:

  Medicines (0/1).

- useful_poisons:

  Poisons (0/1).

- useful_social_uses:

  Social uses (0/1).

- useful_crop_wild_relative:

  Crop wild relative (0/1).

## Details

Source: World Checklist of Useful Plant Species (Diazgranados et al.
2020, KNB, CC BY 4.0). Coverage: ~39k plant species.

## References

Diazgranados M et al. (2020) World Checklist of Useful Plant Species.
Knowledge Network for Biocomplexity.
[doi:10.5063/F1CV4G34](https://doi.org/10.5063/F1CV4G34)

## Examples

``` r
# \donttest{
taxify("Acorus calamus", backend = "gbif") |>
  add_useful_plants()
# }
```
