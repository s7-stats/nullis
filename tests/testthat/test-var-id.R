# ---- x_by_b: construction ----

test_that("x_by_b() produces an x_by_b/<var_id> object", {
    m = x_by_b(extra, group, block)

    expect_s7_class(m, x_by_b)
    expect_s7_class(m, statim::var_id)
})

test_that("x_by_b() stores quosures in @x, @group, and @block", {
    m = x_by_b(extra, group, block)

    expect_true(rlang::is_quosure(m@x))
    expect_true(rlang::is_quosure(m@group))
    expect_true(rlang::is_quosure(m@block))
})

test_that("x_by_b() does not validate expression shape at construction", {
    # @x/@group/@block are class_any, so garbage expressions are accepted
    # silently. Validation only happens later, when model_processor() runs.
    m = x_by_b(sqrt(extra), group, block)

    expect_s7_class(m, x_by_b)
    expect_true(rlang::is_quosure(m@x))
})

test_that("x_by_b() captures the calling environment in each quosure", {
    m = local({
        local_val = 99
        x_by_b(local_val, group, block)
    })

    expect_identical(rlang::eval_tidy(m@x), 99)
})

# ---- model_processor(x_by_b) ----

test_that("model_processor() resolves bare-name x/group/block without data", {
    extra = 1:5
    group = letters[1:5]
    block = rep(1, 5)

    m = x_by_b(extra, group, block)
    out = model_processor(m)

    expect_named(out, c("x_data", "group_data", "block_data"))
    expect_equal(out$x_data$extra, 1:5)
    expect_equal(out$group_data$group, letters[1:5])
    expect_equal(out$block_data$block, rep(1, 5))
})

test_that("model_processor() resolves c()-wrapped x/group/block without data", {
    a = 1:3
    b = 4:6
    grp = c("x", "y", "z")
    blk = c(1, 1, 2)

    m = x_by_b(c(a, b), grp, blk)
    out = model_processor(m)

    expect_named(out$x_data, c("a", "b"))
    expect_equal(out$x_data$a, 1:3)
    expect_equal(out$x_data$b, 4:6)
})

test_that("model_processor() resolves bare names via tidyselect when data is supplied", {
    df = data.frame(extra = 1:3, group = c("a", "a", "b"), block = c(1, 1, 2))
    m = x_by_b(extra, group, block)

    out = model_processor(m, data = df)

    expect_equal(out$x_data$extra, df$extra)
    expect_equal(out$group_data$group, df$group)
    expect_equal(out$block_data$block, df$block)
})

test_that("model_processor() resolves a c() of names via tidyselect when data is supplied", {
    df = data.frame(x1 = 1:3, x2 = 4:6, g = c("a", "a", "b"), blk = c(1, 1, 2))
    m = x_by_b(c(x1, x2), g, blk)

    out = model_processor(m, data = df)

    expect_named(out$x_data, c("x1", "x2"))
})

test_that("model_processor() resolves a tidyselect helper only when data is supplied", {
    df = data.frame(x1 = 1:3, x2 = 4:6, g = c("a", "a", "b"), blk = c(1, 1, 2))
    m = x_by_b(tidyselect::starts_with("x"), g, blk)

    out = model_processor(m, data = df)

    expect_named(out$x_data, c("x1", "x2"))
    expect_equal(out$group_data$g, df$g)
    expect_equal(out$block_data$blk, df$blk)
})

test_that("model_processor() errors on a non-symbol, non-c() expression without data", {
    m = x_by_b(sqrt(extra), group, block)

    expect_error(model_processor(m), "Invalid input in model ID")
})

test_that("model_processor() rejects a tidyselect helper when data is not supplied", {
    m = x_by_b(tidyselect::starts_with("x"), group, block)

    expect_error(model_processor(m), "Invalid input in model ID")
})

test_that("model_processor() errors on an unmatched column name when data is supplied", {
    df = data.frame(extra = 1:3, group = c("a", "a", "b"), block = c(1, 1, 2))
    m = x_by_b(not_a_column, group, block)

    expect_error(model_processor(m, data = df))
})

# ---- var_id_info(x_by_b) ----

test_that("var_id_info() builds the arg string as 'x | group <=> [ block ]'", {
    m = x_by_b(extra, group, block)

    info = var_id_info(m)

    expect_equal(info@args, "extra | group <=> [ block ]")
})

test_that("var_id_info() with c()-wrapped x joins names with commas in the arg string", {
    m = x_by_b(c(a, b), group, block)

    info = var_id_info(m)

    expect_equal(info@args, "a, b | group <=> [ block ]")
})

test_that("var_id_info() leaves other_info and vars empty when processed is NULL", {
    m = x_by_b(extra, group, block)

    info = var_id_info(m)

    expect_equal(info@other_info, list())
    expect_equal(info@vars, list())
})

test_that("var_id_info() leaves other_info and vars empty when processed has length 0", {
    m = x_by_b(extra, group, block)

    info = var_id_info(m, processed = list())

    expect_equal(info@other_info, list())
    expect_equal(info@vars, list())
})

test_that("var_id_info() populates other_info with column counts from processed data", {
    df = data.frame(x1 = 1:3, x2 = 4:6, g = c("a", "a", "b"), blk = c(1, 1, 2))
    m = x_by_b(c(x1, x2), g, blk)
    processed = model_processor(m, data = df)

    info = var_id_info(m, processed = processed)

    expect_equal(info@other_info$x_vars, 2)
    expect_equal(info@other_info$by_vars, 1)
    expect_equal(info@other_info$block_vars, 1)
})

test_that("var_id_info() populates vars with one preview entry per column, in x/group/block order", {
    df = data.frame(x1 = 1:3, g = c("a", "a", "b"), blk = c(1, 1, 2))
    m = x_by_b(x1, g, blk)
    processed = model_processor(m, data = df)

    info = var_id_info(m, processed = processed)

    expect_length(info@vars, 3)
    expect_equal(vapply(info@vars, `[[`, character(1), "name"), c("x1", "g", "blk"))
})

test_that("var_id_info() always marks registered = TRUE", {
    m = x_by_b(extra, group, block)

    expect_true(var_id_info(m)@registered)
})

test_that("var_id_info() stores the original var_id object on the returned object", {
    m = x_by_b(extra, group, block)

    info = var_id_info(m)

    expect_identical(info@var_id, m)
})
