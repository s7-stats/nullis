# Cochran's Q test

`COCHRAN_QTEST()` tests whether the distribution of a continuous
variable differs across the levels of one or more grouping variables. It
is the rank-based, distribution-free analogue to one-way ANOVA. If
`COCHRAN_QTEST` is supplied within the lazy-loaded pipeline, supply
`COCHRAN_QTEST` as a function i.e.
`prepare_test(.test = COCHRAN_QTEST)`.

## Usage

``` r
COCHRAN_QTEST(.var_id = NULL, .data = NULL, ...)
```

## Arguments

- .var_id:

  A variable mapper `<var_id>`. Currently supports
  [`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html).
  When supplied, the test executes immediately. If `.var_id` maps
  multiple grouping variables, one Kruskal-Wallis test runs per grouping
  variable against the same continuous variable.

- .data:

  A data frame. Only used on the standalone path.

- ...:

  Additional arguments passed to the implementation. See the **Supported
  variable mapper** section for the full list per path.

## Value

A `cld_exec` object (in
[`statim::conclude()`](https://s7-stats.github.io/statim/reference/conclude.html)),
a `stat_infer_spec` object, or a `test_spec` when `.var_id = NULL`.
`cqtest_def_xby`'s baseline returns a
[class_cq_test](https://s7-stats.github.io/nullis/reference/class_cq_test.md)
object by default; its `pairwise` variant instead returns a plain list
(`COCHRAN_QTEST`, `comps`) with its own `print` method.
`cqtest_def_on`'s baseline returns a plain list (`statistic`, `df`,
`p_value`) with its own `print` method — neither path shares a class
between them.

## Details

`H0`: all samples come from the same distribution (equal medians, under
the assumption of equal shape). `H1`: at least one sample is
stochastically greater than another.

## Supported variable mapper `<var_id>`s

- [`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html):
  grouped Kruskal-Wallis test, with optional pairwise comparisons. See
  details from
  [cqtest-xby](https://s7-stats.github.io/nullis/reference/cqtest-xby.md).

## See also

[cqtest-xby](https://s7-stats.github.io/nullis/reference/cqtest-xby.md),
[class_cq_test](https://s7-stats.github.io/nullis/reference/class_cq_test.md),
[`statim::via()`](https://s7-stats.github.io/statim/reference/via.html),
[`statim::conclude()`](https://s7-stats.github.io/statim/reference/conclude.html)

## Examples

``` r
set.seed(123)
x = sample(0:1, 45, replace = TRUE)
treatment = gl(3, 1, 45, labels = c("A", "B", "C"))
block = gl(5, 3, 45, labels = 1:5)
COCHRAN_QTEST(x_by_b(x, treatment, block))
#> -- Summary ---------------------------------------------------------------------
#> 
#> ─────────────────────────────────────────────────
#>     vars     n_groups  Q statistic  df  p_value  
#> ─────────────────────────────────────────────────
#>   treatment     3         1.500     2    0.472   
#> ─────────────────────────────────────────────────
#> 
#> 
#> -- Frequency Table -------------------------------------------------------------
#> 
#>                           Cross Tabulation:   by Value
#>                           ───────────────────────────
#>                                     Value     
#>                           ───────────────────────────
#>                                     0    1    TOTAL  
#>                           ───────────────────────────
#>                             A       7    8     15    
#>                           
#>                             B       10   5     15    
#>                           
#>                             C       9    6     15    
#>                           ───────────────────────────
#>                             TOTAL   26   19    45    
#>                           ───────────────────────────
#> 
```
