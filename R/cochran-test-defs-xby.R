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
                tests = lapply(.proc$group_data, function(g) {
                    cochran_q_test_group(
                        .proc$x_data[[1]],
                        g,
                        .proc$block_data[[1]]
                    )
                })

                freq_table = as.matrix(table(
                    .proc$group_data[[1]],
                    .proc$x_data[[1]]
                ))

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
