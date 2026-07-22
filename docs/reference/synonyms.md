# List the synonyms of a name

The reverse of the forward resolution
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) does:
each input name is resolved to its accepted taxon, then every synonym
that points to that accepted taxon in the backbone is returned. Useful
for auditing which historical names collapse onto a current name.

## Usage

``` r
synonyms(x, backbone = NULL, verbose = TRUE)
```

## Arguments

- x:

  Character vector of names (accepted names or synonyms; each is
  resolved to its accepted taxon first).

- backbone:

  A single backbone name (e.g. `"wfo"`) or a `taxify_backend` object.
  `NULL` (default) uses the highest-priority installed backbone.

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame with one row per synonym found, columns:

- input_name:

  The queried name.

- accepted_name:

  The accepted name the query resolved to.

- synonym:

  A synonym of that accepted taxon.

- authorship:

  Authorship of the synonym.

- rank:

  Rank of the synonym.

- taxon_id:

  Backend ID of the synonym.

- backbone:

  Backend used.

Names that resolve to an accepted taxon with no synonyms contribute no
rows.

## See also

[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) for
the forward direction,
[`children()`](https://gillescolling.com/taxify/reference/children.md)
to list the accepted taxa within a genus or family.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

# Amphibolurus vitticeps is a synonym of Pogona vitticeps
synonyms("Pogona vitticeps", backbone = "reptiledb")

options(old)
```
