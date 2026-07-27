#' Cochran's Q test
#'
#' `COCHRAN_QTEST()` tests whether the distribution of a continuous variable
#' differs across the levels of one or more grouping variables. It is the
#' rank-based, distribution-free analogue to one-way ANOVA. If `COCHRAN_QTEST` is
#' supplied within the lazy-loaded pipeline, supply `COCHRAN_QTEST` as a function
#' i.e. `prepare_test(.test = COCHRAN_QTEST)`.
#'
#' `H0`: all samples come from the same distribution (equal medians, under
#' the assumption of equal shape). `H1`: at least one sample is
#' stochastically greater than another.
#'
#' @param .var_id A variable mapper `<var_id>`. Currently supports `x_by()`.
#'   When supplied, the test executes immediately. If `.var_id` maps
#'   multiple grouping variables, one Kruskal-Wallis test runs per grouping
#'   variable against the same continuous variable.
#' @param .data A data frame. Only used on the standalone path.
#' @param ... Additional arguments passed to the implementation. See the
#'   **Supported variable mapper** section for the full list per path.
#'
#' @return A `cld_exec` object (in [conclude()]), a `stat_infer_spec`
#'   object, or a `test_spec` when `.var_id = NULL`. `cqtest_def_xby`'s
#'   baseline returns a [class_cq_test] object by default; its `pairwise`
#'   variant instead returns a plain list (`COCHRAN_QTEST`, `comps`) with its own
#'   `print` method. `cqtest_def_on`'s baseline returns a plain list
#'   (`statistic`, `df`, `p_value`) with its own `print` method — neither
#'   path shares a class between them.
#'
#' @section Supported variable mapper `<var_id>`s:
#' - `x_by()`: grouped Kruskal-Wallis test, with optional pairwise
#'   comparisons. See details from [cqtest-xby].
#'
#' @examples
#' set.seed(123)
#' x = sample(0:1, 45, replace = TRUE)
#' treatment = gl(3, 1, 45, labels = c("A", "B", "C"))
#' block = gl(5, 3, 45, labels = 1:5)
#' COCHRAN_QTEST(x_by_b(x, treatment, block))
#'
#' @seealso [cqtest-xby], [class_cq_test], [via()], [conclude()]
#'
#' @export
COCHRAN_QTEST = statim::HTEST_FN(
    "cq_test",
    defs = list(cqtest_def_xby),
    "Cochran's Q Test"
)

#' Structured S7 container for Cochran's Q test
#'
#' @description
#' An S7 class produced by [COCHRAN_QTEST].
#'
#' Inherits from [statim::class_stat_infer], so [statim::auto_tidy()]
#' dispatches on it automatically. Downstream packages can use it as a
#' `parent` in `S7::new_class()`.
#'
#' @usage NULL
#'
#' @export
class_cq_test = S7::new_class(
    "median_test",
    parent = statim::class_stat_infer,
    properties = list(
        vars = S7::class_character,
        statistic = S7::class_numeric,
        df = S7::class_numeric,
        p_value = S7::new_property(
            class = S7::class_numeric,
            validator = function(value) {
                if (any(value < 0 | value > 1)) {
                    "p_value must be between 0 and 1."
                }
            }
        ),
        freq_table = S7::new_property(
            class = S7::class_any,
            default = quote(matrix(nrow = 0, ncol = 2)),
            validator = function(value) {
                if (!is.matrix(value)) {
                    "freq_table must be a matrix"
                }
            }
        ),
        n_groups = S7::class_integer
    )
)

S7::method(print, class_cq_test) = function(x, ...) {
    vars = x@vars
    n_groups = x@n_groups
    statistic = x@statistic
    df = x@df
    p_value = x@p_value

    stat_out = tibble::tibble(
        vars = vars,
        n_groups = n_groups,
        `Q statistic` = round(statistic, 4),
        df = as.integer(df),
        p_value = round(p_value, 4)
    )

    # ---- Test Summary ----
    cli::cat_line(cli::rule(left = "Summary", line = "-"), "\n")
    tabstats::table_default(
        stat_out,
        style_columns = tabstats::td_style(p_value = pval_styler)
    )
    cat("\n\n")

    # ---- Frequency Table ----
    if (nrow(x@freq_table) > 0) {
        cli::cat_line(cli::rule(left = "Frequency Table", line = "-"), "\n")

        tabstats::cross_table(
            x@freq_table,
            layout = FALSE,
            expected = FALSE,
            center_table = TRUE
        )
        cat("\n")
    }

    invisible(x)
}

S7::method(auto_tidy, class_cq_test) = function(x, ...) {
    tibble::tibble(
        vars = x@vars,
        n_groups = x@n_groups,
        statistic = x@statistic,
        df = x@df,
        p_value = x@p_value
    )
}
