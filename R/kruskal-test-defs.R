kwtest_def = statim::stat_define(
    model_type = x_by,
    impl = statim::agendas(
        base = statim::baseline(fn = function(.proc) {
            kruskal_wallis_group(.proc$x_data[[1]], .proc$group_data[[1]])
        })
    )
)
