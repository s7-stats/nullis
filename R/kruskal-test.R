#' Kruskal-Wallis H test
#'
#' @export
KW_TEST = statim::HTEST_FN(
    "kw_test",
    defs = list(kwtest_def),
    "Kruskal-Wallis Test"
)

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
