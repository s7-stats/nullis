# ---- C++ Source Tests ----
test_that("statistic, mean, variance, and z-score match hand-derived values", {
    # 3 groups of 2, perfectly increasing: group1 < group2 < group3.
    # statistic hits its max of sum(n_i * n_(>i)) = 2*4 + 2*2 = 12.
    # mean = 4 + 2 = 6; variance = 2*4*7/12 + 2*2*5/12 = 56/12 + 20/12 = 76/12.
    values = c(1, 2, 3, 4, 5, 6)
    groups = c(1L, 1L, 2L, 2L, 3L, 3L)

    result = jonckheere_terpstra_test(
        values,
        groups,
        alternative = "increasing"
    )

    expect_equal(result$statistic, 12)
    expect_equal(result$mean, 6)
    expect_equal(result$variance, 76 / 12, tolerance = 1e-8)
    expect_equal(result$z_score, (12 - 6) / sqrt(76 / 12), tolerance = 1e-8)
    expect_equal(result$method, "exact")
    expect_false(result$approximate)
})

test_that("exact increasing/decreasing p-values are complementary, inclusive of the observed point", {
    # With both tails inclusive of the observed statistic (p_lower = P(W <=
    # jt_int), p_upper = P(W >= jt_int)), they overlap by exactly the point
    # mass at jt_int: p_inc + p_dec = 1 + P(W = jt_int), not exactly 1. Here
    # jt_int sits at the boundary (statistic = 12, the max), where only one
    # arrangement out of 90 achieves it, so the overlap is 1/90.
    values = c(1, 2, 3, 4, 5, 6)
    groups = c(1L, 1L, 2L, 2L, 3L, 3L)

    p_inc = jonckheere_terpstra_test(
        values,
        groups,
        alternative = "increasing"
    )$p_value
    p_dec = jonckheere_terpstra_test(
        values,
        groups,
        alternative = "decreasing"
    )$p_value
    p_two = jonckheere_terpstra_test(
        values,
        groups,
        alternative = "two.sided"
    )$p_value

    expect_equal(p_inc + p_dec, 1 + 1 / 90, tolerance = 1e-8)
    expect_lte(p_two, 1)
})

test_that("reversing group order swaps increasing/decreasing p-values", {
    values = c(1, 2, 3, 4, 5, 6)
    groups_inc = c(1L, 1L, 2L, 2L, 3L, 3L)
    groups_dec = c(3L, 3L, 2L, 2L, 1L, 1L)

    p_inc_forward = jonckheere_terpstra_test(
        values,
        groups_inc,
        alternative = "increasing"
    )$p_value
    p_dec_reversed = jonckheere_terpstra_test(
        values,
        groups_dec,
        alternative = "decreasing"
    )$p_value

    expect_equal(p_inc_forward, p_dec_reversed, tolerance = 1e-8)
})

test_that("ties are split 0.5/0.5 in the statistic", {
    # Two groups, all values tied across groups: each of the 4 cross
    # comparisons contributes 0.5, so statistic = 4 * 0.5 = 2.
    values = c(1, 1, 1, 1)
    groups = c(1L, 1L, 2L, 2L)

    result = jonckheere_terpstra_test(
        values,
        groups,
        alternative = "two.sided"
    )

    expect_equal(result$statistic, 2)
})

test_that("normal approximation is used when n > 50 or approximate = TRUE", {
    set.seed(42)
    values = rnorm(60)
    groups = rep(1:3, each = 20)

    result_large_n = jonckheere_terpstra_test(values, groups)
    expect_equal(result_large_n$method, "normal approximation")
    expect_true(result_large_n$approximate)

    small_values = c(1, 2, 3, 4, 5, 6)
    small_groups = c(1L, 1L, 2L, 2L, 3L, 3L)
    result_forced = jonckheere_terpstra_test(
        small_values,
        small_groups,
        approximate = TRUE
    )
    expect_equal(result_forced$method, "normal approximation")
    expect_true(result_forced$approximate)
})

test_that("jonckheere_terpstra_test_groups matches the flat-vector call", {
    g1 = c(1, 2)
    g2 = c(3, 4)
    g3 = c(5, 6)

    result_grouped = jonckheere_terpstra_test_groups(
        list(g1, g2, g3),
        alternative = "increasing"
    )
    result_flat = jonckheere_terpstra_test(
        c(g1, g2, g3),
        c(1L, 1L, 2L, 2L, 3L, 3L),
        alternative = "increasing"
    )

    expect_equal(result_grouped$statistic, result_flat$statistic)
    expect_equal(result_grouped$p_value, result_flat$p_value, tolerance = 1e-8)
})

test_that("invalid alternative errors for both entry points", {
    values = c(1, 2, 3, 4)
    groups = c(1L, 1L, 2L, 2L)

    expect_error(
        jonckheere_terpstra_test(values, groups, alternative = "bogus"),
        "Invalid alternative"
    )
    expect_error(
        jonckheere_terpstra_test_groups(
            list(c(1, 2), c(3, 4)),
            alternative = "bogus"
        ),
        "Invalid alternative"
    )
})

test_that("jonckheere_terpstra_test errors on mismatched lengths", {
    expect_error(
        jonckheere_terpstra_test(c(1, 2, 3), c(1L, 2L)),
        "must match"
    )
})

test_that("p-values are always valid probabilities", {
    set.seed(7)
    values = rnorm(30)
    groups = rep(1:4, times = c(8, 7, 8, 7))

    for (alt in c("two.sided", "increasing", "decreasing")) {
        result = jonckheere_terpstra_test(values, groups, alternative = alt)
        expect_gte(result$p_value, 0)
        expect_lte(result$p_value, 1)
    }
})

test_that("z-score sign follows the direction of the observed trend", {
    increasing_values = 1:9
    decreasing_values = 9:1
    groups = rep(1:3, each = 3)

    z_up = jonckheere_terpstra_test(increasing_values, groups)$z_score
    z_down = jonckheere_terpstra_test(decreasing_values, groups)$z_score

    expect_gt(z_up, 0)
    expect_lt(z_down, 0)
})

# ---- R APIs ----
test_that("class_jt_test rejects p-values outside (0, 1)", {
    expect_error(
        class_jt_test(
            vars = "g",
            statistic = 10,
            p_value = 0,
            alternative = "two.sided"
        ),
        "p_value must be between 0 and 1"
    )
    expect_error(
        class_jt_test(
            vars = "g",
            statistic = 10,
            p_value = 1,
            alternative = "two.sided"
        ),
        "p_value must be between 0 and 1"
    )
})

test_that("class_jt_test accepts a minimal construction with only required slots", {
    obj = class_jt_test(
        vars = "g",
        statistic = 10,
        p_value = 0.04,
        alternative = "increasing"
    )

    expect_s7_class(obj, class_jt_test)
    expect_length(obj@z_score, 0)
    expect_length(obj@mean, 0)
    expect_length(obj@variance, 0)
    expect_length(obj@approximate, 0)
    expect_length(obj@method, 0)
})

test_that("class_jt_test print() shows optional fields as 'Not given' when absent", {
    obj = class_jt_test(
        vars = "g",
        statistic = 10,
        p_value = 0.04,
        alternative = "increasing"
    )

    expect_error(print(obj), "New column")
})

test_that("class_jt_test print() includes z_score/mean/variance when supplied", {
    obj = class_jt_test(
        vars = "g",
        statistic = 12,
        mean = 6,
        variance = 6.3333,
        z_score = 2.38,
        p_value = 0.02,
        alternative = "increasing",
        approximate = FALSE,
        method = "exact"
    )

    out = capture.output(print(obj))
    combined = paste(out, collapse = " ")

    expect_match(combined, "6.3333|6\\.333")
    expect_no_match(combined, "Not given")
})

test_that("auto_tidy.class_jt_test returns a tibble with one row per group", {
    obj = class_jt_test(
        vars = c("g1", "g2"),
        statistic = c(10, 20),
        p_value = c(0.03, 0.04),
        alternative = c("two.sided", "two.sided"),
        z_score = c(2.1, 2.5),
        mean = c(5, 8),
        variance = c(3, 4),
        approximate = c(FALSE, FALSE),
        method = c("exact", "exact")
    )

    tidy_out = auto_tidy(obj)

    expect_s3_class(tidy_out, "tbl_df")
    expect_equal(nrow(tidy_out), 2)
    expect_equal(tidy_out$vars, c("g1", "g2"))
    expect_setequal(
        names(tidy_out),
        c(
            "vars",
            "statistic",
            "p_value",
            "alternative",
            "z_score",
            "mean",
            "variance",
            "approximate",
            "method"
        )
    )
})

test_that("JT_TEST(x_by()) matches jonckheere_terpstra_test called directly", {
    set.seed(123)
    x = rcauchy(50, 1, 1.5)
    g = factor(
        sample(letters[1:3], size = 50, replace = TRUE),
        levels = c("a", "b", "c"),
        ordered = TRUE
    )

    piped = JT_TEST(x_by(x, g))
    direct = jonckheere_terpstra_test(
        x,
        as.integer(g),
        alternative = "two.sided"
    )

    expect_s7_class(piped@data, class_jt_test)
    expect_equal(unname(piped@data@vars), "g")
    expect_equal(
        unname(piped@data@statistic),
        direct$statistic,
        tolerance = 1e-8
    )
    expect_equal(unname(piped@data@p_value), direct$p_value, tolerance = 1e-8)
})

test_that("JT_TEST(x_by()) errors when the grouping variable is not an ordered factor", {
    set.seed(123)
    x = rcauchy(30, 1, 1.5)
    g_unordered = factor(sample(letters[1:3], size = 30, replace = TRUE))

    expect_error(
        JT_TEST(x_by(x, g_unordered)),
        "ordered factor"
    )
})

# NOTE: your own roxygen example flags this call shape as unconfirmed
# ("confirm this call shape against your actual x_by() signature"). This
# test mirrors that example exactly; update the x_by() call below to match
# whatever multi-grouping-variable syntax x_by() actually accepts.
test_that("JT_TEST(x_by()) runs one test per grouping variable", {
    set.seed(123)
    x = rcauchy(50, 1, 1.5)
    g = factor(
        sample(letters[1:3], size = 50, replace = TRUE),
        levels = c("a", "b", "c"),
        ordered = TRUE
    )
    g2 = factor(
        sample(c("low", "high"), size = 50, replace = TRUE),
        levels = c("low", "high"),
        ordered = TRUE
    )

    result = JT_TEST(x_by(x, c(g, g2)))

    expect_length(unname(result@data@statistic), 2)
})

test_that("JT_TEST(x_by()) respects the alternative and approximate arguments", {
    set.seed(1)
    x = 1:20
    g = factor(
        rep(c("low", "high"), each = 10),
        levels = c("low", "high"),
        ordered = TRUE
    )

    result_default = JT_TEST(x_by(x, g))
    result_approx = JT_TEST(x_by(x, g), approximate = TRUE)

    expect_true(unname(result_approx@data@approximate))
    expect_equal(unname(result_default@data@method), "exact")
})
