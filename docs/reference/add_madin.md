# Add bacterial and archaeal traits (Madin et al.)

Joins species-level bacterial and archaeal phenotypic and genome traits
to a [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_madin(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- madin_gram_stain:

  Gram stain (positive/negative).

- madin_metabolism:

  Metabolism (aerobic/anaerobic/facultative/...).

- madin_cell_shape:

  Cell shape (bacillus/coccus/spiral/...).

- madin_motility:

  Motility (yes/no/flagella/gliding/...).

- madin_sporulation:

  Sporulation (yes/no).

- madin_isolation_source:

  Isolation source category.

- madin_growth_temp_c:

  Recorded growth temperature (degrees Celsius).

- madin_optimum_temp_c:

  Optimum growth temperature (degrees Celsius).

- madin_optimum_ph:

  Optimum growth pH.

- madin_genome_size_bp:

  Genome size (base pairs).

- madin_gc_content_pct:

  Genomic G+C content (percent).

## Details

Source: Madin et al. (2020, Scientific Data, CC BY 4.0). Coverage:
~14.9k bacterial and archaeal species.

## References

Madin JS et al. (2020) A synthesis of bacterial and archaeal phenotypic
trait data. Scientific Data 7:170.
[doi:10.1038/s41597-020-0497-4](https://doi.org/10.1038/s41597-020-0497-4)

## Examples

``` r
# \donttest{
taxify("Escherichia coli", backend = "gbif") |>
  add_madin()
# }
```
