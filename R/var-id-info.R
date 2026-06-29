S7::method(var_id_info, x_by_block) = function(.var_id, processed = NULL, ...) {
    x_lbl = format_quo_label(.var_id@x)
    g_lbl = format_quo_label(.var_id@group)
    b_lbl = format_quo_label(.var_id@block)

    other_info = list()
    vars = list()

    if (!is.null(processed) && length(processed)) {
        other_info = list(
            x_vars = ncol(processed$x_data),
            by_vars = ncol(processed$group_data),
            block_vars = ncol(processed$block_data)
        )
        vars = vars_preview(c(
            as.list(processed$x_data),
            as.list(processed$group_data),
            as.list(processed$block_data)
        ))
    }

    statim::class_var_inform(
        var_id = .var_id,
        args = paste0(x_lbl, " | ", g_lbl, " <=> ", "[ ", b_lbl, " ]"),
        other_info = other_info,
        vars = vars,
        registered = TRUE
    )
}

format_quo_label = function(quo) {
    cl = classify_quo(quo)
    switch(
        cl$type,
        ":symbol" = as.character(cl$expr),
        ":c_call" = paste(
            vapply(as.list(cl$expr[-1]), as.character, character(1)),
            collapse = ", "
        ),
        ":i_call" = "<inline>",
        ":inlines_call" = "<inlines>",
        ":tidyselect" = deparse(cl$expr),
        rlang::as_label(quo)
    )
}

vars_preview = function(cols) {
    lapply(seq_along(cols), function(i) {
        val = cols[[i]]
        list(
            name = names(cols)[[i]],
            preview = paste0(
                "<",
                pillar::type_sum(val),
                " [",
                length(val),
                "]>"
            )
        )
    })
}

classify_quo = function(quo) {
    expr = rlang::quo_get_expr(quo)
    env = rlang::quo_get_env(quo)

    type = if (rlang::is_missing(expr)) {
        ":error"
    } else if (is.symbol(expr)) {
        ":symbol"
    } else if (rlang::is_call(expr, "c")) {
        args = as.list(expr[-1])
        all_symbols = all(vapply(args, is.symbol, logical(1)))
        if (!all_symbols) ":error" else ":c_call"
    } else {
        ":error"
    }

    list(type = type, expr = expr, env = env)
}
