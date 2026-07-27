# Mood's Median Test

`MEDIAN_TEST()` tests whether a continuous variable's population median
differs across the levels of one or more grouping variables. It works by
dichotomizing all observations at the grand median (or a supplied
`custom_median`) and running a chi-squared test of independence on the
resulting 2xk contingency table. If `MEDIAN_TEST` is supplied within the
lazy-loaded pipeline, supply `MEDIAN_TEST` as a function i.e.
`prepare_test(.test = MEDIAN_TEST)`.

## Usage

``` r
MEDIAN_TEST(.var_id = NULL, .data = NULL, ...)
```

## Arguments

- .var_id:

  A variable mapper `<var_id>`. Supports
  [`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html) and
  [`on()`](https://s7-stats.github.io/statim/reference/on.html). When
  supplied, the test executes immediately.
  [`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html) with
  more than one grouping variable requires `via("multi")` (see the
  **Supported variable mapper** section).

- .data:

  A data frame. Only used on the standalone path.

- ...:

  Additional arguments passed to the implementation: `custom_median` (a
  hypothesized median to split on, instead of the sample's own grand
  median), accepted on every path, accepted on default (which is the
  "base", both
  [`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html) and
  [`on()`](https://s7-stats.github.io/statim/reference/on.html)).
  [`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html)'s
  `multi` variant instead accepts `display_var` (whether an index or
  grouping-variable name choosing which variable's table to compute and
  show; that the default (base) or
  [`on()`](https://s7-stats.github.io/statim/reference/on.html) never
  have. See the **Supported variable mapper** section for the full list
  per path.

## Value

A `cld_exec` object (in
[`statim::conclude()`](https://s7-stats.github.io/statim/reference/conclude.html)),
a `stat_infer_spec` object, or a `test_spec` when `.var_id = NULL`.
`mmdtest_def_xby`'s `base` and `multi`, and `mmdtest_def_on`'s baseline,
all return a
[class_median_test](https://s7-stats.github.io/nullis/reference/class_median_test.md)
object. On `multi`, every grouping variable's test runs and its
`statistic`/`df`/`p_value`/`median` are kept, but only the
`display_var`-selected variable's contingency table is retained in
`cont_tab`, others' tables are discarded. On the
[`on()`](https://s7-stats.github.io/statim/reference/on.html) path,
`vars` is fixed to `"on"` since there is no grouping variable to label.

## Details

`H0`: all groups share a common population median. `H1`: at least one
group's median differs from the others.

## Supported variable mapper `<var_id>`s

- [`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html):
  grouped Mood's median test. The `base` path handles exactly one
  grouping variable; the `multi` variant handles more than one, running
  one test per grouping variable. See details from
  [mmdtest-xby](https://s7-stats.github.io/nullis/reference/mmdtest-xby.md).

- [`on()`](https://s7-stats.github.io/statim/reference/on.html):
  one-sample or k-sample Mood's median test via a compiled backend, run
  directly on `.proc$data` without an
  [`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html)
  split. See details from
  [mmdtest-on](https://s7-stats.github.io/nullis/reference/mmdtest-on.md).

## A note on `custom_median` for single-group tests

With exactly one group and no `custom_median` supplied, the split point
is estimated from that same group's data, so the above/below counts land
near a 50/50 split by construction and the test has little power to
detect anything. Supply `custom_median` (a hypothesized population
median) whenever you're testing a single group.

## See also

[mmdtest-xby](https://s7-stats.github.io/nullis/reference/mmdtest-xby.md),
[mmdtest-on](https://s7-stats.github.io/nullis/reference/mmdtest-on.md),
[class_median_test](https://s7-stats.github.io/nullis/reference/class_median_test.md),
[`statim::via()`](https://s7-stats.github.io/statim/reference/via.html),
[`statim::conclude()`](https://s7-stats.github.io/statim/reference/conclude.html)

## Examples

``` r
set.seed(123)
x = rcauchy(50, 1, 1.5)
g = sample(letters[1:5], size = 50, replace = TRUE)
MEDIAN_TEST(x_by(x, g))
#> -- Summary ---------------------------------------------------------------------
#> 
#> ────────────────────────────────────────────
#>   vars  n_groups  Q statistic  df  p_value  
#> ────────────────────────────────────────────
#>    g       5         3.066     4    0.547   
#> ────────────────────────────────────────────
#> 
#> 
#> Error: Can't find property <nullis::median_test>@freq_table

# against a hypothesized median rather than the sample's own
MEDIAN_TEST(x_by(x, g), custom_median = 1)
#> -- Summary ---------------------------------------------------------------------
#> 
#> ────────────────────────────────────────────
#>   vars  n_groups  Q statistic  df  p_value  
#> ────────────────────────────────────────────
#>    g       5         3.066     4    0.547   
#> ────────────────────────────────────────────
#> 
#> 
#> Error: Can't find property <nullis::median_test>@freq_table
```
