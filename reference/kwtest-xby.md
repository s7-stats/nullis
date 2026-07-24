# Kruskal-Wallis Test: Grouped (`x_by`)

The `x_by` implementation tests whether a continuous variable's
distribution differs across the levels of one or more grouping
variables. It accepts one or more grouping variables via
[`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html),
running one Kruskal-Wallis test per grouping variable.

## Arguments

`kwtest_def_xby`'s baseline `fn` takes no arguments beyond `.proc`.
Nothing is currently passed through `...` in
[`KW_TEST()`](https://s7-stats.github.io/nullis/reference/KW_TEST.md) or
[`statim::via()`](https://s7-stats.github.io/statim/reference/via.html)
for the default path, yet.

## Variants

- `"pairwise"`:

  Runs the default Kruskal-Wallis test, then all pairwise group
  comparisons using a rank-based z-test with tie correction. Accepts one
  additional argument:

  `p_adj_method`

  :   P-value adjustment method for the pairwise comparisons, passed to
      [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html). Must
      be one of
      [stats::p.adjust.methods](https://rdrr.io/r/stats/p.adjust.html).
      Default `"holm"`.

  Requires at least two groups; errors otherwise.

## Grouped Kruskal-Wallis default class

By default, returns a
[class_kw_test](https://s7-stats.github.io/nullis/reference/class_kw_test.md)
object. The `pairwise` variant returns a plain list (`kw_test`, `comps`)
with its own registered `print` method — it does not return
`class_kw_test`, so it does not inherit
[`statim::auto_tidy()`](https://s7-stats.github.io/statim/reference/auto_tidy.html)
automatically.
[`statim::making_tidy()`](https://s7-stats.github.io/statim/reference/making_tidy.html)
is registered separately for the `pairwise` path via `.x@data$comps`.

## See also

Other kwtest-implementations:
[`kwtest-on`](https://s7-stats.github.io/nullis/reference/kwtest-on.md)

## Examples

``` r
set.seed(123)
x = rcauchy(50, 1, 1.5)
g = sample(letters[1:5], size = 50, replace = TRUE)
KW_TEST(x_by(x, g))
#> -- Summary ---------------------------------------------------------------------
#> 
#> ────────────────────────────────
#>   vars  statistic  df  p_value  
#> ────────────────────────────────
#>    g      1.022    4    0.906   
#> ────────────────────────────────
#> 
#> 

KW_TEST(x_by(x, g)) |> via("pairwise")
#> Error in via(KW_TEST(x_by(x, g)), "pairwise"): could not find function "via"

KW_TEST(x_by(x, g)) |> via("pairwise", p_adj_method = "bonferroni")
#> Error in via(KW_TEST(x_by(x, g)), "pairwise", p_adj_method = "bonferroni"): could not find function "via"
```
