# Add spider traits (World Spider Trait Database)

Joins species-level spider morphometric and ecological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Values are aggregated from the
World Spider Trait Database (numeric traits by median, categorical
traits by mode); access-restricted source records are excluded.

## Usage

``` r
add_spider_traits(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- spider_body_length_mm:

  Body length (mm).

- spider_prosoma_length_mm:

  Cephalothorax (prosoma) length (mm).

- spider_prosoma_width_mm:

  Cephalothorax (prosoma) width (mm).

- spider_abdomen_length_mm:

  Abdomen (opisthosoma) length (mm).

- spider_leg1_length_mm:

  Leg I length (mm).

- spider_ballooning:

  Ballooning (aerial dispersal): yes/no.

- spider_web_building:

  Web building: yes/no.

- spider_hunting_guild:

  Hunting guild.

- spider_web_type:

  Web type.

- spider_circadian_activity:

  Circadian activity (diurnal/nocturnal).

- spider_stratum:

  Vertical stratum (habitat layer).

## Details

Source: World Spider Trait Database (Pekar et al. 2021, Database, CC BY
4.0). Coverage: ~7.3k spider species. Morphometry is sexually dimorphic
in spiders; the value here is the across-record median and is not split
by sex.

## References

Pekar S et al. (2021) The World Spider Trait database: a centralized
global open repository for curated data on spider traits. Database
2021:baab064.
[doi:10.1093/database/baab064](https://doi.org/10.1093/database/baab064)

## Examples

``` r
# \donttest{
taxify("Araneus diadematus", backend = "gbif") |>
  add_spider_traits()
# }
```
