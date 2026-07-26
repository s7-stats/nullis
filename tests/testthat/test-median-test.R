# ---- C++ Source tests ----

test_that("mood_median_test_cpp matches a manual median-split chi-square test", {
    set.seed(1)
    g1 = rnorm(20)
    g2 = rnorm(20, mean = 1)
    g3 = rnorm(20, mean = -1)

    cpp_out = mood_median_test_cpp(list(g1, g2, g3))

    med = median(c(g1, g2, g3))
    tab = rbind(
        above = c(sum(g1 > med), sum(g2 > med), sum(g3 > med)),
        below_or_equal = c(sum(g1 <= med), sum(g2 <= med), sum(g3 <= med))
    )
    ref = suppressWarnings(stats::chisq.test(tab, correct = FALSE))

    expect_equal(cpp_out$statistic, unname(ref$statistic), tolerance = 1e-8)
    expect_equal(cpp_out$p_value, ref$p.value, tolerance = 1e-8)
    expect_equal(cpp_out$df, unname(ref$parameter))
    expect_equal(cpp_out$median, med, tolerance = 1e-8)
})

test_that("mood_median_test_cpp uses custom_median when supplied", {
    g1 = c(1, 2, 3, 4, 5)
    g2 = c(6, 7, 8, 9, 10)

    custom_out = mood_median_test_cpp(list(g1, g2), custom_median = 5)

    expect_equal(custom_out$median, 5)
    # row 1 = above median: none of g1 (max 5) qualifies, all of g2 does
    expect_equal(unname(custom_out$cont_table[1, ]), c(0, 5))
})

test_that("mood_median_test_cpp handles a single group against a custom_median", {
    g1 = c(1, 2, 3, 8, 9, 10)

    single_out = mood_median_test_cpp(list(g1), custom_median = 5)

    above = sum(g1 > 5)
    below_or_equal = sum(g1 <= 5)
    expected = length(g1) / 2
    chi_sq = ((above - expected)^2 + (below_or_equal - expected)^2) / expected

    expect_equal(single_out$statistic, chi_sq, tolerance = 1e-8)
    expect_equal(single_out$df, 1)
})

test_that("mood_median_test_cpp keeps the same row orientation for k == 1 and k > 1", {
    set.seed(3)
    g1 = rnorm(30)
    g2 = rnorm(30)
    med = median(g1)

    single_out = mood_median_test_cpp(list(g1), custom_median = med)
    grouped_out = mood_median_test_cpp(list(g1, g2), custom_median = med)

    # row 1 = above median in both branches
    expect_equal(unname(single_out$cont_table[1, 1]), sum(g1 > med))
    expect_equal(unname(grouped_out$cont_table[1, 1]), sum(g1 > med))
})

test_that("mood_median_test_cpp errors on no groups or an empty group", {
    expect_error(mood_median_test_cpp(list()), "No groups")
    expect_error(
        mood_median_test_cpp(list(numeric(0), c(1, 2, 3))),
        "Empty group"
    )
})

test_that("mood_median_test_cpp is invariant to group order", {
    set.seed(6)
    g1 = rnorm(15)
    g2 = rnorm(15, mean = 2)
    g3 = rnorm(15, mean = -1)

    forward_out = mood_median_test_cpp(list(g1, g2, g3))
    shuffled_out = mood_median_test_cpp(list(g3, g1, g2))

    expect_equal(
        forward_out$statistic,
        shuffled_out$statistic,
        tolerance = 1e-8
    )
    expect_equal(forward_out$p_value, shuffled_out$p_value, tolerance = 1e-8)
})

test_that("mood_median_test_cpp handles an unnamed list without erroring", {
    set.seed(7)
    g1 = rnorm(15)
    g2 = rnorm(15, mean = 2)

    unnamed_out = mood_median_test_cpp(list(g1, g2))

    expect_null(colnames(unnamed_out$cont_table))
})

test_that("mood_median_test_cpp attaches colnames when the list is named", {
    set.seed(7)
    g1 = rnorm(15)
    g2 = rnorm(15, mean = 2)

    named_out = mood_median_test_cpp(list(x1 = g1, x2 = g2))

    expect_equal(colnames(named_out$cont_table), c("x1", "x2"))
})

test_that("mood_median_test_group matches mood_median_test_cpp with equivalent groups", {
    set.seed(4)
    x = c(rnorm(15), rnorm(15, mean = 2), rnorm(15, mean = -1))
    g = rep(c("a", "b", "c"), each = 15)

    group_out = mood_median_test_group(x, g)
    cpp_out = mood_median_test_cpp(list(x[g == "a"], x[g == "b"], x[g == "c"]))

    expect_equal(group_out$statistic, cpp_out$statistic, tolerance = 1e-8)
    expect_equal(group_out$p_value, cpp_out$p_value, tolerance = 1e-8)
    expect_equal(group_out$median, cpp_out$median, tolerance = 1e-8)
})

test_that("mood_median_test_group is invariant to group label order/spelling", {
    set.seed(5)
    x = c(rnorm(10), rnorm(10, mean = 2))
    g_alpha = rep(c("control", "treatment"), each = 10)
    g_relabel = rep(c("zzz_treatment", "aaa_control"), each = 10)

    alpha_out = mood_median_test_group(x, g_alpha)
    relabel_out = mood_median_test_group(x, g_relabel)

    expect_equal(alpha_out$statistic, relabel_out$statistic, tolerance = 1e-8)
    expect_equal(alpha_out$p_value, relabel_out$p_value, tolerance = 1e-8)
})

test_that("mood_median_test_group errors on mismatched lengths", {
    expect_error(
        mood_median_test_group(c(1, 2, 3), c("a", "b")),
        "must match"
    )
})

test_that("mood_median_test_group's cont_table columns are named in first-appearance order", {
    set.seed(123)
    x = rcauchy(50, 1, 1.5)
    g = sample(letters[1:5], size = 50, replace = TRUE)

    group_out = mood_median_test_group(x, g)

    expect_equal(colnames(group_out$cont_table), unique(g))
})

test_that("mood_median_test_group's cont_table column sums match group sizes", {
    set.seed(5)
    x = rcauchy(40, 0, 1)
    g = sample(c("x1", "x2", "x3"), size = 40, replace = TRUE)

    group_out = mood_median_test_group(x, g)

    expect_equal(
        unname(colSums(group_out$cont_table)),
        as.integer(table(g)[colnames(group_out$cont_table)])
    )
})

# ---- R APIs ----

test_that("class_median_test accepts p_value exactly 0 or 1", {
    expect_no_error(
        class_median_test(
            vars = "g",
            statistic = 100,
            df = 1,
            p_value = 0,
            cont_tab = list(matrix(1:4, 2)),
            median = 0,
            n_groups = 2L
        )
    )
    expect_no_error(
        class_median_test(
            vars = "g",
            statistic = 0,
            df = 1,
            p_value = 1,
            cont_tab = list(matrix(1:4, 2)),
            median = 0,
            n_groups = 2L
        )
    )
})

test_that("class_median_test rejects p-values outside [0, 1]", {
    expect_error(
        class_median_test(
            vars = "g",
            statistic = 5,
            df = 1,
            p_value = -0.1,
            cont_tab = list(matrix(1:4, 2)),
            median = 0,
            n_groups = 2L
        ),
        "p_value must be between 0 and 1"
    )
    expect_error(
        class_median_test(
            vars = "g",
            statistic = 5,
            df = 1,
            p_value = 1.1,
            cont_tab = list(matrix(1:4, 2)),
            median = 0,
            n_groups = 2L
        ),
        "p_value must be between 0 and 1"
    )
})

test_that("class_median_test rejects a cont_tab that isn't a list of matrices", {
    expect_error(
        class_median_test(
            vars = "g",
            statistic = 5,
            df = 1,
            p_value = 0.05,
            cont_tab = matrix(1:4, 2),
            median = 0,
            n_groups = 2L
        )
    )
})

test_that("class_median_test print() shows the contingency table when display_ct is TRUE", {
    obj = class_median_test(
        vars = "g",
        statistic = 5.4321,
        df = 1,
        p_value = 0.0321,
        cont_tab = list(matrix(c(4, 6, 5, 5), nrow = 2)),
        median = 1.23,
        n_groups = 2L,
        display_ct = TRUE
    )

    expect_output(print(obj), "Contingency Table")
})

test_that("class_median_test print() hides the contingency table when display_ct is FALSE", {
    obj = class_median_test(
        vars = "g",
        statistic = 5.4321,
        df = 1,
        p_value = 0.0321,
        cont_tab = list(matrix(c(4, 6, 5, 5), nrow = 2)),
        median = 1.23,
        n_groups = 2L,
        display_ct = FALSE
    )

    printed = capture.output(print(obj))
    expect_false(any(grepl("Contingency Table", printed)))
})

test_that("auto_tidy.class_median_test returns a tibble with one row per group", {
    obj = class_median_test(
        vars = c("g1", "g2"),
        statistic = c(5, 8),
        df = c(1, 1),
        p_value = c(0.03, 0.01),
        cont_tab = list(),
        median = c(0, 1),
        n_groups = c(2L, 2L)
    )

    tidy_out = auto_tidy(obj)

    expect_s3_class(tidy_out, "tbl_df")
    expect_equal(nrow(tidy_out), 2)
    expect_equal(
        names(tidy_out),
        c("vars", "median", "statistic", "df", "p_value")
    )
})

test_that("MEDIAN_TEST(x_by()) matches mood_median_test_group called directly", {
    set.seed(123)
    x = rcauchy(50, 1, 1.5)
    g = sample(letters[1:5], size = 50, replace = TRUE)

    piped = MEDIAN_TEST(x_by(x, g))
    direct = mood_median_test_group(x, g)

    expect_s7_class(piped@data, class_median_test)
    expect_equal(unname(piped@data@vars), "g")
    expect_equal(
        unname(piped@data@statistic),
        direct$statistic,
        tolerance = 1e-8
    )
    expect_equal(unname(piped@data@p_value), direct$p_value, tolerance = 1e-8)
    expect_equal(unname(piped@data@df), direct$df)
})

test_that("MEDIAN_TEST(x_by())'s base path always shows the contingency table", {
    set.seed(123)
    x = rcauchy(30, 1, 1.5)
    g = sample(letters[1:3], size = 30, replace = TRUE)

    piped = MEDIAN_TEST(x_by(x, g))

    expect_true(piped@data@display_ct)
    expect_output(print(piped), "Contingency Table")
})

test_that("MEDIAN_TEST(x_by())'s cont_tab has group-labeled columns", {
    set.seed(123)
    x = rcauchy(50, 1, 1.5)
    g = sample(letters[1:5], size = 50, replace = TRUE)

    piped = MEDIAN_TEST(x_by(x, g))

    expect_equal(colnames(piped@data@cont_tab[[1]]), unique(g))
})

test_that("MEDIAN_TEST(x_by()) errors on more than one grouping variable without via('multi')", {
    set.seed(123)
    x = rcauchy(50, 1, 1.5)
    g1 = sample(letters[1:5], size = 50, replace = TRUE)
    g2 = sample(c("control", "treatment"), size = 50, replace = TRUE)

    expect_error(
        MEDIAN_TEST(x_by(x, c(g1, g2))),
        "supports exactly one grouping variable"
    )
})

test_that("'multi' variant runs one test per grouping variable", {
    set.seed(123)
    x = rcauchy(50, 1, 1.5)
    g1 = sample(letters[1:5], size = 50, replace = TRUE)
    g2 = sample(c("control", "treatment"), size = 50, replace = TRUE)

    multi_out =
        statim::define_model(x_by(x, c(g1, g2))) |>
        statim::prepare(MEDIAN_TEST) |>
        statim::via("multi") |>
        statim::conclude()

    expect_length(multi_out@data@statistic, 2)
})

test_that("MEDIAN_TEST(x_by()) |> via('multi') selects the requested variable's table", {
    set.seed(123)
    x = rcauchy(60, 1, 1.5)
    g1 = sample(letters[1:3], size = 60, replace = TRUE)
    g2 = sample(c("control", "treatment"), size = 60, replace = TRUE)

    direct_g2 = mood_median_test_group(x, g2)

    multi_out =
        statim::define_model(x_by(x, c(g1, g2))) |>
        statim::prepare(MEDIAN_TEST) |>
        statim::via("multi", display_var = 2L) |>
        statim::conclude()

    expect_true(multi_out@data@display_ct)
    expect_equal(
        multi_out@data@cont_tab[[1]],
        direct_g2$cont_table,
        ignore_attr = TRUE
    )
})

test_that("MEDIAN_TEST(x_by()) |> via('multi', display_var = FALSE) hides the table", {
    set.seed(123)
    x = rcauchy(60, 1, 1.5)
    g1 = sample(letters[1:3], size = 60, replace = TRUE)
    g2 = sample(c("control", "treatment"), size = 60, replace = TRUE)

    hidden_out =
        statim::define_model(x_by(x, c(g1, g2))) |>
        statim::prepare(MEDIAN_TEST) |>
        statim::via("multi", display_var = FALSE) |>
        statim::conclude()

    expect_false(hidden_out@data@display_ct)
    expect_length(hidden_out@data@cont_tab, 0)
})

test_that("MEDIAN_TEST(x_by()) |> via('multi') errors on an out-of-range display_var", {
    set.seed(123)
    x = rcauchy(60, 1, 1.5)
    g1 = sample(letters[1:3], size = 60, replace = TRUE)
    g2 = sample(c("control", "treatment"), size = 60, replace = TRUE)

    expect_error(
        {
            statim::define_model(x_by(x, c(g1, g2))) |>
                statim::prepare(MEDIAN_TEST) |>
                statim::via("multi", display_var = 5L) |>
                statim::conclude()
        },
        "display_var"
    )
})

test_that("MEDIAN_TEST(x_by()) |> via('multi') errors with fewer than two grouping variables", {
    set.seed(123)
    x = rcauchy(30, 1, 1.5)
    g1 = sample(letters[1:3], size = 30, replace = TRUE)

    expect_error(
        {
            statim::define_model(x_by(x, g1)) |>
                statim::prepare(MEDIAN_TEST) |>
                statim::via("multi") |>
                statim::conclude()
        },
        "more than one grouping variable"
    )
})

test_that("MEDIAN_TEST(on()) matches mood_median_test_cpp called directly", {
    set.seed(123)
    x = rcauchy(50, 1, 1.5)
    y = rcauchy(50, 3, 1.5)

    piped = MEDIAN_TEST(on(x, y))
    direct = mood_median_test_cpp(list(x, y))

    expect_s7_class(piped@data, class_median_test)
    expect_equal(piped@data@vars, "on")
    expect_equal(piped@data@statistic, direct$statistic, tolerance = 1e-8)
    expect_equal(piped@data@p_value, direct$p_value, tolerance = 1e-8)
    expect_equal(piped@data@df, direct$df)
})

test_that("MEDIAN_TEST(on())'s display_ct defaults to TRUE", {
    set.seed(123)
    x = rcauchy(30, 1, 1.5)
    y = rcauchy(30, 3, 1.5)

    piped = MEDIAN_TEST(on(x, y))

    expect_true(piped@data@display_ct)
})

test_that("MEDIAN_TEST(on()) respects custom_median", {
    x = c(1, 2, 3, 4, 5)
    y = c(6, 7, 8, 9, 10)

    piped = MEDIAN_TEST(on(x, y), custom_median = 5)

    expect_equal(piped@data@median, 5)
})

test_that("MEDIAN_TEST(on()) with a single group matches the k == 1 formula", {
    g1 = c(1, 2, 3, 8, 9, 10)

    piped = MEDIAN_TEST(on(g1), custom_median = 5)

    above = sum(g1 > 5)
    below_or_equal = sum(g1 <= 5)
    expected = length(g1) / 2
    chi_sq = ((above - expected)^2 + (below_or_equal - expected)^2) / expected

    expect_equal(piped@data@statistic, chi_sq, tolerance = 1e-8)
    expect_equal(piped@data@df, 1)
})

test_that("MEDIAN_TEST(on()) print() runs without error", {
    set.seed(123)
    x = rcauchy(30, 1, 1.5)
    y = rcauchy(30, 3, 1.5)

    piped = MEDIAN_TEST(on(x, y))

    expect_output(print(piped), "Summary")
})
