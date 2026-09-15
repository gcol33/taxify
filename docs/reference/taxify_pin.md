# Pin or release installed taxify assets

A pinned build stays active: the version check that
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md),
[`install_backbones()`](https://gillescolling.com/taxify/reference/install_backbones.md)
and the `add_*()` doors run against the manifest leaves it in place
instead of replacing it with the current release. Pin the builds a
project was run against to keep a shared data directory from moving
under it, and release them when the project is done. The pin is recorded
in the build's `meta.json` together with its content id (the md5 of its
`.vtr`, as
[`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md)
records it), so a pinned build can also be named in a lockfile.

## Usage

``` r
taxify_pin(name, pin = TRUE, kind = NULL, verbose = TRUE)
```

## Arguments

- name:

  Character vector of installed backbone and/or enrichment names.

- pin:

  Logical. `TRUE` (default) pins; `FALSE` releases the pin, so the next
  version check compares the build against the manifest again.

- kind:

  `NULL` (default) to find each name among the installed backbones and
  enrichments, or `"backbone"` / `"enrichment"` to look only there.
  Needed for a name installed as both (e.g. `"wcvp"`).

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame with one row per name: `component`, `type`, `version`,
`content_id` (the full id of the build pinned or released) and `pinned`.

## Details

Every name is checked before anything is written: when one is not
installed, or is installed as both a backbone and an enrichment and
`kind` does not say which, nothing is pinned.

[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md)
with `install = TRUE` pins every build matching a lockfile, and a build
fetched with `taxify_download(content_id = )` or
`taxify_download_enrichment(content_id = )` is pinned when it is
activated.

## See also

[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md)
to pin the builds a lockfile records,
[`taxify_store()`](https://gillescolling.com/taxify/reference/taxify_store.md)
to list the builds on disk and whether each is pinned.

## Examples

``` r
if (FALSE) { # \dontrun{
taxify_pin(c("wfo", "col"))
taxify_pin("iucn", kind = "enrichment")
taxify_pin(c("wfo", "col"), pin = FALSE)
} # }
```
