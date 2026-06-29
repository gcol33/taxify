# Test whether a canonical name carries an aggregate marker

`TRUE` for names ending in any aggregate marker spelling (`agg.`,
`aggr.`, `-agg`, `s.l.`, `sensu lato`, `coll. sp.`). Exported for the
taxifydb build pipeline so it can keep aggregate source rows out of
cross-backbone name expansion (which would otherwise leak an aggregate
trait onto the binomial species key).

## Usage

``` r
is_aggregate_name(x)
```

## Arguments

- x:

  Character vector of canonical names.

## Value

Logical vector; `FALSE` for `NA`.
