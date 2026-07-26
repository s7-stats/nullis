#!/usr/bin/env rscript

box::use(
    statim[define_model, x_by, on, prepare, via, conclude, tidy],
    nullis[KW_TEST],
    tibble[tbl = tibble],
    purrr[imap_dfr],
)

data_list = list(
    x1 = c(83, 91, 94, 89, 89, 96, 91, 92, 90),
    x2 = c(91, 90, 81, 83, 84, 83, 88, 91, 89, 84),
    x3 = c(101, 100, 91, 93, 96, 95, 94),
    x4 = c(78, 82, 81, 77, 79, 81, 80, 81)
)

df = imap_dfr(data_list, \(x, i) tbl(group = i, value = x))
init =
    df |>
    define_model(x_by(value, group)) |>
    prepare(KW_TEST)

cat("Kruskal-Wallis Test: \n\n")
conclude(init)
cat("\n\n")

cat("Pairwise Kruskal-Wallis Test: \n\n")
init |>
    via("pairwise", p_adj_method = "bonferroni") |>
    conclude() |>
    tidy()
cat("\n\n")

# You don't need to transform it into long format
# statim already has `on()`
cat("Kruskal-Wallis Test (one-liner) with `on()`: \n\n")
KW_TEST(on(x1, x2, x3, x4), data_list)
