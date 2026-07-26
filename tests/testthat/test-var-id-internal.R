# ---- quo_resolver() ----

test_that("quo_resolver() resolves a bare symbol into a one-column data frame", {
    extra = c(1, 2, 3)
    q = rlang::new_quosure(quote(extra), env = environment())

    out = quo_resolver(q)

    expect_s3_class(out, "data.frame")
    expect_named(out, "extra")
    expect_equal(out$extra, c(1, 2, 3))
})

test_that("quo_resolver() resolves a c() call into a multi-column data frame", {
    a = c(1, 2)
    b = c(3, 4)
    q = rlang::new_quosure(quote(c(a, b)), env = environment())

    out = quo_resolver(q)

    expect_s3_class(out, "data.frame")
    expect_named(out, c("a", "b"))
    expect_equal(out$a, c(1, 2))
    expect_equal(out$b, c(3, 4))
})

test_that("quo_resolver() errors on anything other than a symbol or c()", {
    q = rlang::new_quosure(quote(sqrt(x)), env = environment())

    expect_error(quo_resolver(q), class = "rlang_error")
})

test_that("quo_resolver() error message names the offending expression", {
    q = rlang::new_quosure(quote(sqrt(x)), env = environment())

    expect_error(quo_resolver(q), "sqrt\\(x\\)")
})

test_that("quo_resolver() errors on a tidyselect helper when no data is present", {
    q = rlang::new_quosure(quote(tidyselect::starts_with("x")), env = environment())

    expect_error(quo_resolver(q), "Invalid input in model ID")
})

# ---- classify_quo() / format_quo_label() ----

test_that("classify_quo() tags a bare symbol as :symbol", {
    q = rlang::new_quosure(quote(extra), env = environment())

    expect_equal(classify_quo(q)$type, ":symbol")
})

test_that("classify_quo() tags a c() of bare symbols as :c_call", {
    q = rlang::new_quosure(quote(c(a, b)), env = environment())

    expect_equal(classify_quo(q)$type, ":c_call")
})

test_that("classify_quo() tags a c() containing a non-symbol as :error", {
    q = rlang::new_quosure(quote(c(a, sqrt(b))), env = environment())

    expect_equal(classify_quo(q)$type, ":error")
})

test_that("classify_quo() has no branch for tidyselect helpers", {
    q = rlang::new_quosure(quote(tidyselect::starts_with("x")), env = environment())

    expect_equal(classify_quo(q)$type, ":error")
})

test_that("format_quo_label() labels a bare symbol as its name", {
    q = rlang::new_quosure(quote(extra), env = environment())

    expect_equal(format_quo_label(q), "extra")
})

test_that("format_quo_label() labels a c() call as a comma-separated list", {
    q = rlang::new_quosure(quote(c(a, b)), env = environment())

    expect_equal(format_quo_label(q), "a, b")
})

test_that("format_quo_label() falls back to rlang::as_label() for a tidyselect helper", {
    # since classify_quo() never returns ":tidyselect", the explicit
    # ":tidyselect" = deparse(cl$expr) branch inside format_quo_label() is
    # dead code; this pins down what actually happens instead (the switch()
    # default).
    q = rlang::new_quosure(quote(tidyselect::starts_with("x")), env = environment())

    expect_equal(format_quo_label(q), rlang::as_label(q))
})

test_that("format_quo_label() falls back to rlang::as_label() for a malformed c()", {
    q = rlang::new_quosure(quote(c(a, sqrt(b))), env = environment())

    expect_equal(format_quo_label(q), rlang::as_label(q))
})

# ---- vars_preview() ----

test_that("vars_preview() formats each column as <type [length]>", {
    cols = list(n = 1:3, s = c("a", "b"))

    out = vars_preview(cols)

    expect_equal(out[[1]]$name, "n")
    expect_equal(out[[1]]$preview, paste0("<", pillar::type_sum(1:3), " [3]>"))
    expect_equal(out[[2]]$name, "s")
    expect_equal(out[[2]]$preview, paste0("<", pillar::type_sum(c("a", "b")), " [2]>"))
})

test_that("vars_preview() returns an empty list for an empty input", {
    expect_equal(vars_preview(list()), list())
})

