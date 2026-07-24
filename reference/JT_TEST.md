# Jonckheere-Terpstra Test

`JT_TEST()` tests whether the distribution of a continuous variable
shifts monotonically across the *ordered* levels of a grouping variable.
It is a trend-sensitive alternative to Kruskal-Wallis: where
Kruskal-Wallis only asks whether the groups differ, Jonckheere-Terpstra
asks whether they differ in a consistent direction. If `JT_TEST` is
supplied within the lazy-loaded pipeline, supply `JT_TEST` as a function
i.e. `prepare_test(.test = JT_TEST)`.

## Usage

``` r
JT_TEST(.var_id = NULL, .data = NULL, ...)
```

## Arguments

- .var_id:

  A variable mapper `<var_id>`. Currently supports
  [`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html).
  When supplied, the test executes immediately. If `.var_id` maps
  multiple grouping variables, one Jonckheere-Terpstra test runs per
  grouping variable against the same continuous variable. Each grouping
  variable must be an ordered factor — see
  [jttest-xby](https://s7-stats.github.io/nullis/reference/jttest-xby.md).

- .data:

  A data frame. Only used on the standalone path.

- ...:

  Additional arguments passed to the implementation, including
  `alternative` and `approximate`. See
  [jttest-xby](https://s7-stats.github.io/nullis/reference/jttest-xby.md)
  for the full list.

## Value

A `cld_exec` object (in
[`statim::conclude()`](https://s7-stats.github.io/statim/reference/conclude.html)),
a `stat_infer_spec` object, or a `test_spec` when `.var_id = NULL`.
`jttest_def_xby` always returns a
[class_jt_test](https://s7-stats.github.io/nullis/reference/class_jt_test.md)
object.

## Details

`H0`: all groups come from the same distribution. `H1`: the groups are
stochastically ordered in the direction given by `alternative`.

## Supported variable mapper `<var_id>`s

- [`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html):
  grouped Jonckheere-Terpstra test against an ordered grouping variable.
  See details from
  [jttest-xby](https://s7-stats.github.io/nullis/reference/jttest-xby.md).

## See also

[jttest-xby](https://s7-stats.github.io/nullis/reference/jttest-xby.md),
[class_jt_test](https://s7-stats.github.io/nullis/reference/class_jt_test.md),
[`statim::via()`](https://s7-stats.github.io/statim/reference/via.html),
[`statim::conclude()`](https://s7-stats.github.io/statim/reference/conclude.html)

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

# direction of the trend matters here, unlike Kruskal-Wallis
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

# multiple grouping variables -> one test per grouping variable
# (confirm this call shape against your actual x_by() signature)
g2 = factor(
    sample(c("low", "high"), size = 50, replace = TRUE),
    levels = c("low", "high"),
    ordered = TRUE
)
JT_TEST(x_by(x, c(g, g2)))
#> -- Summary ---------------------------------------------------------------------
#> 
#> ─────────────────────────────────────────────────────────────────────
#>   vars   mean    variance  statistic  z_score  p_value  alternative  
#> ─────────────────────────────────────────────────────────────────────
#>    g    414.500  3143.250     462      0.847    0.404    two.sided   
#>    g2   308.000  2618.000     260     -0.938    0.356    two.sided   
#> ─────────────────────────────────────────────────────────────────────
#> 
#> 
#> -- Details ---------------------------------------------------------------------
#> 
#> Warning: running command 'tput cols' had status 2
#> -----------------------------
#>   g: Approximate  :   FALSE
#>   g2: Approximate :   FALSE
#>   g: Method       :   exact
#>   g2: Method      :   exact
#> -----------------------------
#> 
#> 
```
