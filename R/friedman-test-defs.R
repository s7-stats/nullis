friedman_def_xby = statim::stat_define(
    model_type = x_by_b,
    impl = statim::agendas(
        base = statim::baseline(fn = function(.proc) {
            friedman_test_group(
                .proc$x_data[[1]],
                .proc$group_data[[1]],
                .proc$block_data[[1]]
            )
        })
    )
)
