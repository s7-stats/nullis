kwtest_def = statim::stat_define(
    model_type = x_by,
    impl = statim::agendas(
        base = statim::baseline(
            fn = function(.proc) {
                out = kruskal_wallis_group(.proc$x_data[[1]], .proc$group_data[[1]])

                class_kw_test(
                    # vars = names(.proc$group_data),
                    statistic = out$statistic,
                    df = out$df,
                    p_value = out$p_value
                )
            },
            print = function(x, ...) {
                print(x@data@p_value)
            }
        )
    )
)
