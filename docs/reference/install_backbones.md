# Install taxonomic backbones for offline matching

Downloads the pre-built `.vtr` for each named backbone into the taxify
data directory
([`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md)),
so subsequent
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) calls
match against them offline. Called without arguments it installs the
default set (COL, GBIF, ITIS, about 1.1 GB); name backbones to install a
different set, add a backbone, or refresh to the latest release. Calling
it is the consent to download: other functions that reach a backbone not
on disk ask first in an interactive session and stop with an error
otherwise, unless `options(taxify.auto_download = TRUE)` (or the
`TAXIFY_AUTO_DOWNLOAD` environment variable) allows the download.
[`taxify_clean()`](https://gillescolling.com/taxify/reference/taxify_clean.md)
removes backbones again.

## Usage

``` r
install_backbones(backbones = NULL, verbose = TRUE)
```

## Arguments

- backbones:

  Character vector of backbone names (see
  [`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md)).
  `NULL` (default) installs taxify's first-run set: COL, GBIF, and ITIS.

- verbose:

  Logical. Default `TRUE`.

## Value

Invisibly, the backbones now installed (those that downloaded
successfully, or were already on disk), in priority order. A backbone
whose refresh failed stays in the result with a warning, since its
previous build is still usable.

## Details

An installed backbone is compared against the manifest by the same check
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) runs
once per session: by content id where both sides record one, else by
version. A backbone whose build differs from the one the manifest serves
is replaced with the current release; one that is already current is
left as it is. A build pinned by
[`taxify_pin()`](https://gillescolling.com/taxify/reference/taxify_pin.md),
[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md)
or `taxify_download(content_id = )` is never refreshed, and a message
says so; `taxify_pin(backbone, pin = FALSE)` releases it. With
`options(taxify.offline = TRUE)` nothing is compared and installed
backbones are kept.

## See also

[`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md)
for the full set with sizes,
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

## Examples

``` r
if (FALSE) { # \dontrun{
# Pre-install a marine-focused set before matching:
install_backbones(c("col", "worms"))
} # }
```
