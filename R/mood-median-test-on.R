#' @title Mood's Median Test (`on`)
#'
#' @description
#' The `on` implementation runs Mood's median test via a compiled C++
#' backend (`mood_median_test_cpp()`) directly on `.proc$data`, without
#' going through an R-level `x_by()` grouping split.
#'
#' @section Arguments:
#' `mmdtest_def_on`'s baseline `fn` takes `.proc` plus optional
#' `custom_median` and `display_ct`, forwarded through `...` in
#' [MEDIAN_TEST()] or [via()]. When `.proc$data` holds a single group,
#' `custom_median` should almost always be supplied — see the note in
#' [MEDIAN_TEST].
#'
#' @section Variants:
#' None. `mmdtest_def_on` declares only a `base` baseline — no `variant()`
#' entries.
#'
#' @section Mood's Median Test default class:
#' Returns a [class_median_test] object, same as `mmdtest_def_xby`'s
#' `base`. `vars` is set to `"on"` — there is no grouping variable on this
#' path, since `.proc$data` is a plain list of groups rather than an
#' `x_by()` split. `cont_tab` holds a single contingency table, wrapped in
#' a one-element list to match `mmdtest_def_xby`'s convention.
#'
#' @examples
#' set.seed(123)
#' x = rcauchy(50, 1, 1.5)
#' y = rcauchy(50, 3, 1.5)
#' MEDIAN_TEST(on(x, y))
#'
#' # single group against a hypothesized median
#' MEDIAN_TEST(on(x), custom_median = 1)
#'
#' @keywords internal
#' @name mmdtest-on
#' @family mmdtest-implementations
NULL

mmdtest_def_on = statim::stat_define(
    model_type = on,
    impl = statim::agendas(
        base = statim::baseline(
            fn = function(.proc, custom_median = NULL, display_ct = TRUE) {
                test = mood_median_test_cpp(.proc$data, custom_median)

                class_median_test(
                    vars = "on",
                    statistic = test$statistic,
                    df = test$df,
                    p_value = test$p_value,
                    cont_tab = list(test$cont_table),
                    median = test$median,
                    n_groups = as.integer(test$n_groups),
                    display_ct = display_ct
                )
            }
        )
    )
)
