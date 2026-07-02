kwtest_def_on = statim::stat_define(
    model_type = on,
    impl = statim::agendas(
        base = statim::baseline(
            fn = function(.proc) {
                kruskal_wallis_cpp(.proc$data)
            },
            print = function(x, ...) {
                out = x@data

                df_res = tibble::tibble(
                    `H Statistic` = out$statistic,
                    `Degrees of Freedom` = out$df,
                    `p-value` = out$p_value
                )

                tabstats::table_default(
                    df_res,
                    style_columns = tabstats::td_style("p value" = pval_styler)
                )
                cat("\n")
            }
        )
    )
)
