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
            fn = function(.proc, .ci = 0.95) {
                # curr_data = imap(.proc$data, \(x, i) tibble(group = i, value = x))
                curr_data = .proc$x_data[[1]]
                group_data = .proc$group_data[[1]]

                r = rank(curr_data)
                kw = kruskal_wallis_group(curr_data, group_data)
                h_stat = kw$statistic

                groups = unique(group_data)
                k = length(groups)
                n = tapply(curr_data, group_data, length)
                N = length(curr_data)
                mean_r = tapply(r, group_data, mean)

                df_resid = N - k
                s2 = N * (N + 1) / 12
                pooled_var = s2 * (N - 1 - h_stat) / df_resid

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
                    \(x, y) sqrt(pooled_var * (1 / n[[x]] + 1 / n[[y]]))
                )

                test_stat = diff / std_err
                p_value = 2 * pt(abs(test_stat), df_resid, lower.tail = FALSE)
                p_adj = p.adjust(p_value, method = "holm")

                tibble::tibble(
                    comparison = paste(group_a, "and", group_b),
                    diff = diff,
                    std_err = std_err,
                    statistic = test_stat,
                    df = df_resid,
                    p_value = p_value,
                    p_adj = p_adj
                )
            }
        )
    )
)
