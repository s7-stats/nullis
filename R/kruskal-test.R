#' Kruskal-Wallis rank sum test
#'
#' `KW_TEST()` tests whether the distribution of a continuous variable
#' differs across the levels of one or more grouping variables. It is the
#' rank-based, distribution-free analogue to one-way ANOVA. If `KW_TEST` is
#' supplied within the lazy-loaded pipeline, supply `KW_TEST` as a function
#' i.e. `prepare_test(.test = KW_TEST)`.
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
#'   **Arguments by variable mapper** section for the full list per path.
#'
#' @return A `cld_exec` object (in [statim::conclude()]), a `stat_infer_spec`
#'   object, or a `test_spec` when `.var_id = NULL`. Depending on the
#'   implementation you wrote, it returns any class.
#'
#' @examples
#' set.seed(123)
#' x = rcauchy(50, 1, 1.5)
#' g = sample(letters[1:5], size = 50, replace = TRUE)
#' KW_TEST(x_by(x, g))
#'
#' # multiple grouping variables -> one test per grouping variable
#' # (confirm this call shape against your actual x_by() signature)
#' g2 = sample(c("control", "treatment"), size = 50, replace = TRUE)
#' KW_TEST(x_by(x, c(g, g2)))
#'
#' @export
KW_TEST = statim::HTEST_FN(
    "kw_test",
    defs = list(kwtest_def),
    "Kruskal-Wallis Test"
)

#' Structured result container for Kruskal-Wallis test
#'
#' @description
#' An S7 class produced by [KW_TEST] pipelines using [statim::x_by] as the
#' variable mapper `<var_id>`.
#'
#' Inherits from [statim::class_stat_infer], so [statim::auto_tidy()]
#' dispatches on it automatically. Downstream packages can use it as a
#' `parent` in `S7::new_class()`.
#'
#' @usage NULL
#'
#' @export
class_kw_test = S7::new_class(
    "kw_test",
    parent = statim::class_stat_infer,
    properties = list(
        vars = S7::class_character,
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

S7::method(print, class_kw_test) = function(x, ...) {
    .vars = x@vars
    .statistic = x@statistic
    .df = x@df
    .p_value = x@p_value

    pval_styler = function(x) {
        x_num = suppressWarnings(as.numeric(x$value))
        if (is.na(x_num) || x_num > 0.05) {
            cli::style_italic(x$value)
        } else if (x_num > 0.01) {
            cli::col_red(x$value)
        } else {
            cli::style_bold("<0.001")
        }
    }

    stat_out = tibble::tibble(
        vars = .vars,
        statistic = round(.statistic, 4),
        df = as.integer(.df),
        p_value = round(.p_value, 4)
    )

    cli::cat_line(cli::rule(left = "Summary", line = "-"), "\n")
    tabstats::table_default(
        stat_out,
        style_columns = tabstats::td_style(p_value = pval_styler)
    )
    cat("\n\n")

    invisible(x)
}

S7::method(auto_tidy, class_kw_test) = function(x, ...) {
    tibble::tibble(
        vars = x@vars,
        statistic = x@statistic,
        df = x@df,
        p_value = x@p_value
    )
}
