S7::method(model_processor, x_by_b) = function(x, data = NULL, ...) {
    x_data = if (!is.null(data) && is.data.frame(data)) {
        cols = tidyselect::eval_select(expr = x@x, data = data)
        data[, cols, drop = FALSE]
    } else {
        quo_resolver(x@x)
    }
    group_data = if (!is.null(data) && is.data.frame(data)) {
        cols = tidyselect::eval_select(expr = x@group, data = data)
        data[, cols, drop = FALSE]
    } else {
        quo_resolver(x@group)
    }
    block_data = if (!is.null(data) && is.data.frame(data)) {
        cols = tidyselect::eval_select(expr = x@block, data = data)
        data[, cols, drop = FALSE]
    } else {
        quo_resolver(x@block)
    }

    list(x_data = x_data, group_data = group_data, block_data = block_data)
}

quo_resolver = function(quo) {
    expr = rlang::quo_get_expr(quo)
    env = rlang::quo_get_env(quo)

    if (rlang::is_symbol(expr)) {
        nm = rlang::as_string(expr)
        vctrs::new_data_frame(
            list(rlang::eval_tidy(expr, env = env)) |> rlang::set_names(nm)
        )
    } else if (rlang::is_call(expr, "c")) {
        vars = as.list(expr[-1])
        nms = vapply(vars, rlang::as_string, character(1))
        lapply(vars, function(v) {
            rlang::eval_tidy(rlang::new_quosure(v, env = env), env = env)
        }) |>
            rlang::set_names(nms) |>
            vctrs::new_data_frame()
    } else {
        expr_lbl = rlang::as_label(quo)
        cli::cli_abort(c(
            "Invalid input in model ID: {.code {expr_lbl}}.",
            "i" = "Use bare names or {.code c()} for column references."
        ))
    }
}
