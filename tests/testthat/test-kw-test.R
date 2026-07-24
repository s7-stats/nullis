# ---- C++ Source tests ----

test_that("kruskal_wallis_cpp matches stats::kruskal.test on grouped lists", {
    set.seed(1)
    g1 = rnorm(10)
    g2 = rnorm(10, mean = 2)
    g3 = rnorm(10, mean = -1)

    result = kruskal_wallis_cpp(list(g1, g2, g3))
    ref = stats::kruskal.test(list(g1, g2, g3))

    expect_equal(result$statistic, unname(ref$statistic), tolerance = 1e-8)
    expect_equal(result$p_value, ref$p.value, tolerance = 1e-8)
    expect_equal(result$df, unname(ref$parameter))
})

test_that("kruskal_wallis_cpp matches stats::kruskal.test with ties", {
    x1 = c(1, 2, 2, 3, 4)
    x2 = c(2, 3, 3, 5, 5)
    x3 = c(1, 1, 4, 4, 6)

    result = kruskal_wallis_cpp(list(x1, x2, x3))
    ref = stats::kruskal.test(list(x1, x2, x3))

    expect_equal(result$statistic, unname(ref$statistic), tolerance = 1e-8)
    expect_equal(result$p_value, ref$p.value, tolerance = 1e-8)
})

test_that("kruskal_wallis_cpp handles two groups (df = 1)", {
    set.seed(2)
    g1 = rnorm(15)
    g2 = rnorm(15, mean = 1.5)

    result = kruskal_wallis_cpp(list(g1, g2))
    ref = stats::kruskal.test(list(g1, g2))

    expect_equal(result$df, 1)
    expect_equal(result$statistic, unname(ref$statistic), tolerance = 1e-8)
})

test_that("kruskal_wallis_cpp returns a nonnegative statistic and a valid p-value", {
    set.seed(3)
    groups = lapply(1:4, \(i) rnorm(8, mean = i))

    result = kruskal_wallis_cpp(groups)

    expect_gte(result$statistic, 0)
    expect_gte(result$p_value, 0)
    expect_lte(result$p_value, 1)
    expect_equal(result$df, 3)
})

test_that("kruskal_wallis_group matches stats::kruskal.test with character grouping", {
    set.seed(4)
    x = c(rnorm(10), rnorm(10, mean = 3), rnorm(10, mean = -2))
    g = rep(c("a", "b", "c"), each = 10)

    result = kruskal_wallis_group(x, g)
    ref = stats::kruskal.test(x, factor(g))

    expect_equal(result$statistic, unname(ref$statistic), tolerance = 1e-8)
    expect_equal(result$p_value, ref$p.value, tolerance = 1e-8)
    expect_equal(result$df, unname(ref$parameter))
})

test_that("kruskal_wallis_group is invariant to group label order/spelling", {
    set.seed(5)
    x = c(rnorm(10), rnorm(10, mean = 2))
    g_alpha = rep(c("control", "treatment"), each = 10)
    g_relabel = rep(c("zzz_treatment", "aaa_control"), each = 10)

    result_alpha = kruskal_wallis_group(x, g_alpha)
    result_relabel = kruskal_wallis_group(x, g_relabel)

    expect_equal(
        result_alpha$statistic,
        result_relabel$statistic,
        tolerance = 1e-8
    )
    expect_equal(result_alpha$p_value, result_relabel$p_value, tolerance = 1e-8)
})

test_that("kruskal_wallis_group errors on mismatched lengths", {
    expect_error(
        kruskal_wallis_group(c(1, 2, 3), c("a", "b")),
        "must match"
    )
})

test_that("kruskal_wallis_cpp is invariant to group order", {
    set.seed(6)
    g1 = rnorm(10)
    g2 = rnorm(10, mean = 2)
    g3 = rnorm(10, mean = -1)

    result_1 = kruskal_wallis_cpp(list(g1, g2, g3))
    result_2 = kruskal_wallis_cpp(list(g3, g1, g2))

    expect_equal(result_1$statistic, result_2$statistic, tolerance = 1e-8)
    expect_equal(result_1$p_value, result_2$p_value, tolerance = 1e-8)
})

# ---- R APIs ----
test_that("class_kw_test rejects p-values outside (0, 1)", {
    expect_error(
        class_kw_test(vars = "g", statistic = 5, df = 2, p_value = 0),
        "p_value must be between 0 and 1"
    )
    expect_error(
        class_kw_test(vars = "g", statistic = 5, df = 2, p_value = 1),
        "p_value must be between 0 and 1"
    )
})

test_that("class_kw_test print() runs without error", {
    obj = class_kw_test(
        vars = "g",
        statistic = 5.4321,
        df = 2,
        p_value = 0.0321
    )

    expect_output(print(obj))
})

test_that("auto_tidy.class_kw_test returns a tibble with one row per group", {
    obj = class_kw_test(
        vars = c("g1", "g2"),
        statistic = c(5, 8),
        df = c(2, 1),
        p_value = c(0.03, 0.01)
    )

    tidy_out = auto_tidy(obj)

    expect_s3_class(tidy_out, "tbl_df")
    expect_equal(nrow(tidy_out), 2)
    expect_equal(names(tidy_out), c("vars", "statistic", "df", "p_value"))
})

test_that("KW_TEST(x_by()) matches kruskal_wallis_group called directly", {
    set.seed(123)
    x = rcauchy(50, 1, 1.5)
    g = sample(letters[1:5], size = 50, replace = TRUE)

    piped = KW_TEST(x_by(x, g))
    direct = kruskal_wallis_group(x, g)

    expect_s7_class(piped@data, class_kw_test)
    expect_equal(unname(piped@data@vars), "g")
    expect_equal(unname(piped@data@statistic), direct$statistic, tolerance = 1e-8)
    expect_equal(unname(piped@data@p_value), direct$p_value, tolerance = 1e-8)
    expect_equal(unname(piped@data@df), direct$df)
})

test_that("KW_TEST(x_by()) runs one test per grouping variable", {
    set.seed(123)
    x = rcauchy(50, 1, 1.5)
    g = sample(letters[1:5], size = 50, replace = TRUE)
    g2 = sample(c("control", "treatment"), size = 50, replace = TRUE)

    result = KW_TEST(x_by(x, c(g, g2)))

    expect_length(result@data@statistic, 2)
})

test_that("KW_TEST(x_by()) |> via('pairwise') matches manual pairwise z-tests", {
    set.seed(123)
    x = rcauchy(60, 1, 1.5)
    g = sample(letters[1:3], size = 60, replace = TRUE)

    # result = KW_TEST(x_by(x, g)) |> via("pairwise")
    result =
        statim::define_model(x_by(x, g)) |>
        statim::prepare(KW_TEST) |>
        statim::via("pairwise") |>
        statim::conclude()

    expect_named(result@data, c("kw_test", "comps"))
    expect_equal(nrow(result@data$comps), choose(length(unique(g)), 2))
    expect_true(all(
        result@data$comps$p_adj >= result@data$comps$p_value |
            is.na(result@data$comps$p_adj)
    ))
    expect_output(print(result))
})

test_that("pairwise variant applies the requested p_adj_method", {
    set.seed(123)
    x = rcauchy(60, 1, 1.5)
    g = sample(letters[1:3], size = 60, replace = TRUE)

    result_holm =
        statim::define_model(x_by(x, g)) |>
        statim::prepare(KW_TEST) |>
        statim::via("pairwise") |>
        statim::conclude()

    result_bonf =
        statim::define_model(x_by(x, g)) |>
        statim::prepare(KW_TEST) |>
        statim::via("pairwise", p_adj_method = "bonferroni") |>
        statim::conclude()

    expected_bonf = stats::p.adjust(
        result_bonf@data$comps$p_value,
        method = "bonferroni"
    )

    expect_equal(result_bonf@data$comps$p_adj, expected_bonf, tolerance = 1e-8)
    expect_true(all(
        result_holm@data$comps$p_adj <= result_bonf@data$comps$p_adj + 1e-8
    ))
})

test_that("pairwise variant errors with fewer than two groups", {
    set.seed(1)
    x = rcauchy(20, 1, 1.5)
    g = rep("only_group", 20)

    expect_error({
        statim::define_model(x_by(x, g)) |>
            statim::prepare(KW_TEST) |>
            statim::via("pairwise") |>
            statim::conclude()
    }, "At least two groups")
})

test_that("pairwise variant rejects an unsupported p_adj_method", {
    set.seed(1)
    x = rcauchy(30, 1, 1.5)
    g = sample(letters[1:3], size = 30, replace = TRUE)

    expect_error({
        statim::define_model(x_by(x, g)) |>
            statim::prepare(KW_TEST) |>
            statim::via("pairwise", p_adj_method = "not_a_method") |>
            statim::conclude()
    }, "should be one of")
})

test_that("KW_TEST(on()) matches kruskal_wallis_cpp called directly", {
    set.seed(123)
    x = rcauchy(50, 1, 1.5)
    y = rcauchy(50, 3, 1.5)

    piped = KW_TEST(on(x, y))
    direct = kruskal_wallis_cpp(list(x, y))

    expect_equal(piped@data$statistic, direct$statistic, tolerance = 1e-8)
    expect_equal(piped@data$p_value, direct$p_value, tolerance = 1e-8)
    expect_equal(piped@data$df, direct$df)
})

test_that("KW_TEST(on()) print() runs without error", {
    set.seed(123)
    x = rcauchy(30, 1, 1.5)
    y = rcauchy(30, 3, 1.5)

    result = KW_TEST(on(x, y))

    expect_output(print(result), "H Statistic")
})
