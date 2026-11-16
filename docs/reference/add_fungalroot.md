# Add mycorrhizal type from FungalRoot

Joins genus-level mycorrhizal type from the FungalRoot database
(Soudzilovskaia et al. 2020) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `genus`. Mycorrhizal type is phylogenetically
conserved at the genus level, which is the resolution FungalRoot
recommends for inference, so this enrichment joins on `genus` rather
than `accepted_name`.

## Usage

``` r
add_fungalroot(x, verbose = TRUE, cols = NULL)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

- cols:

  Which columns to attach. `NULL` (the default) attaches the curated
  set; a character vector of column names attaches just those, and
  `"all"` attaches every column the source carries (see
  [`enrichment_cols()`](https://gillescolling.com/taxify/reference/enrichment_cols.md)).

## Value

The same data.frame with three additional columns:

- fungalroot_mycorrhizal_type:

  Genus-level majority-consensus type, one of `AM` (arbuscular), `EcM`
  (ecto), `ErM` (ericoid), `OM` (orchid), `NM` (non-mycorrhizal), the
  dual types `EcM-AM` / `ErM-EcM` / `ErM-AM`, `Other`, or `uncertain`.
  `NA` if the genus is not in FungalRoot.

- fungalroot_mycorrhizal_status:

  Coarse status derived from the type: `"mycorrhizal"`,
  `"non-mycorrhizal"`, or `"uncertain"`.

- fungalroot_mycorrhizal_records:

  Number of FungalRoot observations supporting the genus-level
  consensus.

## Details

Source: FungalRoot, published on GBIF as a Darwin Core Archive
([doi:10.15468/a7ujmj](https://doi.org/10.15468/a7ujmj) ), CC BY-NC 4.0.
The per-genus value is a majority consensus computed from the
per-observation mycorrhiza type labels, not FungalRoot's own published
per-genus assignment. Plant genera only. The `.vtr` is downloaded from
the taxify release on first use and cached.

## References

Soudzilovskaia NA et al. (2020) FungalRoot: global online database of
plant mycorrhizal associations. New Phytologist 227:955-966.

## Examples

``` r
if (FALSE) { # \dontrun{
# Joins on genus, so any species in a covered genus is annotated.
taxify(c("Quercus robur", "Trifolium pratense")) |>
  add_fungalroot()
} # }
```
