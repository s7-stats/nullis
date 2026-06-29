#' Friedman Rank Sum Test
#'
#' @export
FRIEDMAN_TEST = statim::HTEST_FN(
    "friedman_test",
    defs = list(friedman_def_xby),
    "Friedman Rank Sum Test"
)
