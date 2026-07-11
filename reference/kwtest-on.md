# Kruskal-Wallis Test: One-Sample (`on`)

The `on` implementation runs a Kruskal-Wallis test via a compiled C++
backend (`kruskal_wallis_cpp()`) directly on `.proc$data`, without going
through an R-level [`x_by()`](https://rdrr.io/pkg/statim/man/x_by.html)
grouping split.

## Arguments

`kwtest_def_on`'s baseline `fn` takes no arguments beyond `.proc` —
nothing is passed through `...` in
[`KW_TEST()`](https://s7-stats.github.io/nullis/reference/KW_TEST.md) or
[`statim::via()`](https://rdrr.io/pkg/statim/man/via.html) for this
path.

## Variants

None. `kwtest_def_on` declares only a `base` baseline — no `variant()`
entries.

## One-sample Kruskal-Wallis default class

No S7 wrapper. The baseline returns whatever `kruskal_wallis_cpp()`
returns, unwrapped, a plain list with `statistic`, `df`, `p_value`.
Unlike [`x_by()`](https://rdrr.io/pkg/statim/man/x_by.html), this path
does **not** return
[class_kw_test](https://s7-stats.github.io/nullis/reference/class_kw_test.md).
It has its own `print` method (a `tibble` with `H Statistic`,
`Degrees of Freedom`, `p-value` columns) and its own registered
[`statim::making_tidy()`](https://rdrr.io/pkg/statim/man/making_tidy.html)
entry (`tibble::as_tibble(.x@data)`), rather than inheriting
[`statim::auto_tidy()`](https://rdrr.io/pkg/statim/man/auto_tidy.html)
from `class_kw_test`.

## See also

Other kwtest-implementations:
[`kwtest-xby`](https://s7-stats.github.io/nullis/reference/kwtest-xby.md)

## Examples

``` r
set.seed(123)
x = rcauchy(50, 1, 1.5)
y = rcauchy(50, 3, 1.5)
KW_TEST(on(x, y))
#> ────────────────────────────────────────────
#>   H Statistic  Degrees of Freedom  p-value  
#> ────────────────────────────────────────────
#>     12.900             1           <0.001   
#> ────────────────────────────────────────────
#> 
```
