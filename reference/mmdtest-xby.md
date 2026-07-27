# Mood's Median Test: Grouped (`x_by`)

The `x_by` implementation tests whether a continuous variable's
population median differs across the levels of a grouping variable.

## Arguments

`mmdtest_def_xby`'s baseline `fn` takes `.proc` plus an optional
`custom_median` forwarded through `...` in
[`MEDIAN_TEST()`](https://s7-stats.github.io/nullis/reference/MEDIAN_TEST.md).

## Variants

- `"multi"`:

  Runs one Mood's median test per grouping variable when `group` from
  [`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html)
  selects multiple variables. Accepts `custom_median` (applied
  identically to every grouping variable's test) and `display_var`, a
  1-based index (default `1L`, the first grouping variable) choosing
  which grouping variable's contingency table is computed and shown;
  pass `display_var = FALSE` to skip it entirely. Only the selected
  variable's table is retained on the returned object, so re-run with a
  different `display_var` to inspect another one.

## Grouped Mood's Median Test default class

Both `base` and `multi` return a
[class_median_test](https://s7-stats.github.io/nullis/reference/class_median_test.md)
object. `base` always has one grouping variable, so `cont_tab` holds its
one table. `multi` has as many `statistic`/`df`/`p_value` entries as
grouping variables, but `cont_tab` holds only the one `display_var`
selected (or none, if `display_var = FALSE`).

## See also

Other mmdtest-implementations:
[`mmdtest-on`](https://s7-stats.github.io/nullis/reference/mmdtest-on.md)

## Examples

``` r
box::use(
    statim[define_model, prepare, via, conclude]
)

set.seed(123)
x = rcauchy(50, 1, 1.5)
g1 = sample(letters[1:5], size = 50, replace = TRUE)
g2 = sample(c("control", "treatment"), size = 50, replace = TRUE)

MEDIAN_TEST(x_by(x, g1))
#> -- Summary ---------------------------------------------------------------------
#> 
#> ────────────────────────────────
#>   vars  statistic  df  p_value  
#> ────────────────────────────────
#>    g1     3.066    4    0.547   
#> ────────────────────────────────
#> 
#> 
#> -- Contingency Table -----------------------------------------------------------
#> 
#>                            Cross Tabulation: x by y              
#>               ───────────────────────────────────────────────────
#>                                            y              
#>               ───────────────────────────────────────────────────
#>                 x                  d   e    c   a    b    TOTAL  
#>               ───────────────────────────────────────────────────
#>                 > Median (1.04)    4   5    3   5    8     25    
#>               
#>                 <= Median (1.04)   5   6    5   6    3     25    
#>               ───────────────────────────────────────────────────
#>                 TOTAL              9   11   8   11   11    50    
#>               ───────────────────────────────────────────────────
#> 

# show g1's contingency table
define_model(x_by(x, g1)) |>
    prepare(MEDIAN_TEST) |>
    conclude()
#> 
#> == Model ======================================================================= 
#> 
#> Variable Mapper : x_by 
#> Args : x | g1 
#>     x_vars : 1 
#>     by_vars : 1 
#> 
#> == Mood's Median Test ========================================================== 
#> 
#> -- Summary ---------------------------------------------------------------------
#> 
#> ────────────────────────────────
#>   vars  statistic  df  p_value  
#> ────────────────────────────────
#>    g1     3.066    4    0.547   
#> ────────────────────────────────
#> 
#> 
#> -- Contingency Table -----------------------------------------------------------
#> 
#>                            Cross Tabulation: x by y              
#>               ───────────────────────────────────────────────────
#>                                            y              
#>               ───────────────────────────────────────────────────
#>                 x                  d   e    c   a    b    TOTAL  
#>               ───────────────────────────────────────────────────
#>                 > Median (1.04)    4   5    3   5    8     25    
#>               
#>                 <= Median (1.04)   5   6    5   6    3     25    
#>               ───────────────────────────────────────────────────
#>                 TOTAL              9   11   8   11   11    50    
#>               ───────────────────────────────────────────────────
#> 

# more than one grouping variable requires "multi"; shows g2's table
define_model(x_by(x, c(g1, g2))) |>
    prepare(MEDIAN_TEST) |>
    via("multi", display_var = 2L) |>
    conclude()
#> 
#> == Model ======================================================================= 
#> 
#> Variable Mapper : x_by 
#> Args : x | g1, g2 
#>     x_vars : 1 
#>     by_vars : 2 
#> 
#> == Mood's Median Test · multi ================================================== 
#> 
#> -- Summary ---------------------------------------------------------------------
#> 
#> ────────────────────────────────
#>   vars  statistic  df  p_value  
#> ────────────────────────────────
#>    g1     3.066    4    0.547   
#>    g2     5.128    1    0.024   
#> ────────────────────────────────
#> 
#> 
#> -- Contingency Table -----------------------------------------------------------
#> 
#>                            Cross Tabulation: x by y          
#>                   ───────────────────────────────────────────
#>                                         y             
#>                   ───────────────────────────────────────────
#>                     x           treatment   control   TOTAL  
#>                   ───────────────────────────────────────────
#>                     > Median        9         16       25    
#>                   
#>                     <= Median      17          8       25    
#>                   ───────────────────────────────────────────
#>                     TOTAL          26         24       50    
#>                   ───────────────────────────────────────────
#> 
```
