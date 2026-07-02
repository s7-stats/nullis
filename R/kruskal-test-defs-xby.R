kwtest_def_xby = statim::stat_define(
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
            fn = function(.proc, p_adj_method = "holm", alpha = 0.05) {
                # curr_data = imap(.proc$data, \(x, i) tibble(group = i, value = x))
                curr_data = .proc$x_data[[1]]
                group_data = vctrs::vec_cast(.proc$group_data[[1]], character())
                p_adj_method = match.arg(
                    p_adj_method,
                    choices = p.adjust.methods
                )

                r = rank(curr_data)
                kw = kruskal_wallis_group(curr_data, group_data)
                h_stat = kw$statistic

                groups = unique(group_data)
                k = length(groups)
                n = tapply(curr_data, group_data, length)
                N = length(curr_data)
                sum_r = tapply(r, group_data, sum)
                mean_r = tapply(r, group_data, mean)

                df_resid = N - k
                s2 = N * (N + 1) / 12
                test_stat = (1 / s2) * sum((sum_r^2 / n)) - 3 * (N + 1)
                pooled_var = s2 * (N - 1 - test_stat) / df_resid

                pairs = combn(groups, 2, simplify = FALSE)
                group_a = purrr::map_chr(pairs, 1)
                group_b = purrr::map_chr(pairs, 2)

                diff = purrr::map2_dbl(
                    group_a,
                    group_b,
                    \(x, y) mean_r[[x]] - mean_r[[y]]
                )

                std_err = purrr::map2_dbl(
                    group_a,
                    group_b,
                    function(x, y) {
                        t_crit = qt(1 - alpha / 2, df_resid)
                        t_crit * sqrt(pooled_var * (1 / n[[x]] + 1 / n[[y]]))
                    }
                )

                t_stat = diff / std_err
                p_value = 2 * pt(abs(t_stat), df_resid, lower.tail = FALSE)
                p_adj = p.adjust(p_value, method = p_adj_method)

                tibble::tibble(
                    comparison = paste(group_a, "and", group_b),
                    diff = diff,
                    std_err = std_err,
                    statistic = t_stat,
                    df = df_resid,
                    p_value = p_value,
                    p_adj = p_adj
                )
            },
            print = function(x, ...) {
                cli::cat_line(cli::rule(left = "Summary", line = "-"), "\n")
                tabstats::table_default(
                    x@data,
                    style_columns = tabstats::td_style(
                        p_value = pval_styler,
                        p_adj = pval_styler
                    ),
                    vb = list(
                        char = "\u2502",
                        after = 1
                    )
                )
                cat("\n\n")

                invisible(x)
            }
        )
    )
)
