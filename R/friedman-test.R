#' Friedman Rank Sum Test
#'
#' `FRIEDMAN_TEST()` tests whether treatment effects differ across k >= 2
#' related conditions measured on the same block (e.g. repeated measures on
#' the same subject, or a randomized block design). It is the rank-based,
#' distribution-free analogue to a two-way repeated-measures ANOVA without
#' an interaction term.
#'
#' `H0`: there is no difference in treatment effects across blocks.
#' `H1`: at least one treatment differs from another within blocks.
#'
#' @param .var_id A variable mapper `<var_id>`. Currently supports
#'   `x_by_b()`, mapping a continuous response, a treatment/grouping
#'   variable, and a blocking variable. The test executes immediately when
#'   supplied. Only a single grouping variable is read
#'   (`.proc$group_data[[1]]`) — additional grouping variables are silently
#'   ignored, not looped over like in [KW_TEST].
#' @param .data A data frame. Only used on the standalone path.
#' @param ... Accepted for pipeline consistency. See the **Supported
#'   variable mapper** section — the current implementation takes no
#'   additional arguments.
#'
#' @return A `cld_exec` object, or a `test_spec` when `.var_id = NULL`.
#'   `cld_exec@data` is a plain list with `statistic`, `df`, and `p_value`.
#'
#' @section Supported variable mapper `<var_id>`s:
#' - `x_by_b()`: blocked Friedman test, single grouping variable only. See
#'   details from [friedman-xby].
#'
#' @examples
#' set.seed(123)
#' x = rnorm(30)
#' g = rep(letters[1:3], 10)
#' b = rep(1:10, each = 3)
#' FRIEDMAN_TEST(x_by_b(x, g, b))
#'
#' @seealso [friedman-xby]
#'
#' @export
FRIEDMAN_TEST = statim::HTEST_FN(
    "friedman_test",
    defs = list(friedman_def_xby),
    "Friedman Rank Sum Test"
)

#' Structured result container for Friedman tests
#'
#' @description
#' An S7 class produced by [FRIEDMAN_TEST] pipelines using
#' [x_by_b] as the variable mapper `<var_id>`.
#'
#' Inherits from [statim::class_stat_infer], so [statim::auto_tidy()]
#' dispatches on it automatically. Downstream packages can use it as a
#' `parent` in `S7::new_class()`.
#'
#' @usage NULL
#'
#' @export
class_friedman_test = S7::new_class(
    "friedman_test",
    parent = statim::class_stat_infer,
    properties = list(
        statistic = S7::class_numeric,
        df = S7::class_numeric,
        p_value = S7::new_property(
            class = S7::class_numeric,
            validator = function(value) {
                if (any(value <= 0 | value >= 1)) {
                    "p_value must be between 0 and 1 only."
                }
            }
        )
    )
)

S7::method(print, class_friedman_test) = function(x, ...) {
    vars = x@statistic
    df = x@df
    p_value = x@p_value

    stat_out = tibble::tibble(
        statistic = round(vars, 4),
        df = as.integer(df),
        p_value = round(p_value, 4)
    )

    cli::cat_line(cli::rule(left = "Summary", line = "-"), "\n")
    tabstats::table_default(
        stat_out,
        style_columns = tabstats::td_style(p_value = pval_styler)
    )
    cat("\n\n")

    invisible(x)
}

S7::method(auto_tidy, class_friedman_test) = function(x, ...) {
    tibble::tibble(
        statistic = x@statistic,
        df = x@df,
        p_value = x@p_value
    )
}
