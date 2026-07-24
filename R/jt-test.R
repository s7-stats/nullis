#' Jonckheere-Terpstra Test
#'
#' `JT_TEST()` tests whether the distribution of a continuous variable
#' shifts monotonically across the *ordered* levels of a grouping
#' variable. It is a trend-sensitive alternative to Kruskal-Wallis: where
#' Kruskal-Wallis only asks whether the groups differ, Jonckheere-Terpstra
#' asks whether they differ in a consistent direction. If `JT_TEST` is
#' supplied within the lazy-loaded pipeline, supply `JT_TEST` as a function
#' i.e. `prepare_test(.test = JT_TEST)`.
#'
#' `H0`: all groups come from the same distribution. `H1`: the groups are
#' stochastically ordered in the direction given by `alternative`.
#'
#' @param .var_id A variable mapper `<var_id>`. Currently supports `x_by()`.
#'   When supplied, the test executes immediately. If `.var_id` maps
#'   multiple grouping variables, one Jonckheere-Terpstra test runs per
#'   grouping variable against the same continuous variable. Each grouping
#'   variable must be an ordered factor — see [jttest-xby].
#' @param .data A data frame. Only used on the standalone path.
#' @param ... Additional arguments passed to the implementation, including
#'   `alternative` and `approximate`. See [jttest-xby] for the full list.
#'
#' @return A `cld_exec` object (in [conclude()]), a `stat_infer_spec`
#'   object, or a `test_spec` when `.var_id = NULL`. `jttest_def_xby`
#'   always returns a [class_jt_test] object.
#'
#' @section Supported variable mapper `<var_id>`s:
#' - `x_by()`: grouped Jonckheere-Terpstra test against an ordered
#'   grouping variable. See details from [jttest-xby].
#'
#' @examples
#' set.seed(123)
#' x = rcauchy(50, 1, 1.5)
#' g = factor(
#'     sample(letters[1:3], size = 50, replace = TRUE),
#'     levels = c("a", "b", "c"),
#'     ordered = TRUE
#' )
#' JT_TEST(x_by(x, g))
#'
#' # direction of the trend matters here, unlike Kruskal-Wallis
#' JT_TEST(x_by(x, g), alternative = "increasing")
#'
#' # multiple grouping variables -> one test per grouping variable
#' # (confirm this call shape against your actual x_by() signature)
#' g2 = factor(
#'     sample(c("low", "high"), size = 50, replace = TRUE),
#'     levels = c("low", "high"),
#'     ordered = TRUE
#' )
#' JT_TEST(x_by(x, c(g, g2)))
#'
#' @seealso [jttest-xby], [class_jt_test], [via()], [conclude()]
#'
#' @export
JT_TEST = statim::HTEST_FN(
    "jt_test",
    defs = list(jttest_def_xby),
    "Jonckheere-Terpstra Test"
)

#' Structured result container for the Jonckheere-Terpstra test
#'
#' @description
#' An S7 class produced by [JT_TEST] pipelines using [statim::x_by] as the
#' variable mapper `<var_id>`.
#'
#' Inherits from [statim::class_stat_infer], so [statim::auto_tidy()]
#' dispatches on it automatically. Downstream packages can use it as a
#' `parent` in `S7::new_class()`.
#'
#' @usage NULL
#'
#' @details
#' Only `vars`, `statistic`, `p_value`, and `alternative` are guaranteed
#' by every constructor of `class_jt_test`. `z_score`, `mean`, and
#' `variance` are optional and, when supplied, join the headline summary
#' table on `print()`; when absent, they're left out of that table
#' entirely rather than shown as `"Not given"`. `approximate` and
#' `method` are also optional, and appear in a second details table,
#' printed as `"Not given"` when a constructor doesn't supply them. The
#' `x_by` baseline path always populates all eight, since
#' `jonckheere_terpstra_test()` returns them unconditionally.
#'
#' @export
class_jt_test = S7::new_class(
    "jt_test",
    parent = statim::class_stat_infer,
    properties = list(
        # ---- Required: guaranteed by any JT result ----
        vars = S7::class_character,
        statistic = S7::class_numeric,
        p_value = S7::new_property(
            class = S7::class_numeric,
            validator = function(value) {
                if (anyNA(value)) {
                    return("p_value must not contain missing values.")
                }
                if (any(value <= 0 | value >= 1)) {
                    "p_value must be between 0 and 1."
                }
            }
        ),
        alternative = S7::class_character,

        # ---- Optional: joins the headline table when supplied ----
        z_score = S7::new_property(
            class = S7::new_union(S7::class_numeric, S7::class_missing),
            default = NULL
        ),
        mean = S7::new_property(
            class = S7::new_union(S7::class_numeric, S7::class_missing),
            default = NULL
        ),
        variance = S7::new_property(
            class = S7::new_union(S7::class_numeric, S7::class_missing),
            default = NULL
        ),

        # ---- Optional: printed as "Not given" in the details table ----
        approximate = S7::new_property(
            class = S7::new_union(S7::class_logical, S7::class_missing),
            default = NULL
        ),
        method = S7::new_property(
            class = S7::new_union(S7::class_character, S7::class_missing),
            default = NULL
        )
    )
)

S7::method(print, class_jt_test) = function(x, ...) {
    stat_out = tibble::tibble(
        vars = x@vars,
        statistic = round(x@statistic, 4),
        p_value = round(x@p_value, 4),
        alternative = x@alternative
    )
    if (length(x@z_score) > 0) {
        stat_out = tibble::add_column(
            stat_out,
            z_score = round(x@z_score, 4),
            .after = "statistic"
        )
    }
    if (!is.null(x@mean)) {
        stat_out = tibble::add_column(
            stat_out,
            mean = round(x@mean, 4),
            .after = "vars"
        )
    }
    if (!is.null(x@variance)) {
        stat_out = tibble::add_column(
            stat_out,
            variance = round(x@variance, 4),
            .before = "statistic"
        )
    }

    cli::cat_line(cli::rule(left = "Summary", line = "-"), "\n")
    tabstats::table_default(
        stat_out,
        style_columns = tabstats::td_style(p_value = pval_styler)
    )
    cat("\n\n")

    not_given = "Not given"

    detail_stats = c(
        paste0(x@vars, ": Approximate"),
        paste0(x@vars, ": Method")
    )
    detail_values = c(
        if (is.null(x@approximate)) {
            rep(not_given, length(x@vars))
        } else {
            as.character(x@approximate)
        },
        if (is.null(x@method)) rep(not_given, length(x@vars)) else x@method
    )

    details = tibble::tibble(statistic = detail_stats, value = detail_values)

    cli::cat_line(cli::rule(left = "Details", line = "-"), "\n")
    tabstats::table_summary(
        details,
        center_table = TRUE,
        l = nrow(details),
        style = tabstats::sm_style(sep = ":  ")
    )
    cat("\n\n")

    invisible(x)
}

S7::method(auto_tidy, class_jt_test) = function(x, ...) {
    tibble::tibble(
        vars = x@vars,
        statistic = x@statistic,
        p_value = x@p_value,
        alternative = x@alternative,
        z_score = x@z_score,
        mean = x@mean,
        variance = x@variance,
        approximate = x@approximate,
        method = x@method
    )
}
