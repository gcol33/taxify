# List the regions accepted by `region=`

Returns every region code and name the `region` argument of
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
resolves, across both vocabularies it accepts, optionally filtered by a
search term matched (case- and accent-insensitively) against the code
and all three level names.

## Usage

``` r
taxify_regions(search = NULL, scheme = c("all", "wgsrpd", "meow"))
```

## Arguments

- search:

  Optional character string. If supplied, only regions whose code or
  name contains it are returned.

- scheme:

  Which vocabulary to list: `"all"` (the default), `"wgsrpd"` for the
  botanical regions, or `"meow"` for the marine ones.

## Value

A data.frame with columns `code`, `name`, `level2_name`, `level1_name`,
and `scheme`, one row per region.

## Details

Botanical regions (`scheme = "wgsrpd"`) come from the bundled WGSRPD
(World Geographical Scheme for Recording Plant Distributions) Level 3
crosswalk, and are also the codes
[`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md)
uses. Marine regions (`scheme = "meow"`) are the Marine Ecoregions of
the World, listed only when the `marine_distribution` asset is
installed, since that is also when `region=` resolves them. The two
schemes nest the same way, so they share the three name columns: a MEOW
ecoregion is the `name`, its province the `level2_name`, and its realm
the `level1_name`.

## Examples

``` r
head(taxify_regions())
#>   code                name            level2_name      level1_name scheme
#> 1  ABT             Alberta         Western Canada NORTHERN AMERICA wgsrpd
#> 2  AFG         Afghanistan           Western Asia   ASIA-TEMPERATE wgsrpd
#> 3  AGE Argentina Northeast Southern South America SOUTHERN AMERICA wgsrpd
#> 4  AGS     Argentina South Southern South America SOUTHERN AMERICA wgsrpd
#> 5  AGW Argentina Northwest Southern South America SOUTHERN AMERICA wgsrpd
#> 6  ALA             Alabama    Southeastern U.S.A. NORTHERN AMERICA wgsrpd
# \donttest{
taxify_regions("belgium")
#>   code    name   level2_name level1_name scheme
#> 1  BGM Belgium Middle Europe      EUROPE wgsrpd
taxify_regions("Europe")
#>     code                          name            level2_name
#> 1    ALB                       Albania    Southeastern Europe
#> 2    AUT                       Austria          Middle Europe
#> 3    BAL                      Baleares    Southwestern Europe
#> 4    BGM                       Belgium          Middle Europe
#> 5    BLR                       Belarus         Eastern Europe
#> 6    BLT                 Baltic States         Eastern Europe
#> 7    BUL                      Bulgaria    Southeastern Europe
#> 8    COR                         Corse    Southwestern Europe
#> 9    CZE                Czechoslovakia          Middle Europe
#> 10   DEN                       Denmark        Northern Europe
#> 11   FIN                       Finland        Northern Europe
#> 12   FOR                       Føroyar        Northern Europe
#> 13   FRA                        France    Southwestern Europe
#> 14   GER                       Germany          Middle Europe
#> 15   GRB                 Great Britain        Northern Europe
#> 16   GRC                        Greece    Southeastern Europe
#> 17   HUN                       Hungary          Middle Europe
#> 18   ICE                       Iceland        Northern Europe
#> 19   IRE                       Ireland        Northern Europe
#> 20   ITA                         Italy    Southeastern Europe
#> 21   KRI                         Kriti    Southeastern Europe
#> 22   KRY                          Krym         Eastern Europe
#> 23   NET                   Netherlands          Middle Europe
#> 24   NOR                        Norway        Northern Europe
#> 25   POL                        Poland          Middle Europe
#> 26   POR                      Portugal    Southwestern Europe
#> 27   ROM                       Romania    Southeastern Europe
#> 28   RUC       Central European Russia         Eastern Europe
#> 29   RUE          East European Russia         Eastern Europe
#> 30   RUN         North European Russia         Eastern Europe
#> 31   RUS         South European Russia         Eastern Europe
#> 32   RUW     Northwest European Russia         Eastern Europe
#> 33   SAR                      Sardegna    Southwestern Europe
#> 34   SIC                       Sicilia    Southeastern Europe
#> 35   SPA                         Spain    Southwestern Europe
#> 36   SVA                      Svalbard        Northern Europe
#> 37   SWE                        Sweden        Northern Europe
#> 38   SWI                   Switzerland          Middle Europe
#> 39   TUE              Turkey-in-Europe    Southeastern Europe
#> 40   UKR                       Ukraine         Eastern Europe
#> 41   YUG                    Yugoslavia    Southeastern Europe
#> 42 20021                 Faroe Plateau Northern European Seas
#> 43 20025                     North Sea Northern European Seas
#> 44 20027 South European Atlantic Shelf             Lusitanian
#> 45 20022               Southern Norway Northern European Seas
#> 46 20026                   Celtic Seas Northern European Seas
#> 47 20023  Northern Norway and Finnmark Northern European Seas
#> 48 20020        South and West Iceland Northern European Seas
#> 49 20024                    Baltic Sea Northern European Seas
#>                    level1_name scheme
#> 1                       EUROPE wgsrpd
#> 2                       EUROPE wgsrpd
#> 3                       EUROPE wgsrpd
#> 4                       EUROPE wgsrpd
#> 5                       EUROPE wgsrpd
#> 6                       EUROPE wgsrpd
#> 7                       EUROPE wgsrpd
#> 8                       EUROPE wgsrpd
#> 9                       EUROPE wgsrpd
#> 10                      EUROPE wgsrpd
#> 11                      EUROPE wgsrpd
#> 12                      EUROPE wgsrpd
#> 13                      EUROPE wgsrpd
#> 14                      EUROPE wgsrpd
#> 15                      EUROPE wgsrpd
#> 16                      EUROPE wgsrpd
#> 17                      EUROPE wgsrpd
#> 18                      EUROPE wgsrpd
#> 19                      EUROPE wgsrpd
#> 20                      EUROPE wgsrpd
#> 21                      EUROPE wgsrpd
#> 22                      EUROPE wgsrpd
#> 23                      EUROPE wgsrpd
#> 24                      EUROPE wgsrpd
#> 25                      EUROPE wgsrpd
#> 26                      EUROPE wgsrpd
#> 27                      EUROPE wgsrpd
#> 28                      EUROPE wgsrpd
#> 29                      EUROPE wgsrpd
#> 30                      EUROPE wgsrpd
#> 31                      EUROPE wgsrpd
#> 32                      EUROPE wgsrpd
#> 33                      EUROPE wgsrpd
#> 34                      EUROPE wgsrpd
#> 35                      EUROPE wgsrpd
#> 36                      EUROPE wgsrpd
#> 37                      EUROPE wgsrpd
#> 38                      EUROPE wgsrpd
#> 39                      EUROPE wgsrpd
#> 40                      EUROPE wgsrpd
#> 41                      EUROPE wgsrpd
#> 42 Temperate Northern Atlantic   meow
#> 43 Temperate Northern Atlantic   meow
#> 44 Temperate Northern Atlantic   meow
#> 45 Temperate Northern Atlantic   meow
#> 46 Temperate Northern Atlantic   meow
#> 47 Temperate Northern Atlantic   meow
#> 48 Temperate Northern Atlantic   meow
#> 49 Temperate Northern Atlantic   meow
# }
```
