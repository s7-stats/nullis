#' @title Mood's Median Test: Grouped (`x_by`)
#'
#' @description
#' The `x_by` implementation tests whether a continuous variable's
#' population median differs across the levels of a grouping variable.
#'
#' @section Arguments:
#' `mmdtest_def_xby`'s baseline `fn` takes `.proc` plus an optional
#' `custom_median` forwarded through `...` in [MEDIAN_TEST()].
#'
#' @section Variants:
#' \describe{
#'   \item{`"multi"`}{Runs one Mood's median test per grouping variable
#'     when `group` from `x_by()` selects multiple variables. Accepts `custom_median`
#'     (applied identically to every grouping variable's test) and
#'     `display_var`, a 1-based index (default `1L`, the first grouping
#'     variable) choosing which grouping variable's contingency table is
#'     computed and shown; pass `display_var = FALSE` to skip it entirely.
#'     Only the selected variable's table is retained on the returned
#'     object, so re-run with a different `display_var` to inspect another
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
#'     conclude()
#'
#' # more than one grouping variable requires "multi"; shows g2's table
#' define_model(x_by(x, c(g1, g2))) |>
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

                if (
                    !isFALSE(display_var) && !(display_var %in% seq_along(vars))
                ) {
                    cli::cli_abort(
                        "{.arg display_var} must be an index between 1 and {length(vars)}, or FALSE to hide the table."
                    )
                }

                tests = lapply(.proc$group_data, function(g) {
                    mood_median_test_group(.proc$x_data[[1]], g, custom_median)
                })

                cont_tab = if (isFALSE(display_var)) {
                    list()
                } else {
                    list(tests[[display_var]]$cont_table)
                }

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
        ),
        pairwise = statim::variant(
            fn = function(.proc) {
                curr_data = .proc$x_data[[1]]
                group_data = vctrs::vec_cast(
                    .proc$group_data[[1]],
                    character()
                )

                groups = unique(group_data)
                k = length(groups)
                if (k < 2) {
                    cli::cli_abort(
                        "At least two groups are required for pairwise comparisons."
                    )
                }
                pairs = utils::combn(groups, 2, simplify = FALSE)
                group_a = purrr::map_chr(pairs, 1)
                group_b = purrr::map_chr(pairs, 2)

                med_test = mood_median_test_group(curr_data, group_data)
                med_tests = purrr::map2(group_a, group_b, function(a, b) {
                    mood_median_test_cpp(
                        list(
                            curr_data[group_data == a],
                            curr_data[group_data == b]
                        )
                    )
                })

                list(
                    test = tibble::tibble(
                        median = med_test$median,
                        n_groups = med_test$n_groups,
                        statistic = med_test$statistic,
                        df = med_test$df,
                        p_value = med_test$p_value
                    ),
                    comps = tibble::tibble(
                        comparison = paste(group_a, "and", group_b),
                        statistic = purrr::map_dbl(med_tests, "statistic"),
                        p_value = purrr::map_dbl(med_tests, "p_value"),
                        median = purrr::map_dbl(med_tests, "median")
                    )
                )
            },
            print = function(x, ...) {
                cli::cat_line(cli::rule(left = "Summary", line = "-"), "\n")
                tabstats::table_default(
                    x@data$test,
                    style_columns = tabstats::td_style(
                        p_value = pval_styler
                    )
                )
                cat("\n\n")
                cli::cat_line(cli::rule(left = "Comparison", line = "-"), "\n")
                tabstats::table_default(
                    x@data$comps,
                    style_columns = tabstats::td_style(
                        p_value = pval_styler
                    ),
                    vb = list(
                        char = "\u2502",
                        after = 1
                    ),
                    digits_by_col = list(
                        median = 2
                    )
                )
                cat("\n\n")

                invisible(x)
            }
        )
    )
)
