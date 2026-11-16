# Add alien species first record years

Joins alien species first record data to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result, filtered by location. Data from the FirstRecords dataset
(Seebens & Renard Truong 2026; Seebens et al. 2017).

## Usage

``` r
add_alien_first_records(x, location, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- location:

  Character. Location key(s), or `"all"`. A location that is a whole
  country is given by its ISO 3166-1 alpha-2 code (e.g. `"AT"`, `"US"`);
  an island or other part of a country that the source records as a
  region of its own is given by its name (e.g. `"Hawaii"`,
  `"Canary Islands"`).

  - Single location (e.g., `"AT"`): adds columns without suffix.

  - Multiple locations (e.g., `c("AT", "DE")`): adds columns with a
    location suffix (e.g., `alien_first_record_AT`).

  - `"all"`: adds one column set per location in the dataset.

  List the locations covered with
  `enrichment_groups("alien_first_records")`.

- cols:

  Character vector of value columns to attach (from
  `alien_first_records_year`, `alien_first_records_source`,
  `alien_first_records_reference`, plus the dataset's further columns
  such as `country_code` and `alien_first_record_status`), or `"all"`.
  `NULL` (default) attaches the first three.

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional column(s):

- alien_first_records_year:

  Year of the first record (integer), or `NA` if not recorded for that
  location.

- alien_first_records_source:

  Database that contributed the record (e.g., `"GAVIA"`, `"CABI ISC"`).

- alien_first_records_reference:

  Original citation or reference for the record.

## Details

The source's locations do not overlap: a country's location excludes the
islands and other parts recorded separately, so `location = "US"` is the
first record for the United States without Hawaii and Alaska, and a
species first recorded on Hawaii has no `"US"` record unless the source
holds one for the country itself. Seebens et al. (2017) define the set
as "282 non-overlapping regions (countries and sub-national regions such
as islands)". Every row carries `country_code`, the ISO 3166-1 alpha-2
code of the country the location lies in, so a country-wide first record
is an explicit roll-up: request the country's locations and take the
earliest year.

Source: FirstRecords v4.0 (Seebens & Renard Truong 2026,
doi:10.5281/zenodo.18759840), CC BY 4.0, one row per species x location.

## References

Seebens H, Blackburn TM, Dyer EE, et al. (2017) No saturation in the
accumulation of alien species worldwide. Nature Communications 8:14435.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Robinia pseudoacacia") |>
  add_alien_first_records(location = "AT")
#> Matching 1 names against 8 backbones: col -> wcvp -> lcvp -> wfo -> fishbase -> sealifebase -> reptiledb -> gbif
#>   [col] Matching 1 names...
#>   [wcvp] Matching 1 remaining names...
#>   [lcvp] Matching 1 remaining names...
#>   [wfo] Matching 1 remaining names...
#>   [fishbase] Skipped (all names matched)
#>   [sealifebase] Skipped (all names matched)
#>   [reptiledb] Skipped (all names matched)
#>   [gbif] Skipped (all names matched)
#>             input_name         matched_name        accepted_name   taxon_id
#> 1 Robinia pseudoacacia Robinia pseudoacacia Robinia pseudoacacia wfo-ex-006
#>   accepted_id    rank   family   genus      epithet authorship
#> 1  wfo-ex-006 species Fabaceae Robinia pseudoacacia         L.
#>   accepted_authorship is_synonym taxonomic_status is_hybrid match_type
#> 1                  L.      FALSE         ACCEPTED     FALSE      exact
#>   fuzzy_dist backbone         backbone_version kingdom_group taxon_group
#> 1         NA      wfo wfo:example (2026-06-24)       plantae        <NA>
#>   life_form qualifier qualifier_position aggregate_fallback hybrid_type
#> 1      <NA>      <NA>               <NA>                 NA        <NA>
#>   alien_first_records_year        alien_first_records_source
#> 1                       11 example_alien_first_record_source
#>          alien_first_records_reference
#> 1 example_alien_first_record_reference
#> Sources: WFO example, Alien first records (Seebens et al.) example | cite() for full citations

taxify(c("Robinia pseudoacacia", "Ailanthus altissima")) |>
  add_alien_first_records(location = c("AT", "DE", "Hawaii"))
#> Matching 2 names against 8 backbones: col -> wcvp -> lcvp -> wfo -> fishbase -> sealifebase -> reptiledb -> gbif
#>   [col] Matching 2 names...
#>   [wcvp] Matching 2 remaining names...
#>   [lcvp] Matching 2 remaining names...
#>   [wfo] Matching 2 remaining names...
#>   [fishbase] Skipped (all names matched)
#>   [sealifebase] Skipped (all names matched)
#>   [reptiledb] Skipped (all names matched)
#>   [gbif] Skipped (all names matched)
#> Tip: pipe into taxify_long() to reshape wide columns to long format.
#>             input_name         matched_name        accepted_name   taxon_id
#> 1 Robinia pseudoacacia Robinia pseudoacacia Robinia pseudoacacia wfo-ex-006
#> 2  Ailanthus altissima  Ailanthus altissima  Ailanthus altissima wfo-ex-007
#>   accepted_id    rank        family     genus      epithet      authorship
#> 1  wfo-ex-006 species      Fabaceae   Robinia pseudoacacia              L.
#> 2  wfo-ex-007 species Simaroubaceae Ailanthus    altissima (Mill.) Swingle
#>   accepted_authorship is_synonym taxonomic_status is_hybrid match_type
#> 1                  L.      FALSE         ACCEPTED     FALSE      exact
#> 2     (Mill.) Swingle      FALSE         ACCEPTED     FALSE      exact
#>   fuzzy_dist backbone         backbone_version kingdom_group taxon_group
#> 1         NA      wfo wfo:example (2026-06-24)       plantae        <NA>
#> 2         NA      wfo wfo:example (2026-06-24)       plantae  angiosperm
#>    life_form qualifier qualifier_position aggregate_fallback hybrid_type
#> 1       <NA>      <NA>               <NA>                 NA        <NA>
#> 2 angiosperm      <NA>               <NA>                 NA        <NA>
#>   alien_first_records_year_AT     alien_first_records_source_AT
#> 1                          11 example_alien_first_record_source
#> 2                          13 example_alien_first_record_source
#>       alien_first_records_reference_AT alien_first_records_year_DE
#> 1 example_alien_first_record_reference                          12
#> 2 example_alien_first_record_reference                          14
#>       alien_first_records_source_DE     alien_first_records_reference_DE
#> 1 example_alien_first_record_source example_alien_first_record_reference
#> 2 example_alien_first_record_source example_alien_first_record_reference
#>   alien_first_records_year_Hawaii alien_first_records_source_Hawaii
#> 1                              15 example_alien_first_record_source
#> 2                              NA                              <NA>
#>   alien_first_records_reference_Hawaii
#> 1 example_alien_first_record_reference
#> 2                                 <NA>
#> Sources: WFO example, Alien first records (Seebens et al.) example | cite() for full citations

options(old)
```
