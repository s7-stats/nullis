# Compare a variable by group given block

An extended version of
[`statim::x_by()`](https://s7-stats.github.io/statim/reference/x_by.html)
which adds `block`, used on statistical inference pipeline that applies
blocking

## Usage

``` r
x_by_b(x, group, block)
```

## Arguments

- x:

  The response variable. Accepts a bare name, a
  [`c()`](https://rdrr.io/r/base/c.html) of bare names, or a tidyselect
  helper (requires a `data` data frame).

- group:

  The grouping variable. Same rules as `x`.

- block:

  The blocking variable. Same rules as `x`.

## Value

An `x_by_b` / `var_id` S7 object.

## Details

Unlike
[`statim::x_by()`](https://s7-stats.github.io/statim/reference/x_by.html),
`x_by_b()` does not support [`I()`](https://rdrr.io/r/base/AsIs.html) or
`inlines()` for inline data. Only bare names,
[`c()`](https://rdrr.io/r/base/c.html), and tidyselect helpers (with
`data` supplied) are accepted for `x`, `group`, and `block`.

## Examples

``` r
x_by_b(x, g, blocking)
#> -- Model Definition ------------------------------------------------------------ 
#> 
#> Variable Mapper : x_by_b 
#> Args : x | g <=> [ blocking ] 
```
