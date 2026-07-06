# Kruskal-Wallis rank sum test

`KW_TEST()` tests whether the distribution of a continuous variable
differs across the levels of one or more grouping variables. It is the
rank-based, distribution-free analogue to one-way ANOVA. If `KW_TEST` is
supplied within the lazy-loaded pipeline, supply `KW_TEST` as a function
i.e. `prepare_test(.test = KW_TEST)`.

## Usage

``` r
KW_TEST(.var_id = NULL, .data = NULL, ...)
```

## Arguments

- .var_id:

  A variable mapper `<var_id>`. Currently supports `x_by()`. When
  supplied, the test executes immediately. If `.var_id` maps multiple
  grouping variables, one Kruskal-Wallis test runs per grouping variable
  against the same continuous variable.

- .data:

  A data frame. Only used on the standalone path.

- ...:

  Additional arguments passed to the implementation. See the **Arguments
  by variable mapper** section for the full list per path.

## Value

A `cld_exec` object (in
[`statim::conclude()`](https://rdrr.io/pkg/statim/man/conclude.html)), a
`stat_infer_spec` object, or a `test_spec` when `.var_id = NULL`.
Depending on the implementation you wrote, it returns any class.

## Details

`H0`: all samples come from the same distribution (equal medians, under
the assumption of equal shape). `H1`: at least one sample is
stochastically greater than another.

## Examples

``` r
set.seed(123)
x = rcauchy(50, 1, 1.5)
g = sample(letters[1:5], size = 50, replace = TRUE)
KW_TEST(x_by(x, g))
#> Error in x_by(x, g): could not find function "x_by"

# multiple grouping variables -> one test per grouping variable
# (confirm this call shape against your actual x_by() signature)
g2 = sample(c("control", "treatment"), size = 50, replace = TRUE)
KW_TEST(x_by(x, c(g, g2)))
#> Error in x_by(x, c(g, g2)): could not find function "x_by"
```
