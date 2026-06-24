# Add plant traits from Baseflor (Catminat / Julve)

Joins Baseflor (Julve, Programme Catminat) plant traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Baseflor covers the vascular flora
of France and neighbouring regions, providing flowering phenology,
pollination and breeding biology, dispersal mode, and floral and fruit
morphology.

## Usage

``` r
add_baseflor(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- flower_begin_month:

  First month of flowering (1-12).

- flower_end_month:

  Last month of flowering (1-12). A value smaller than
  `flower_begin_month` denotes a flowering period that wraps across the
  new year (e.g. begin 10, end 6).

- pollination_vector:

  Pollination vector(s): insect, wind, water, self, apogamy.
  Comma-separated when more than one applies.

- dispersal_mode:

  Diaspore dispersal mode(s): anemochory, barochory, epizoochory,
  endozoochory, myrmecochory, hydrochory, autochory, dyszoochory.
  Comma-separated when more than one applies.

- breeding_system:

  Sexual system: hermaphroditic, monoecious, dioecious, gynodioecious,
  androdioecious, gynomonoecious, polygamous.

- flower_colour:

  Flower colour(s): white, yellow, pink, green, blue, brown, black.
  Comma-separated when more than one applies.

- fruit_type:

  Fruit type: achene, capsule, caryopsis, drupe, legume, silique, berry,
  follicle, cone, samara, pyxid.

- woody_growth_form:

  Woody growth form for woody taxa: tree, small tree, large tree, shrub,
  bush, subshrub, liana, parasite. NA for non-woody (herbaceous) taxa.

- continentality:

  Ellenberg-style continentality indicator value (1-9), the axis absent
  from EIVE.

- salinity:

  Ellenberg-style salinity indicator value (0-9), the axis absent from
  EIVE.

## Details

Source: Baseflor, Programme Catminat (Julve 1998 ff.). Coverage: ~7,000
vascular plant taxa of France and neighbouring regions. Data are
released under ODbL 1.0 / CC BY-SA 2.0.

For ecological indicator values on the light, temperature, moisture,
reaction, and nutrient axes, see
[`add_eive()`](https://gillescolling.com/taxify/reference/add_eive.md)
(European calibration). For Raunkiaer life form and seed, leaf, and
clonality traits of the Northwest European flora, see
[`add_leda()`](https://gillescolling.com/taxify/reference/add_leda.md).

## References

Julve, Ph. (1998 ff.) baseflor. Index botanique, ecologique et
chorologique de la Flore de France. Programme Catminat.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Bellis perennis") |>
  add_baseflor()

options(old)
```
