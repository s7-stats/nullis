kwtest_def = statim::stat_define(
    model_type = x_by,
    impl = statim::agendas(
        base = statim::baseline(
            fn = function(.proc) {
                tests = lapply(.proc$group_data, function(g) {
                    kruskal_wallis_group(.proc$x_data[[1]], g)
                })

                class_kw_test(
                    vars = names(.proc$group_data),
                    statistic = vapply(tests, \(t) t$statistic, numeric(1)),
                    df = vapply(tests, \(t) t$df, numeric(1)),
                    p_value = vapply(tests, \(t) t$p_value, numeric(1))
                )
            }
        ),
        pairwise = statim::variant(
            fn = function(.proc) {
                curr_data = imap(.proc$data, \(x, i) tibble(group = i, value = x))
            }
        )
    )
)
