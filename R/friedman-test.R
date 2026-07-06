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
