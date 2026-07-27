#' @title Cochran Test: Grouped and Blocked (`x_by_b`)
#'
#' @description
#' The `x_by_b` implementation tests whether a continuous variable's
#' distribution differs across the levels of one or more grouping
#' variables. It accepts one or more grouping variables via [x_by_b()],
#' running one Cochran test per grouping variable.
#'
#' @section Arguments:
#' `cqtest_def_xby`'s baseline `fn` takes no arguments beyond `.proc`.
#' Nothing is currently passed through `...` in [COCHRAN_QTEST()].
#'
#' @section Grouped Cochran's test default class:
#' By default, returns a [class_cq_test] object.
#'
#' @keywords internal
#' @name cqtest-xby
#' @family cqtest-implementations
NULL

cqtest_def_xby = statim::stat_define(
    model_type = x_by_b,
    impl = statim::agendas(
        base = statim::baseline(
            fn = function(.proc) {
                x_raw = .proc$x_data[[1]]

                if (is.factor(x_raw)) {
                    if (nlevels(x_raw) != 2) {
                        cli::cli_abort(
                            "Variable `x` must have exactly 2 levels when supplied as a {.cls factor}."
                        )
                    }
                    x_labels = levels(x_raw)
                    x = as.integer(x_raw) - 1L
                } else if (is.numeric(x_raw)) {
                    x_labels = c("0", "1")
                    x = x_raw
                } else {
                    cli::cli_abort(
                        "Variable `x` must be supplied as a {.cls factor} or an {.cls integer}."
                    )
                }

                tests = lapply(.proc$group_data, function(g) {
                    cochran_q_test_group(x, g, .proc$block_data[[1]])
                })

                freq_table = table(" " = .proc$group_data[[1]], Value = x)
                colnames(freq_table) = x_labels

                class_cq_test(
                    vars = names(.proc$group_data),
                    statistic = vapply(tests, \(t) t$statistic, numeric(1)),
                    df = vapply(tests, \(t) t$df, numeric(1)),
                    p_value = vapply(tests, \(t) t$p_value, numeric(1)),
                    freq_table = freq_table,
                    n_groups = vapply(tests, \(t) t$n_groups, integer(1))
                )
            }
        )
    )
)
