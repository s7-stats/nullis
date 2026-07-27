# ---- C++ Source tests ----

manual_cochran_q = function(design_matrix) {
    n = nrow(design_matrix)
    k = ncol(design_matrix)

    row_sums = rowSums(design_matrix, na.rm = TRUE)
    col_sums = colSums(design_matrix, na.rm = TRUE)
    total_sum = sum(design_matrix, na.rm = TRUE)

    sum_col_squared = sum(col_sums^2)
    sum_row_squared = sum(row_sums^2)

    Q = (k - 1) *
        (k * sum_col_squared - total_sum^2) /
        (k * total_sum - sum_row_squared)
    df = k - 1
    p_value = pchisq(Q, df, lower.tail = FALSE)

    list(statistic = Q, df = df, p_value = p_value)
}

test_that("cochran_q_test_group matches a manual Cochran's Q formula", {
    set.seed(5472)
    outcome = sample(0:1, 30, replace = TRUE)
    treatment = gl(3, 1, 30, labels = LETTERS[1:3])
    block = gl(10, 3, labels = letters[1:10])

    design_matrix = t(matrix(outcome, nrow = 3, ncol = 10))
    ref = manual_cochran_q(design_matrix)

    cpp_out = cochran_q_test_group(
        outcome,
        as.character(treatment),
        as.character(block)
    )

    expect_equal(cpp_out$statistic, ref$statistic, tolerance = 1e-8)
    expect_equal(cpp_out$df, ref$df)
    expect_equal(cpp_out$p_value, ref$p_value, tolerance = 1e-8)
    expect_equal(cpp_out$n_groups, 3)
})

test_that("cochran_q_test_cpp matches cochran_q_test_group on equivalent data", {
    set.seed(5472)
    outcome = sample(0:1, 30, replace = TRUE)
    treatment = gl(3, 1, 30, labels = LETTERS[1:3])
    block = gl(10, 3, labels = letters[1:10])

    design_matrix = t(matrix(outcome, nrow = 3, ncol = 10))
    blocks_list = as.list(as.data.frame(design_matrix))

    list_out = cochran_q_test_cpp(blocks_list)
    group_out = cochran_q_test_group(
        outcome,
        as.character(treatment),
        as.character(block)
    )

    expect_equal(list_out$statistic, group_out$statistic, tolerance = 1e-8)
    expect_equal(list_out$df, group_out$df)
    expect_equal(list_out$p_value, group_out$p_value, tolerance = 1e-8)
})

test_that("cochran_q_test_cpp errors when list elements have unequal length", {
    expect_error(
        cochran_q_test_cpp(list(c(1, 0, 1), c(1, 0))),
        "same length"
    )
})

test_that("cochran_q_test_group errors on mismatched lengths", {
    expect_error(
        cochran_q_test_group(c(1, 0, 1), c("A", "B"), c("x", "y", "z")),
        "must match"
    )
})

test_that("cochran_q_test_group is invariant to label spelling and row order", {
    set.seed(11)
    outcome = sample(0:1, 30, replace = TRUE)
    treatment = gl(3, 1, 30, labels = LETTERS[1:3])
    block = gl(10, 3, labels = letters[1:10])

    base_out = cochran_q_test_group(
        outcome,
        as.character(treatment),
        as.character(block)
    )

    relabel_map = c(A = "zzz_treat", B = "mmm_treat", C = "aaa_treat")
    relabeled_out = cochran_q_test_group(
        outcome,
        unname(relabel_map[as.character(treatment)]),
        as.character(block)
    )

    shuffle_idx = sample(seq_along(outcome))
    shuffled_out = cochran_q_test_group(
        outcome[shuffle_idx],
        as.character(treatment)[shuffle_idx],
        as.character(block)[shuffle_idx]
    )

    expect_equal(base_out$statistic, relabeled_out$statistic, tolerance = 1e-8)
    expect_equal(base_out$statistic, shuffled_out$statistic, tolerance = 1e-8)
    expect_equal(base_out$p_value, shuffled_out$p_value, tolerance = 1e-8)
})

test_that("cochran_q_test_group excludes missing block/treatment combinations from the sums", {
    set.seed(5472)
    outcome = sample(0:1, 30, replace = TRUE)
    treatment = as.character(gl(3, 1, 30, labels = LETTERS[1:3]))
    block = as.character(gl(10, 3, labels = letters[1:10]))

    # drop observation 5: block "b", treatment "B"
    dropped_idx = 5
    reduced_outcome = outcome[-dropped_idx]
    reduced_treatment = treatment[-dropped_idx]
    reduced_block = block[-dropped_idx]

    design_matrix = t(matrix(outcome, nrow = 3, ncol = 10))
    design_matrix[2, 2] = NA
    ref = manual_cochran_q(design_matrix)

    cpp_out = cochran_q_test_group(
        reduced_outcome,
        reduced_treatment,
        reduced_block
    )

    expect_equal(cpp_out$statistic, ref$statistic, tolerance = 1e-8)
    expect_equal(cpp_out$df, ref$df)
    expect_equal(cpp_out$p_value, ref$p_value, tolerance = 1e-8)
})

test_that("cochran_q_test_group handles the minimal k = 2 case", {
    set.seed(22)
    outcome = sample(0:1, 20, replace = TRUE)
    treatment = gl(2, 1, 20, labels = c("A", "B"))
    block = gl(10, 2, labels = letters[1:10])

    design_matrix = t(matrix(outcome, nrow = 2, ncol = 10))
    ref = manual_cochran_q(design_matrix)

    cpp_out = cochran_q_test_group(
        outcome,
        as.character(treatment),
        as.character(block)
    )

    expect_equal(cpp_out$statistic, ref$statistic, tolerance = 1e-8)
    expect_equal(cpp_out$df, 1)
    expect_equal(cpp_out$n_groups, 2)
})

# ---- R APIs ----

test_that("class_cq_test freq_table defaults to an empty 0x2 matrix", {
    obj = class_cq_test(
        vars = "g",
        statistic = 10,
        df = 2,
        p_value = 0.05,
        n_groups = 3L
    )

    expect_true(is.matrix(obj@freq_table))
    expect_equal(dim(obj@freq_table), c(0, 2))
})

test_that("class_cq_test accepts p_value exactly 0 or 1", {
    expect_no_error(
        class_cq_test(
            vars = "g",
            statistic = 10,
            df = 2,
            p_value = 0,
            freq_table = matrix(c(5, 10, 15, 20), nrow = 2),
            n_groups = 3L
        )
    )
    expect_no_error(
        class_cq_test(
            vars = "g",
            statistic = 0,
            df = 2,
            p_value = 1,
            freq_table = matrix(c(5, 10, 15, 20), nrow = 2),
            n_groups = 3L
        )
    )
})

test_that("class_cq_test rejects p-values outside [0, 1]", {
    expect_error(
        class_cq_test(
            vars = "g",
            statistic = 5,
            df = 2,
            p_value = -0.1,
            n_groups = 3L
        ),
        "p_value must be between 0 and 1"
    )
    expect_error(
        class_cq_test(
            vars = "g",
            statistic = 5,
            df = 2,
            p_value = 1.1,
            n_groups = 3L
        ),
        "p_value must be between 0 and 1"
    )
})

test_that("class_cq_test rejects a freq_table that isn't a matrix", {
    expect_error(
        class_cq_test(
            vars = "g",
            statistic = 5,
            df = 2,
            p_value = 0.05,
            freq_table = list(1, 2, 3),
            n_groups = 3L
        )
    )
})

test_that("class_cq_test print() shows the frequency table when freq_table is populated", {
    obj = class_cq_test(
        vars = "g",
        statistic = 10.8889,
        df = 2,
        p_value = 0.0043,
        freq_table = matrix(c(5, 10, 15, 5, 10, 15), nrow = 3, ncol = 2),
        n_groups = 3L
    )

    expect_output(print(obj), "Summary")
    expect_output(print(obj), "Frequency Table")
})

test_that("class_cq_test print() hides the frequency table when freq_table is empty", {
    obj = class_cq_test(
        vars = "g",
        statistic = 10.8889,
        df = 2,
        p_value = 0.0043,
        n_groups = 3L
    )

    printed = capture.output(print(obj))

    expect_true(any(grepl("Summary", printed)))
    expect_false(any(grepl("Frequency Table", printed)))
})

test_that("auto_tidy.class_cq_test returns a tibble with matching fields", {
    obj = class_cq_test(
        vars = "g",
        statistic = 10.8889,
        df = 2,
        p_value = 0.0043,
        n_groups = 3L
    )

    tidy_out = auto_tidy(obj)

    expect_s3_class(tidy_out, "tbl_df")
    expect_equal(nrow(tidy_out), 1)
    expect_equal(
        names(tidy_out),
        c("vars", "n_groups", "statistic", "df", "p_value")
    )
})

test_that("COCHRAN_QTEST(x_by_b()) returns a class_cq_test object", {
    set.seed(123)
    x = sample(0:1, 45, replace = TRUE)
    treatment = gl(3, 1, 45, labels = c("A", "B", "C"))
    block = gl(15, 3, labels = 1:15)

    piped = COCHRAN_QTEST(x_by_b(x, treatment, block))

    expect_s7_class(piped@data, class_cq_test)
})

test_that("COCHRAN_QTEST(x_by_b()) matches cochran_q_test_group called directly", {
    set.seed(123)
    x = sample(0:1, 45, replace = TRUE)
    treatment = gl(3, 1, 45, labels = c("A", "B", "C"))
    block = gl(15, 3, labels = 1:15)

    piped = COCHRAN_QTEST(x_by_b(x, treatment, block))
    direct = cochran_q_test_group(
        x,
        as.character(treatment),
        as.character(block)
    )

    expect_equal(
        unname(piped@data@statistic),
        direct$statistic,
        tolerance = 1e-8
    )
    expect_equal(unname(piped@data@p_value), direct$p_value, tolerance = 1e-8)
    expect_equal(unname(piped@data@df), direct$df)
    expect_equal(unname(piped@data@n_groups), direct$n_groups)
})

test_that("COCHRAN_QTEST(x_by_b())'s freq_table matches table(group, x) for the first grouping variable", {
    set.seed(123)
    x = sample(0:1, 45, replace = TRUE)
    treatment = gl(3, 1, 45, labels = c("A", "B", "C"))
    block = gl(15, 3, labels = 1:15)

    piped = COCHRAN_QTEST(x_by_b(x, treatment, block))

    ref_freq_table = as.matrix(table(treatment, x))

    expect_equal(piped@data@freq_table, ref_freq_table, ignore_attr = TRUE)
})

test_that("COCHRAN_QTEST(x_by_b()) with multiple grouping variables runs one test per group", {
    set.seed(123)
    x = sample(0:1, 45, replace = TRUE)
    treatment = gl(3, 1, 45, labels = c("A", "B", "C"))
    treatment2 = gl(5, 1, 45, labels = c("C", "D", "E", "F", "G"))
    block = gl(5, 3, 45, labels = 1:5)

    piped = COCHRAN_QTEST(x_by_b(x, c(treatment, treatment2), block))

    direct_treatment = cochran_q_test_group(
        x,
        as.character(treatment),
        as.character(block)
    )
    direct_treatment2 = cochran_q_test_group(
        x,
        as.character(treatment2),
        as.character(block)
    )

    expect_equal(unname(piped@data@vars), c("treatment", "treatment2"))
    expect_equal(
        unname(piped@data@statistic),
        c(direct_treatment$statistic, direct_treatment2$statistic),
        tolerance = 1e-8
    )
    expect_equal(
        unname(piped@data@df),
        c(direct_treatment$df, direct_treatment2$df)
    )
    expect_equal(
        unname(piped@data@p_value),
        c(direct_treatment$p_value, direct_treatment2$p_value),
        tolerance = 1e-8
    )
    expect_equal(unname(piped@data@n_groups), c(3L, 5L))
})

test_that("COCHRAN_QTEST(x_by_b()) with multiple grouping variables keeps only the first group's freq_table", {
    set.seed(123)
    x = sample(0:1, 45, replace = TRUE)
    treatment = gl(3, 1, 45, labels = c("A", "B", "C"))
    treatment2 = gl(5, 1, 45, labels = c("C", "D", "E", "F", "G"))
    block = gl(5, 3, 45, labels = 1:5)

    piped = COCHRAN_QTEST(x_by_b(x, c(treatment, treatment2), block))

    ref_freq_table = as.matrix(table(treatment, x))

    expect_equal(piped@data@freq_table, ref_freq_table, ignore_attr = TRUE)
    expect_equal(nrow(piped@data@freq_table), 3)
})
