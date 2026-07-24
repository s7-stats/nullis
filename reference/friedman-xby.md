# Friedman Rank Sum Test: Blocked (`x_by_b`)

The `x_by_b` implementation tests whether treatment effects differ
across k \>= 2 related conditions measured on the same block (e.g.
repeated measures on the same subject, or a randomized block design). It
accepts a continuous response, a treatment/grouping variable, and a
blocking variable via
[`x_by_b()`](https://s7-stats.github.io/nullis/reference/x_by_b.md).

## Arguments

`friedman_def_xby`'s baseline `fn` takes no arguments beyond `.proc` —
nothing is currently passed through `...` in
[`FRIEDMAN_TEST()`](https://s7-stats.github.io/nullis/reference/FRIEDMAN_TEST.md)
or
[`statim::via()`](https://s7-stats.github.io/statim/reference/via.html).

## Variants

None. `friedman_def_xby` declares only a `base` baseline in its
[`statim::agendas()`](https://s7-stats.github.io/statim/reference/agendas.html)
— no `variant()` entries.

## Grouped Friedman default class

By default, returns a
[class_friedman_test](https://s7-stats.github.io/nullis/reference/class_friedman_test.md)
object. There is only one `base` baseline — no variants — so there's
nothing else to inherit or override.

## Examples

``` r
set.seed(123)
x = rnorm(30)
g = rep(letters[1:3], 10)
b = rep(1:10, each = 3)
FRIEDMAN_TEST(x_by_b(x, g, b))
#> -- Summary ---------------------------------------------------------------------
#> 
#> ──────────────────────────
#>   statistic  df  p_value  
#> ──────────────────────────
#>     1.400    2    0.497   
#> ──────────────────────────
#> 
#> 
```
