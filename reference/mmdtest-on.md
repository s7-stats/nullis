# Mood's Median Test (`on`)

The `on` implementation runs Mood's median test via a compiled C++
backend (`mood_median_test_cpp()`) directly on `.proc$data`, without
going through an R-level
[`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html)
grouping split.

## Arguments

`mmdtest_def_on`'s baseline `fn` takes `.proc` plus optional
`custom_median` and `display_ct`, forwarded through `...` in
[`MEDIAN_TEST()`](https://s7-stats.github.io/nullis/reference/MEDIAN_TEST.md)
or
[`statim::via()`](https://s7-stats.github.io/statim/reference/via.html).
When `.proc$data` holds a single group, `custom_median` should almost
always be supplied — see the note in
[MEDIAN_TEST](https://s7-stats.github.io/nullis/reference/MEDIAN_TEST.md).

## Variants

None. `mmdtest_def_on` declares only a `base` baseline — no `variant()`
entries.

## Mood's Median Test default class

Returns a
[class_median_test](https://s7-stats.github.io/nullis/reference/class_median_test.md)
object, same as `mmdtest_def_xby`'s `base`. `vars` is set to `"on"` —
there is no grouping variable on this path, since `.proc$data` is a
plain list of groups rather than an
[`x_by()`](https://s7-stats.github.io/statim/reference/x_by.html) split.
`cont_tab` holds a single contingency table, wrapped in a one-element
list to match `mmdtest_def_xby`'s convention.

## See also

Other mmdtest-implementations:
[`mmdtest-xby`](https://s7-stats.github.io/nullis/reference/mmdtest-xby.md)

## Examples

``` r
set.seed(123)
x = rcauchy(50, 1, 1.5)
y = rcauchy(50, 3, 1.5)
MEDIAN_TEST(on(x, y))
#> -- Summary ---------------------------------------------------------------------
#> 
#> ────────────────────────────────
#>   vars  statistic  df  p_value  
#> ────────────────────────────────
#>    on    10.240    1   <0.001   
#> ────────────────────────────────
#> 
#> 
#> -- Contingency Table -----------------------------------------------------------
#> 
#>                            Cross Tabulation: x by y      
#>                       ───────────────────────────────────
#>                                           y       
#>                       ───────────────────────────────────
#>                         x               x    y    TOTAL  
#>                       ───────────────────────────────────
#>                         > Median (2)    17   33    50    
#>                       
#>                         <= Median (2)   33   17    50    
#>                       ───────────────────────────────────
#>                         TOTAL           50   50    100   
#>                       ───────────────────────────────────
#> 

# single group against a hypothesized median
MEDIAN_TEST(on(x), custom_median = 1)
#> -- Summary ---------------------------------------------------------------------
#> 
#> ────────────────────────────────
#>   vars  statistic  df  p_value  
#> ────────────────────────────────
#>    on       0      1      1     
#> ────────────────────────────────
#> 
#> 
#> -- Contingency Table -----------------------------------------------------------
#> 
#>                             Cross Tabulation: x by y   
#>                          ──────────────────────────────
#>                                           y     
#>                          ──────────────────────────────
#>                            x               x    TOTAL  
#>                          ──────────────────────────────
#>                            > Median (1)    25    25    
#>                          
#>                            <= Median (1)   25    25    
#>                          ──────────────────────────────
#>                            TOTAL           50    50    
#>                          ──────────────────────────────
#> 
```
