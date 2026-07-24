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
box::use(
    statim[define_model, prepare, via, conclude]
)

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

# Pairwise method (Holm method)
define_model(x_by(x, g)) |>
    prepare(KW_TEST) |>
    via("pairwise") |>
    conclude()
#> 
#> == Model ======================================================================= 
#> 
#> Variable Mapper : x_by 
#> Args : x | g 
#>     x_vars : 1 
#>     by_vars : 1 
#> 
#> == Kruskal-Wallis Test · pairwise ============================================== 
#> 
#> -- Summary ---------------------------------------------------------------------
#> 
#> ──────────────────────────
#>   statistic  p_value  df  
#> ──────────────────────────
#>     1.022     0.906   4   
#> ──────────────────────────
#> 
#> 
#> -- Comparison ------------------------------------------------------------------
#> 
#> ─────────────┬──────────────────────────────────────────────
#>   comparison │   diff   std_err  statistic  p_value  p_adj  
#> ─────────────┼──────────────────────────────────────────────
#>    d and e   │  0.495    6.552     0.076     0.940     1    
#>    d and c   │  0.597    7.083     0.084     0.933     1    
#>    d and a   │  -1.960   6.552    -0.299     0.765     1    
#>    d and b   │  -4.778   6.552    -0.729     0.466     1    
#>    e and c   │  0.102    6.774     0.015     0.988     1    
#>    e and a   │  -2.455   6.216    -0.395     0.693     1    
#>    e and b   │  -5.273   6.216    -0.848     0.396     1    
#>    c and a   │  -2.557   6.774    -0.377     0.706     1    
#>    c and b   │  -5.375   6.774    -0.794     0.427     1    
#>    a and b   │  -2.818   6.216    -0.453     0.650     1    
#> ─────────────┴──────────────────────────────────────────────
#> 
#> 

# Pairwise method (Bonferroni method)
define_model(x_by(x, g)) |>
    prepare(KW_TEST) |>
    via("pairwise", p_adj_method = "bonferroni") |>
    conclude()
#> 
#> == Model ======================================================================= 
#> 
#> Variable Mapper : x_by 
#> Args : x | g 
#>     x_vars : 1 
#>     by_vars : 1 
#> 
#> == Kruskal-Wallis Test · pairwise ============================================== 
#> 
#> -- Summary ---------------------------------------------------------------------
#> 
#> ──────────────────────────
#>   statistic  p_value  df  
#> ──────────────────────────
#>     1.022     0.906   4   
#> ──────────────────────────
#> 
#> 
#> -- Comparison ------------------------------------------------------------------
#> 
#> ─────────────┬──────────────────────────────────────────────
#>   comparison │   diff   std_err  statistic  p_value  p_adj  
#> ─────────────┼──────────────────────────────────────────────
#>    d and e   │  0.495    6.552     0.076     0.940     1    
#>    d and c   │  0.597    7.083     0.084     0.933     1    
#>    d and a   │  -1.960   6.552    -0.299     0.765     1    
#>    d and b   │  -4.778   6.552    -0.729     0.466     1    
#>    e and c   │  0.102    6.774     0.015     0.988     1    
#>    e and a   │  -2.455   6.216    -0.395     0.693     1    
#>    e and b   │  -5.273   6.216    -0.848     0.396     1    
#>    c and a   │  -2.557   6.774    -0.377     0.706     1    
#>    c and b   │  -5.375   6.774    -0.794     0.427     1    
#>    a and b   │  -2.818   6.216    -0.453     0.650     1    
#> ─────────────┴──────────────────────────────────────────────
#> 
#> 
```
