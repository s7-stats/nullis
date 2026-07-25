#' @title Mood's Median Test: Grouped (`x_by`)
#'
#' @description
#' The `x_by` implementation tests whether a continuous variable's
#' population median differs across the levels of a grouping variable.
#'
#' @section Arguments:
#' `mmdtest_def_xby`'s baseline `fn` takes `.proc` plus an optional
#' `custom_median` and `display_ct`, forwarded through `...` in
#' [MEDIAN_TEST()] or [via()]. The baseline requires exactly one grouping
#' variable in `.proc$group_data` and errors otherwise, pointing to the
#' `multi` variant.
#'
#' @section Variants:
#' \describe{
#'   \item{`"multi"`}{Runs one Mood's median test per grouping variable
#'     when `.proc$group_data` holds more than one. Accepts `custom_median`
#'     (applied identically to every grouping variable's test) and
#'     `display_var` — a 1-based index (default `1L`, the first grouping
#'     variable) choosing which grouping variable's contingency table is
#'     computed and shown; pass `display_var = FALSE` to skip it entirely.
#'     Only the selected variable's table is retained on the returned
#'     object — re-run with a different `display_var` to inspect another
#'     one.}
#' }
#'
#' @section Grouped Mood's Median Test default class:
#' Both `base` and `multi` return a [class_median_test] object.
#' `base` always has one grouping variable, so `cont_tab` holds its one
#' table. `multi` has as many `statistic`/`df`/`p_value` entries as
#' grouping variables, but `cont_tab` holds only the one `display_var`
#' selected (or none, if `display_var = FALSE`).
#'
#' @examples
#' box::use(
#'     statim[define_model, prepare, via, conclude]
#' )
#'
#' set.seed(123)
#' x = rcauchy(50, 1, 1.5)
#' g1 = sample(letters[1:5], size = 50, replace = TRUE)
#' g2 = sample(c("control", "treatment"), size = 50, replace = TRUE)
#'
#' MEDIAN_TEST(x_by(x, g1))
#'
#' # show g1's contingency table
#' define_model(x_by(x, g1)) |>
#'     prepare(MEDIAN_TEST) |>
#'     via("base", display_ct = TRUE) |>
#'     conclude()
#'
#' # more than one grouping variable requires "multi"; shows g2's table
#' define_model(x_by(x, g1, g2)) |>
#'     prepare(MEDIAN_TEST) |>
#'     via("multi", display_var = 2L) |>
#'     conclude()
#'
#' @keywords internal
#' @name mmdtest-xby
#' @family mmdtest-implementations
NULL

mmdtest_def_xby = statim::stat_define(
    model_type = x_by,
    impl = statim::agendas(
        base = statim::baseline(
            fn = function(.proc, custom_median = NULL) {
                if (length(.proc$group_data) != 1) {
                    cli::cli_abort(
                        "{.fn base} supports exactly one grouping variable. Use {.code via('multi')} for more than one."
                    )
                }

                test = mood_median_test_group(
                    .proc$x_data[[1]],
                    .proc$group_data[[1]],
                    custom_median
                )

                class_median_test(
                    vars = names(.proc$group_data),
                    statistic = test$statistic,
                    df = test$df,
                    p_value = test$p_value,
                    cont_tab = list(test$cont_table),
                    median = test$median,
                    n_groups = test$n_groups,
                    display_ct = TRUE
                )
            }
        ),
        multi = statim::variant(
            fn = function(.proc, custom_median = NULL, display_var = 1L) {
                if (length(.proc$group_data) < 2) {
                    cli::cli_abort(
                        "{.fn multi} requires more than one grouping variable. Use {.code via('base')} for a single one."
                    )
                }

                vars = names(.proc$group_data)

                if (!isFALSE(display_var) && !(display_var %in% seq_along(vars))) {
                    cli::cli_abort(
                        "{.arg display_var} must be an index between 1 and {length(vars)}, or FALSE to hide the table."
                    )
                }

                tests = lapply(.proc$group_data, function(g) {
                    mood_median_test_group(.proc$x_data[[1]], g, custom_median)
                })

                cont_tab = if (isFALSE(display_var)) list() else list(tests[[display_var]]$cont_table)

                class_median_test(
                    vars = vars,
                    statistic = vapply(tests, \(t) t$statistic, numeric(1)),
                    df = vapply(tests, \(t) t$df, numeric(1)),
                    p_value = vapply(tests, \(t) t$p_value, numeric(1)),
                    cont_tab = cont_tab,
                    median = vapply(tests, \(t) t$median, numeric(1)),
                    n_groups = vapply(tests, \(t) t$n_groups, integer(1)),
                    display_ct = !isFALSE(display_var)
                )
            }
        )
    )
)
