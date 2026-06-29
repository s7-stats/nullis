#' Kruskal-Wallis H test
#'
#' @export
KW_TEST = statim::HTEST_FN(
    "kw_test",
    defs = list(kwtest_def),
    "Kruskal-Wallis Test"
)
