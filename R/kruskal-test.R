#' Kruskal-Wallis H test
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
            validator = function(self) {
                if (!(self > 0 && self < 1)) {
                    "p value must be between 0 and 1 only. "
                }
            }
        )
    )
)
