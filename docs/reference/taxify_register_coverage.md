# Show backend coverage for a genus

Queries `backend_coverage.vtr` to determine which backends contain the
given genus, along with the backbone version at time of indexing.

## Usage

``` r
taxify_register_coverage(genus)
```

## Arguments

- genus:

  Character scalar. The genus name to query.

## Value

A data.frame with columns `genus`, `backend`, `version`, `date_added`.
Returns a zero-row data.frame if the genus is not found in any backend.
