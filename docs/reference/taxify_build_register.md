# Build the unified genus register from installed backbones

The genus register is a cross-backbone index of every genus in the
backbones you have installed, carrying each genus's higher
classification and its `life_form` / `kingdom_group` / `taxon_group`
labels.
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
consults it to fill those columns in its output regardless of which
backbone matched, and to flag out-of-scope names before fuzzy matching;
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
uses it for the anomaly checks that need no backbone. Without a
register, those features are silently skipped.

## Usage

``` r
taxify_build_register(verbose = TRUE)
```

## Arguments

- verbose:

  Logical. Print progress messages. Default `TRUE`.

## Value

Path to `genus_register.vtr` (invisibly).

## Details

The register is built locally from whichever backbones are installed
(see
[`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md)
and
[`install_backbones()`](https://gillescolling.com/taxify/reference/install_backbones.md));
it is not itself downloaded. Installing more backbones first yields a
register with broader genus coverage. Building reads every installed
backbone once and can take a few minutes.

`taxify_download("register")` is a convenience alias for this function.

## See also

[`taxify_load_register()`](https://gillescolling.com/taxify/reference/taxify_load_register.md)
to load it into memory,
[`taxify_register_coverage()`](https://gillescolling.com/taxify/reference/taxify_register_coverage.md)
to query backend coverage for a genus.
