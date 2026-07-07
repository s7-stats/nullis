# Structured result container for Friedman tests

An S7 class produced by
[FRIEDMAN_TEST](https://s7-stats.github.io/nullis/reference/FRIEDMAN_TEST.md)
pipelines using
[x_by_b](https://s7-stats.github.io/nullis/reference/x_by_b.md) as the
variable mapper `<var_id>`.

Inherits from
[statim::class_stat_infer](https://rdrr.io/pkg/statim/man/class_stat_infer.html),
so
[`statim::auto_tidy()`](https://rdrr.io/pkg/statim/man/auto_tidy.html)
dispatches on it automatically. Downstream packages can use it as a
`parent` in
[`S7::new_class()`](https://rconsortium.github.io/S7/reference/new_class.html).
