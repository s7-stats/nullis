#' @title Friedman Rank Sum Test: Blocked (`x_by_b`)
#'
#' @description
#' The `x_by_b` implementation tests whether treatment effects differ
#' across k >= 2 related conditions measured on the same block (e.g.
#' repeated measures on the same subject, or a randomized block design).
#' It accepts a continuous response, a treatment/grouping variable, and a
#' blocking variable via [x_by_b()].
#'
#' @section Arguments:
#' `friedman_def_xby`'s baseline `fn` takes no arguments beyond `.proc` —
#' nothing is currently passed through `...` in [FRIEDMAN_TEST()] or
#' [via()].
#'
#' @section Variants:
#' None. `friedman_def_xby` declares only a `base` baseline in its
#' [statim::agendas()] — no `variant()` entries.
#'
#' @section Grouped Friedman default class:
#' By default, returns a [class_friedman_test] object. There is only one
#' `base` baseline — no variants — so there's nothing else to inherit or
#' override.
#'
#' @examples
#' set.seed(123)
#' x = rnorm(30)
#' g = rep(letters[1:3], 10)
#' b = rep(1:10, each = 3)
#' FRIEDMAN_TEST(x_by_b(x, g, b))
#'
#' @keywords internal
#' @name friedman-xby
#' @family friedman-implementations
NULL

friedman_def_xby = statim::stat_define(
    model_type = x_by_b,
    impl = statim::agendas(
        base = statim::baseline(fn = function(.proc) {
            out = friedman_test_group(
                .proc$x_data[[1]],
                .proc$group_data[[1]],
                .proc$block_data[[1]]
            )

            class_friedman_test(
                statistic = out$statistic,
                df = out$df,
                p_value = out$p_value
            )
        })
    )
)
