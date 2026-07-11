# Structured result container for the Jonckheere-Terpstra test

An S7 class produced by
[JT_TEST](https://s7-stats.github.io/nullis/reference/JT_TEST.md)
pipelines using [statim::x_by](https://rdrr.io/pkg/statim/man/x_by.html)
as the variable mapper `<var_id>`.

Inherits from
[statim::class_stat_infer](https://rdrr.io/pkg/statim/man/class_stat_infer.html),
so
[`statim::auto_tidy()`](https://rdrr.io/pkg/statim/man/auto_tidy.html)
dispatches on it automatically. Downstream packages can use it as a
`parent` in
[`S7::new_class()`](https://rconsortium.github.io/S7/reference/new_class.html).

## Details

Only `vars`, `statistic`, `p_value`, and `alternative` are guaranteed by
every constructor of `class_jt_test`. `z_score`, `mean`, and `variance`
are optional and, when supplied, join the headline summary table on
[`print()`](https://rdrr.io/r/base/print.html); when absent, they're
left out of that table entirely rather than shown as `"Not given"`.
`approximate` and `method` are also optional, and appear in a second
details table, printed as `"Not given"` when a constructor doesn't
supply them. The `x_by` baseline path always populates all eight, since
`jonckheere_terpstra_test()` returns them unconditionally.
