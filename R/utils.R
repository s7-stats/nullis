`%||%` = function(x, y) {
    if (is.null(x)) y else x
}

`%notin%` = Negate(`%in%`)
pval_styler = function(x) {
    x_num = suppressWarnings(as.numeric(x$value))
    if (is.na(x_num) || x_num > 0.05) {
        cli::style_italic(x$value)
    } else if (x_num > 0.01) {
        cli::col_red(x$value)
    } else {
        cli::style_bold("<0.001")
    }
}
