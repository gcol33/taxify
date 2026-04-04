# Get the taxify data directory

Returns the platform-appropriate directory where taxify stores
downloaded backbone `.vtr` files. Uses
[`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html) (available
since R 4.0).

## Usage

``` r
taxify_data_dir()
```

## Value

Character string. Path to the data directory.
