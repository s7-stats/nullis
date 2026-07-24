# Friedman Rank Sum Test

`FRIEDMAN_TEST()` tests whether treatment effects differ across k \>= 2
related conditions measured on the same block (e.g. repeated measures on
the same subject, or a randomized block design). It is the rank-based,
distribution-free analogue to a two-way repeated-measures ANOVA without
an interaction term.

## Usage

``` r
FRIEDMAN_TEST(.var_id = NULL, .data = NULL, ...)
```

## Arguments

- .var_id:

  A variable mapper `<var_id>`. Currently supports
  [`x_by_b()`](https://s7-stats.github.io/nullis/reference/x_by_b.md),
  mapping a continuous response, a treatment/grouping variable, and a
  blocking variable.

- .data:

  A data frame. Only used on the standalone path.

- ...:

  Accepted for pipeline consistency. See the **Supported variable
  mapper** section — the current implementation takes no additional
  arguments.

## Value

A `cld_exec` object, or a `test_spec` when `.var_id = NULL`.
`cld_exec@data` is a
[class_friedman_test](https://s7-stats.github.io/nullis/reference/class_friedman_test.md)
object.

## Details

`H0`: there is no difference in treatment effects across blocks. `H1`:
at least one treatment differs from another within blocks.

## Supported variable mapper `<var_id>`s

- [`x_by_b()`](https://s7-stats.github.io/nullis/reference/x_by_b.md):
  blocked Friedman test, single grouping variable only. See details from
  [friedman-xby](https://s7-stats.github.io/nullis/reference/friedman-xby.md).

## See also

[friedman-xby](https://s7-stats.github.io/nullis/reference/friedman-xby.md),
[class_friedman_test](https://s7-stats.github.io/nullis/reference/class_friedman_test.md)

## Examples

``` r
box::use(
    statim[define_model, prepare_test, conclude, tidy]
)

set.seed(123)
x = rnorm(30)
g = rep(letters[1:3], 10)
b = rep(1:10, each = 3)

# Eager Form
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

# Piped/Grammar Syntax Form
out =
    define_model(x_by_b(x, g, b)) |>
    prepare_test(FRIEDMAN_TEST) |>     # Or just `prepare()`
    conclude()

print(out)
#> 
#> == Model ======================================================================= 
#> 
#> Variable Mapper : x_by_b 
#> Args : x | g <=> [ b ] 
#>     x_vars : 1 
#>     by_vars : 1 
#>     block_vars : 1 
#> 
#> == Friedman Rank Sum Test ====================================================== 
#> 
#> -- Summary ---------------------------------------------------------------------
#> 
#> ──────────────────────────
#>   statistic  df  p_value  
#> ──────────────────────────
#>     1.400    2    0.497   
#> ──────────────────────────
#> 
#> 
tidy(out)
#> # A tibble: 1 × 3
#>   statistic    df p_value
#>       <dbl> <dbl>   <dbl>
#> 1      1.40     2   0.497
```
