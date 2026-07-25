# Structured S7 container for Mood's median test

An S7 class produced by
[MEDIAN_TEST](https://s7-stats.github.io/nullis/reference/MEDIAN_TEST.md).

Inherits from
[statim::class_stat_infer](https://s7-stats.github.io/statim/reference/class_stat_infer.html),
so
[`statim::auto_tidy()`](https://s7-stats.github.io/statim/reference/auto_tidy.html)
dispatches on it automatically. Downstream packages can use it as a
`parent` in
[`S7::new_class()`](https://rconsortium.github.io/S7/reference/new_class.html).
