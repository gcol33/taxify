# Add freshwater fish morphological traits (FISHMORPH)

Joins FISHMORPH morphological trait data to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. This is the source-named door for
FISHMORPH; for the fish reference database FishBase see
[`add_fishbase()`](https://gillescolling.com/taxify/reference/add_fishbase.md).

## Usage

``` r
add_fishmorph(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- fish_max_body_length:

  Maximum body length (cm).

- fish_body_elongation:

  Body elongation (body length / body depth).

- fish_vertical_eye_position:

  Vertical eye position (eye position / head depth).

- fish_relative_eye_size:

  Relative eye size (eye diameter / head length).

- fish_oral_gape_position:

  Oral gape position (mouth position: 0 = inferior, 0.5 = terminal, 1 =
  superior).

- fish_relative_maxillary_length:

  Relative maxillary length (maxillary length / head length).

- fish_body_lateral_shape:

  Body lateral shape (body depth / caudal peduncle depth).

- fish_pectoral_fin_position:

  Pectoral fin vertical position (fin insertion depth / body depth).

- fish_pectoral_fin_size:

  Pectoral fin size (fin length / body length).

- fish_caudal_peduncle_throttling:

  Caudal peduncle throttling (caudal peduncle depth / caudal fin depth).

## Details

Source: FISHMORPH (Brosse et al. 2021, Figshare, CC BY 4.0). Coverage:
~8.3k freshwater fish species.

## References

Brosse S, Charpin N, Su G, Toussaint A, Herrera-R GA, Tedesco PA,
Villegé r S (2021) FISHMORPH: A global database on morphological traits
of freshwater fishes. Global Ecology and Biogeography 30:2330-2336.
[doi:10.1111/geb.13395](https://doi.org/10.1111/geb.13395)

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Salmo trutta", backend = "gbif") |>
  add_fishmorph()

options(old)
```
