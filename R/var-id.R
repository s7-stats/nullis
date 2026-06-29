#' Compare a variable by group given block
#'
#' An extended version of [statim::x_by()] which adds `block`, used on statistical
#' inference pipeline that applies blocking
#'
#' @param x The response variable. Accepts a bare name, a `c()` of bare
#'   names, or a tidyselect helper (requires a `data` data frame).
#' @param group The grouping variable. Same rules as `x`.
#' @param block The blocking variable. Same rules as `x`.
#'
#' @return An `x_by_block` / `var_id` S7 object.
#'
#' @examples
#' x_by_block(x, g, blocking)
#'
#' @export
x_by_block = S7::new_class(
    "x_by_block",
    parent = statim::x_by,
    properties = list(
        x = S7::class_any,
        group = S7::class_any,
        block = S7::class_any
    ),
    constructor = function(x, group, block) {
        S7::new_object(
            S7::S7_object(),
            x = rlang::enquo(x),
            group = rlang::enquo(group),
            block = rlang::enquo(block)
        )
    }
)
