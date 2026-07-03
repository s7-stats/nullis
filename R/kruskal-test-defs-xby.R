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
            fn = function(.proc, p_adj_method = "holm") {
                # curr_data = imap(.proc$data, \(x, i) tibble(group = i, value = x))
                curr_data = .proc$x_data[[1]]
                group_data = vctrs::vec_cast(.proc$group_data[[1]], character())
                p_adj_method = match.arg(
                    p_adj_method,
                    choices = p.adjust.methods
                )

                groups = unique(group_data)
                k = length(groups)
                if (k < 2) {
                    cli::cli_abort(
                        "At least two groups are required for pairwise comparisons."
                    )
                }

                x_rank = rank(curr_data)
                r_bar = tapply(x_rank, group_data, mean)
                n = tapply(curr_data, group_data, length)
                N = length(curr_data)

                # tie_sizes = table(x_rank)
                tie_sizes = tabulate(x_rank)
                tie_correction = sum(tie_sizes^3 - tie_sizes) / (12 * (N - 1))
                rank_var = N * (N + 1) / 12 - tie_correction

                pairs = utils::combn(groups, 2, simplify = FALSE)
                group_a = purrr::map_chr(pairs, 1)
                group_b = purrr::map_chr(pairs, 2)

                diff = purrr::map2_dbl(
                    group_a,
                    group_b,
                    function(x, y) {
                        r_bar[[x]] - r_bar[[y]]
                    }
                )
                std_err = purrr::map2_dbl(
                    group_a,
                    group_b,
                    function(x, y) {
                        sqrt(rank_var * (1 / n[[x]] + 1 / n[[y]]))
                    }
                )

                statistic = diff / std_err
                p_value = 2 * pnorm(abs(statistic), lower.tail = FALSE)
                p_adj = p.adjust(p_value, method = p_adj_method)

                list(
                    kw_test = kruskal_wallis_group(
                        .proc$x_data[[1]],
                        .proc$group_data[[1]]
                    ),
                    comps = tibble::tibble(
                        comparison = paste(group_a, "and", group_b),
                        diff = diff,
                        std_err = std_err,
                        statistic = statistic,
                        p_value = p_value,
                        p_adj = p_adj
                    )
                )
            },
            print = function(x, ...) {
                cli::cat_line(cli::rule(left = "Summary", line = "-"), "\n")
                tabstats::table_default(
                    tibble::as_tibble(x@data$kw_test),
                    style_columns = tabstats::td_style(
                        p_value = pval_styler
                    )
                )
                cat("\n\n")
                cli::cat_line(cli::rule(left = "Comparison", line = "-"), "\n")
                tabstats::table_default(
                    x@data$comps,
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
