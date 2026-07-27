# Cochran Test: Grouped and Blocked (`x_by_b`)

The `x_by_b` implementation tests whether a continuous variable's
distribution differs across the levels of one or more grouping
variables. It accepts one or more grouping variables via
[`x_by_b()`](https://s7-stats.github.io/nullis/reference/x_by_b.md),
running one Cochran test per grouping variable.

## Arguments

`cqtest_def_xby`'s baseline `fn` takes no arguments beyond `.proc`.
Nothing is currently passed through `...` in
[`COCHRAN_QTEST()`](https://s7-stats.github.io/nullis/reference/COCHRAN_QTEST.md).

## Grouped Cochran's test default class

By default, returns a
[class_cq_test](https://s7-stats.github.io/nullis/reference/class_cq_test.md)
object.
