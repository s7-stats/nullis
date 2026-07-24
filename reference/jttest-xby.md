# Jonckheere-Terpstra Test: Grouped (`x_by`)

The `x_by` implementation tests whether a continuous variable trends
monotonically across the levels of one or more grouping variables. It
accepts one or more grouping variables via
[`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html),
running one Jonckheere-Terpstra test per grouping variable.

## Arguments

`jttest_def_xby`'s baseline `fn` passes these straight through to the
compiled `jonckheere_terpstra_test()` C++ backend:

- `alternative`:

  One of `"two.sided"`, `"increasing"`, or `"decreasing"`. Default
  `"two.sided"`. Invalid values are rejected by the backend itself.

- `approximate`:

  Force the normal approximation instead of the exact null distribution.
  Default `FALSE`. The backend only uses the exact distribution when
  there are 50 or fewer observations and this is `FALSE`.

## Grouping requirement

Every grouping variable passed to
[`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html) must
be an **ordered factor**. Jonckheere-Terpstra tests a *directional*
trend across group levels — unlike Kruskal-Wallis, group order changes
what the test means, so an unordered factor or plain character vector is
refused rather than silently sorted alphabetically.

## Grouped Jonckheere-Terpstra default class

Always returns a
[class_jt_test](https://s7-stats.github.io/nullis/reference/class_jt_test.md)
object, which inherits
[statim::class_stat_infer](https://s7-stats.github.io/statim/reference/class_stat_infer.html)
and so picks up
[`statim::auto_tidy()`](https://s7-stats.github.io/statim/reference/auto_tidy.html)
automatically. There is no separate `making_tidy()` registration needed
for this path.

## Examples

``` r
set.seed(123)
x = rcauchy(50, 1, 1.5)
g = factor(
    sample(letters[1:3], size = 50, replace = TRUE),
    levels = c("a", "b", "c"),
    ordered = TRUE
)
JT_TEST(x_by(x, g))
#> -- Summary ---------------------------------------------------------------------
#> 
#> ─────────────────────────────────────────────────────────────────────
#>   vars   mean    variance  statistic  z_score  p_value  alternative  
#> ─────────────────────────────────────────────────────────────────────
#>    g    414.500  3143.250     462      0.847    0.404    two.sided   
#> ─────────────────────────────────────────────────────────────────────
#> 
#> 
#> -- Details ---------------------------------------------------------------------
#> 
#> Warning: running command 'tput cols' had status 2
#> ----------------------------
#>   g: Approximate :   FALSE
#>   g: Method      :   exact
#> ----------------------------
#> 
#> 

JT_TEST(x_by(x, g), alternative = "increasing")
#> -- Summary ---------------------------------------------------------------------
#> 
#> ─────────────────────────────────────────────────────────────────────
#>   vars   mean    variance  statistic  z_score  p_value  alternative  
#> ─────────────────────────────────────────────────────────────────────
#>    g    414.500  3143.250     462      0.847    0.202   increasing   
#> ─────────────────────────────────────────────────────────────────────
#> 
#> 
#> -- Details ---------------------------------------------------------------------
#> 
#> Warning: running command 'tput cols' had status 2
#> ----------------------------
#>   g: Approximate :   FALSE
#>   g: Method      :   exact
#> ----------------------------
#> 
#> 

JT_TEST(x_by(x, g), approximate = TRUE)
#> -- Summary ---------------------------------------------------------------------
#> 
#> ─────────────────────────────────────────────────────────────────────
#>   vars   mean    variance  statistic  z_score  p_value  alternative  
#> ─────────────────────────────────────────────────────────────────────
#>    g    414.500  3143.250     462      0.847    0.397    two.sided   
#> ─────────────────────────────────────────────────────────────────────
#> 
#> 
#> -- Details ---------------------------------------------------------------------
#> 
#> Warning: running command 'tput cols' had status 2
#> -------------------------------------------
#>   g: Approximate :                   TRUE
#>   g: Method      :   normal approximation
#> -------------------------------------------
#> 
#> 
```
