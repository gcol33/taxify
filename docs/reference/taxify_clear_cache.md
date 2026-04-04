# Clear all cached backbones

Removes all loaded backbone handles from memory. The next call to
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) will
re-load from disk.

## Usage

``` r
taxify_clear_cache()
```

## Value

No return value, called for side effects.
