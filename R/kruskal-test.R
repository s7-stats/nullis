#' Kruskal-Wallis H test
#'
#' `KW_TEST()` performs a t-test for one-sample, two-sample, paired, pairwise, or
#' formula-based comparisons. If `KW_TEST` is supplied within the lazy-loaded pipeline,
#' supply `KW_TEST` as a function within i.e. `prepare_test(.test = KW_TEST)` call.
#'
#' @param .var_id A variable mapper `<var_id>`. Currently supports `x_by()`.
#'   When supplied, the test executes immediately.
#' @param .data A data frame. Only used on the standalone path.
#' @param ... Additional arguments passed to the implementation. See the
#'   **Arguments by variable mapper** section for the full list per path.
#'
#' @return A `cld_exec` object (in [statim::conclude()]), a `stat_infer_spec` object, or a
#'   `test_spec` when `.var_id = NULL`. Depending on the implementation you wrote, it returns
#'   any class.
#'
#' @examples
#' set.seed(123)
#' x = rcauchy(50, 1, 1.5)
#' g = sample(letters[1:5], size = 50, replace = TRUE)
#' KW_TEST(x_by(x, g))
#'
#' @export
KW_TEST = statim::HTEST_FN(
    "kw_test",
    defs = list(kwtest_def),
    "Kruskal-Wallis Test"
)

#' Structured result container for Kruskal-Wallis H test
#'
#' @description
#' An S7 class produced by [KW_TEST] pipelines using [statim::x_by] as the
#' variable mapper `<var_id>`.
#'
#' Inherits from [statim::class_stat_infer], so [statim::auto_tidy()] dispatches on it
#' automatically. Downstream packages can use it as a `parent` in
#' `S7::new_class()`.
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
                if (!(value > 0 && value < 1)) {
                    "p value must be between 0 and 1 only. "
                }
            }
        )
    )
)
