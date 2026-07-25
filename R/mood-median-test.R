#' Mood's Median Test
#'
#' `MEDIAN_TEST()` tests whether a continuous variable's population median
#' differs across the levels of one or more grouping variables. It works by
#' dichotomizing all observations at the grand median (or a supplied
#' `custom_median`) and running a chi-squared test of independence on the
#' resulting 2xk contingency table. If `MEDIAN_TEST` is supplied within the
#' lazy-loaded pipeline, supply `MEDIAN_TEST` as a function i.e.
#' `prepare_test(.test = MEDIAN_TEST)`.
#'
#' `H0`: all groups share a common population median. `H1`: at least one
#' group's median differs from the others.
#'
#' @param .var_id A variable mapper `<var_id>`. Supports `x_by()` and
#'   `on()`. When supplied, the test executes immediately. `x_by()` with
#'   more than one grouping variable requires `via("multi")`; see the
#'   **Supported variable mapper** section.
#' @param .data A data frame. Only used on the standalone path.
#' @param ... Additional arguments passed to the implementation:
#'   `custom_median` (a hypothesized median to split on, instead of the
#'   sample's own grand median), accepted on every path, and `display_ct`
#'   (show the contingency table in `print()`; default `FALSE`), accepted
#'   on `base` (both `x_by()` and `on()`). `x_by()`'s `multi` variant
#'   instead accepts `display_var` — an index or grouping-variable name
#'   choosing which variable's table to compute and show (`FALSE` to skip
#'   it) — since with several grouping variables there's a choice to make
#'   that `base`/`on()` never have. See the **Supported variable mapper**
#'   section for the full list per path.
#'
#' @return A `cld_exec` object (in [conclude()]), a `stat_infer_spec`
#'   object, or a `test_spec` when `.var_id = NULL`. `mmdtest_def_xby`'s
#'   `base` and `multi`, and `mmdtest_def_on`'s baseline, all return a
#'   [class_median_test] object. On `multi`, every grouping variable's test
#'   runs and its `statistic`/`df`/`p_value`/`median` are kept, but only
#'   the `display_var`-selected variable's contingency table is retained
#'   in `cont_tab` — the others' tables are discarded. On the `on()` path,
#'   `vars` is fixed to `"on"` since there is no grouping variable to
#'   label.
#'
#' @section Supported variable mapper `<var_id>`s:
#' - `x_by()`: grouped Mood's median test. The `base` path handles exactly
#'   one grouping variable; the `multi` variant handles more than one,
#'   running one test per grouping variable. See details from
#'   [mmdtest-xby].
#' - `on()`: one-sample or k-sample Mood's median test via a compiled
#'   backend, run directly on `.proc$data` without an `x_by()` split. See
#'   details from [mmdtest-on].
#'
#' @section A note on `custom_median` for single-group tests:
#' With exactly one group and no `custom_median` supplied, the split point
#' is estimated from that same group's data, so the above/below counts land
#' near a 50/50 split by construction and the test has little power to
#' detect anything. Supply `custom_median` (a hypothesized population
#' median) whenever you're testing a single group.
#'
#' @examples
#' set.seed(123)
#' x = rcauchy(50, 1, 1.5)
#' g = sample(letters[1:5], size = 50, replace = TRUE)
#' MEDIAN_TEST(x_by(x, g))
#'
#' # against a hypothesized median rather than the sample's own
#' MEDIAN_TEST(x_by(x, g), custom_median = 1)
#'
#' @seealso [mmdtest-xby], [mmdtest-on], [class_median_test], [via()], [conclude()]
#'
#' @export
MEDIAN_TEST = statim::HTEST_FN(
    "median_test",
    defs = list(mmdtest_def_xby, mmdtest_def_on),
    "Mood's Median Test"
)

#' Structured S7 container for Mood's median test
#'
#' @description
#' An S7 class produced by [MEDIAN_TEST].
#'
#' Inherits from [statim::class_stat_infer], so [statim::auto_tidy()]
#' dispatches on it automatically. Downstream packages can use it as a
#' `parent` in `S7::new_class()`.
#'
#' @usage NULL
#'
#' @export
class_median_test = S7::new_class(
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
        cont_tab = S7::new_property(
            class = S7::class_list,
            default = quote(list()),
            validator = function(value) {
                if (!all(vapply(value, is.matrix, logical(1)))) {
                    "cont_tab must be a list of integer matrices"
                }
            }
        ),
        median = S7::class_numeric,
        n_groups = S7::class_integer,
        display_ct = S7::new_property(
            class = S7::class_logical,
            default = FALSE
        )
    )
)

S7::method(print, class_median_test) = function(x, ...) {
    .vars = x@vars
    .statistic = x@statistic
    .df = x@df
    .p_value = x@p_value

    stat_out = tibble::tibble(
        vars = .vars,
        statistic = round(.statistic, 4),
        df = as.integer(.df),
        p_value = round(.p_value, 4)
    )

    # ---- Test Summary ----
    cli::cat_line(cli::rule(left = "Summary", line = "-"), "\n")
    tabstats::table_default(
        stat_out,
        style_columns = tabstats::td_style(p_value = pval_styler)
    )
    cat("\n\n")

    # ---- Contingency Table ----
    # base and on() only ever produce a single-element cont_tab, so
    # display_ct is a plain on/off toggle over cont_tab[[1]] — there's
    # nothing to select between here. multi's per-variable selection
    # happens before construction (see mmdtest_def_xby's `multi` variant)
    # and never reaches this class.
    if (x@display_ct) {
        cli::cat_line(cli::rule(left = "Contingency Table", line = "-"), "\n")
        cont_table = x@cont_tab[[1]]
        rownames(cont_table) = c(
            paste0("> Median ", "(", round(x@median, digits = 2), ")"),
            paste0("<= Median ", "(", round(x@median, digits = 2), ")")
        )
        tabstats::cross_table(
            cont_table,
            layout = FALSE,
            expected = FALSE,
            center_table = TRUE
        )
        cat("\n")
    }

    invisible(x)
}

S7::method(auto_tidy, class_median_test) = function(x, ...) {
    tibble::tibble(
        vars = x@vars,
        median = x@median,
        statistic = x@statistic,
        df = x@df,
        p_value = x@p_value
    )
}
