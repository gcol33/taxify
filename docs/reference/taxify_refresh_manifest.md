# Invalidate the session manifest cache

Forces the next `fetch_manifest()` call to re-fetch from the network.
Useful after the maintainer updates the manifest between R sessions
without restarting R.

## Usage

``` r
taxify_refresh_manifest()
```

## Value

No return value, called for side effects.
