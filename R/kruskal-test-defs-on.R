#' @title Kruskal-Wallis Test: One-Sample (`on`)
#'
#' @description
#' The `on` implementation runs a Kruskal-Wallis test via a compiled C++
#' backend (`kruskal_wallis_cpp()`) directly on `.proc$data`, without going
#' through an R-level `x_by()` grouping split.
#'
#' @section Arguments:
#' `kwtest_def_on`'s baseline `fn` takes no arguments beyond `.proc` —
#' nothing is passed through `...` in [KW_TEST()] or [via()] for this path.
#'
#' @section Variants:
#' None. `kwtest_def_on` declares only a `base` baseline — no `variant()`
#' entries.
#'
#' @section One-sample Kruskal-Wallis default class:
#' No S7 wrapper. The baseline returns whatever `kruskal_wallis_cpp()`
#' returns, unwrapped, a plain list with `statistic`, `df`, `p_value`.
#' Unlike `x_by()`, this path does **not** return [class_kw_test]. It has
#' its own `print` method (a `tibble` with `H Statistic`,
#' `Degrees of Freedom`, `p-value` columns) and its own registered
#' [statim::making_tidy()] entry (`tibble::as_tibble(.x@data)`), rather
#' than inheriting [statim::auto_tidy()] from `class_kw_test`.
#'
#' @examples
#' set.seed(123)
#' x = rcauchy(50, 1, 1.5)
#' y = rcauchy(50, 3, 1.5)
#' KW_TEST(on(x, y))
#'
#' @keywords internal
#' @name kwtest-on
#' @family kwtest-implementations
NULL

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
                    style_columns = tabstats::td_style("p-value" = pval_styler)
                )
                cat("\n")
            }
        )
    )
)
