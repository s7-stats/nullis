#' @title Jonckheere-Terpstra Test: Grouped (`x_by`)
#'
#' @description
#' The `x_by` implementation tests whether a continuous variable trends
#' monotonically across the levels of one or more grouping variables. It
#' accepts one or more grouping variables via [x_by()], running one
#' Jonckheere-Terpstra test per grouping variable.
#'
#' @section Arguments:
#' `jttest_def_xby`'s baseline `fn` passes these straight through to the
#' compiled `jonckheere_terpstra_test()` C++ backend:
#' \describe{
#'   \item{`alternative`}{One of `"two.sided"`, `"increasing"`, or
#'     `"decreasing"`. Default `"two.sided"`. Invalid values are rejected
#'     by the backend itself.}
#'   \item{`approximate`}{Force the normal approximation instead of the
#'     exact null distribution. Default `FALSE`. The backend only uses the
#'     exact distribution when there are 50 or fewer observations and this
#'     is `FALSE`.}
#' }
#'
#' @section Grouping requirement:
#' Every grouping variable passed to [x_by()] must be an **ordered
#' factor**. Jonckheere-Terpstra tests a *directional* trend across group
#' levels — unlike Kruskal-Wallis, group order changes what the test
#' means, so an unordered factor or plain character vector is refused
#' rather than silently sorted alphabetically.
#'
#' @section Grouped Jonckheere-Terpstra default class:
#' Always returns a [class_jt_test] object, which inherits
#' [statim::class_stat_infer] and so picks up [auto_tidy()] automatically.
#' There is no separate `making_tidy()` registration needed for this path.
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
#' JT_TEST(x_by(x, g), alternative = "increasing")
#'
#' JT_TEST(x_by(x, g), approximate = TRUE)
#'
#' @keywords internal
#' @name jttest-xby
#' @family jttest-implementations
NULL

jttest_def_xby = statim::stat_define(
    model_type = x_by,
    impl = statim::agendas(
        base = statim::baseline(
            fn = function(.proc, alternative = "two.sided", approximate = FALSE) {
                tests = lapply(.proc$group_data, function(g) {
                    if (!is.ordered(g)) {
                        cli::cli_abort(c(
                            "The grouping variable must be an ordered factor for {.fn JT_TEST}.",
                            "i" = "Jonckheere-Terpstra is a trend test; group order sets the direction of {.arg alternative}.",
                            "i" = "Wrap it with {.fn factor} and pass {.arg levels} in the order you intend, or use {.fn ordered}."
                        ))
                    }

                    jonckheere_terpstra_test(
                        values = .proc$x_data[[1]],
                        groups = as.integer(g),
                        alternative = alternative,
                        approximate = approximate
                    )
                })

                class_jt_test(
                    vars = names(.proc$group_data),
                    statistic = vapply(tests, \(t) t$statistic, numeric(1)),
                    mean = vapply(tests, \(t) t$mean, numeric(1)),
                    variance = vapply(tests, \(t) t$variance, numeric(1)),
                    z_score = vapply(tests, \(t) t$z_score, numeric(1)),
                    p_value = vapply(tests, \(t) t$p_value, numeric(1)),
                    alternative = vapply(tests, \(t) t$alternative, character(1)),
                    approximate = vapply(tests, \(t) t$approximate, logical(1)),
                    method = vapply(tests, \(t) t$method, character(1))
                )
            }
        )
    )
)
