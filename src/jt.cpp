#include <algorithm>
#include <numeric>
#include <vector>
#include <map>
#include <cmath>
#include <Rcpp.h>
#include "jt.h"

using Rcpp::as;
using Rcpp::List;
using Rcpp::Named;
using Rcpp::NumericVector;
using Rcpp::IntegerVector;
using Rcpp::stop;

static int count_less_than(const std::vector<double>& sorted, double x) {
    return static_cast<int>(
        std::lower_bound(sorted.begin(), sorted.end(), x) - sorted.begin()
    );
}

static int count_equal(const std::vector<double>& sorted, double x) {
    auto range = std::equal_range(sorted.begin(), sorted.end(), x);
    return static_cast<int>(range.second - range.first);
}

double jt_stat(const NumericVector& x, const IntegerVector& g) {
    int n = x.size();

    std::vector<int> indices(n);
    std::iota(indices.begin(), indices.end(), 0);
    std::stable_sort(indices.begin(), indices.end(),
                     [&g](int i, int j) { return g[i] < g[j]; });

    std::vector<int> group_sizes;
    std::vector<int> group_starts;
    int current_group = g[indices[0]];
    int current_start = 0;

    for (int i = 0; i < n; ++i) {
        if (g[indices[i]] != current_group) {
            group_sizes.push_back(i - current_start);
            group_starts.push_back(current_start);
            current_group = g[indices[i]];
            current_start = i;
        }
    }
    group_sizes.push_back(n - current_start);
    group_starts.push_back(current_start);

    int n_groups = static_cast<int>(group_starts.size());
    double statistic = 0.0;

    for (int i = 0; i < n_groups - 1; ++i) {
        std::vector<double> current_vals;
        current_vals.reserve(group_sizes[i]);
        for (int j = 0; j < group_sizes[i]; ++j) {
            current_vals.push_back(x[indices[group_starts[i] + j]]);
        }
        std::sort(current_vals.begin(), current_vals.end());

        for (int k = i + 1; k < n_groups; ++k) {
            for (int j = 0; j < group_sizes[k]; ++j) {
                double val = x[indices[group_starts[k] + j]];
                statistic += count_less_than(current_vals, val) + 0.5 * count_equal(current_vals, val);
            }
        }
    }

    return statistic;
}

std::vector<double> jt_pdf(const std::vector<int>& group_sizes) {
    int ng = static_cast<int>(group_sizes.size());

    std::vector<int> cumulative(ng);
    std::partial_sum(group_sizes.rbegin(), group_sizes.rend(), cumulative.rbegin());

    int max_stat = 0;
    for (int i = 0; i < ng - 1; ++i) {
        max_stat += group_sizes[i] * cumulative[i + 1];
    }
    max_stat++;

    std::vector<double> pdf(max_stat, 0.0);
    std::vector<double> pdf_prev(max_stat, 0.0);
    std::vector<double> pdf_mw(max_stat, 0.0);

    int m = group_sizes[ng - 2];
    int n = group_sizes[ng - 1];
    int mn = m * n;
    for (int i = 0; i <= mn; ++i) {
        pdf[i] = R::dwilcox(i, m, n, false);
    }

    int mn_prev = mn;

    for (int g = ng - 3; g >= 0; --g) {
        std::copy(pdf.begin(), pdf.end(), pdf_prev.begin());
        std::fill(pdf.begin(), pdf.end(), 0.0);

        m = group_sizes[g];
        n = cumulative[g + 1];
        mn = m * n;

        for (int i = 0; i <= mn; ++i) {
            pdf_mw[i] = R::dwilcox(i, m, n, false);
        }

        for (int i = 0; i <= mn; ++i) {
            for (int j = 0; j <= mn_prev; ++j) {
                pdf[i + j] += pdf_mw[i] * pdf_prev[j];
            }
        }

        mn_prev = mn + mn_prev;
    }

    return pdf;
}

jtObject compute_jt(
        const NumericVector& values,
        const IntegerVector& groups,
        const std::string& alternative,
        bool approximate
) {
    int n = values.size();

    double statistic = jt_stat(values, groups);

    std::map<int, int> group_size_map;
    for (int g : groups) group_size_map[g]++;

    std::vector<int> group_sizes;
    group_sizes.reserve(group_size_map.size());
    for (const auto& pair : group_size_map) {
        group_sizes.push_back(pair.second);
    }

    long double mean = 0.0L;
    long double variance = 0.0L;
    int running = 0;

    for (size_t i = 0; i < group_sizes.size() - 1; ++i) {
        long double ni = static_cast<long double>(group_sizes[i]);
        long double nj = static_cast<long double>(n - running - group_sizes[i]);
        mean += (ni * nj) / 2.0L;
        variance += (ni * nj * (ni + nj + 1.0L)) / 12.0L;
        running += group_sizes[i];
    }

    double final_mean = static_cast<double>(mean);
    double final_variance = static_cast<double>(variance);
    double z = (statistic - final_mean) / std::sqrt(final_variance);

    bool use_approximate = approximate || n > 50;
    std::string method;
    double p_value;

    if (!use_approximate) {
        method = "exact";
        std::vector<double> pdf = jt_pdf(group_sizes);
        int jt_int = static_cast<int>(std::round(statistic));

        double p_lower = std::accumulate(pdf.begin(), pdf.begin() + jt_int, 0.0);
        double p_upper = std::accumulate(pdf.begin() + jt_int, pdf.end(), 0.0);

        if (alternative == "two.sided") {
            p_value = 2.0 * std::min(p_lower, p_upper);
        } else if (alternative == "increasing") {
            p_value = p_upper;
        } else if (alternative == "decreasing") {
            p_value = p_lower;
        } else {
            stop("Invalid alternative. Choose 'two.sided', 'increasing', or 'decreasing'.");
        }
    } else {
        method = "normal approximation";
        if (alternative == "two.sided") {
            p_value = 2.0 * R::pnorm(-std::abs(z), 0.0, 1.0, true, false);
        } else if (alternative == "increasing") {
            p_value = R::pnorm(z, 0.0, 1.0, false, false);
        } else if (alternative == "decreasing") {
            p_value = R::pnorm(z, 0.0, 1.0, true, false);
        } else {
            stop("Invalid alternative. Choose 'two.sided', 'increasing', or 'decreasing'.");
        }
    }

    return {statistic, final_mean, final_variance, z, p_value, use_approximate, method};
}

// [[Rcpp::export]]
List jonckheere_terpstra_test(
        const NumericVector& values,
        const IntegerVector& groups,
        std::string alternative = "two.sided",
        bool approximate = false
) {
    if (values.size() != groups.size()) {
        stop("Lengths of 'values' and 'groups' must match.");
    }

    jtObject jt = compute_jt(values, groups, alternative, approximate);

    return List::create(
        Named("statistic") = jt.statistic,
        Named("mean") = jt.mean,
        Named("variance") = jt.variance,
        Named("z.score") = jt.z_score,
        Named("p.value") = jt.p_value,
        Named("alternative") = alternative,
        Named("approximate") = jt.approximate,
        Named("method") = jt.method
    );
}

// [[Rcpp::export]]
List jonckheere_terpstra_test_groups(
        const List& groups,
        std::string alternative = "two.sided",
        bool approximate = false
) {
    int n_groups = groups.size();
    int total = 0;
    for (int i = 0; i < n_groups; ++i) {
        total += as<NumericVector>(groups[i]).size();
    }

    NumericVector values(total);
    IntegerVector group_indices(total);
    int offset = 0;

    for (int i = 0; i < n_groups; ++i) {
        NumericVector grp = as<NumericVector>(groups[i]);
        int grp_size = grp.size();
        std::copy(grp.begin(), grp.end(), values.begin() + offset);
        std::fill(group_indices.begin() + offset, group_indices.begin() + offset + grp_size, i + 1);
        offset += grp_size;
    }

    if (values.size() != group_indices.size()) {
        stop("Lengths of 'values' and 'groups' must match.");
    }

    jtObject jt = compute_jt(values, group_indices, alternative, approximate);

    return List::create(
        Named("statistic") = jt.statistic,
        Named("mean") = jt.mean,
        Named("variance") = jt.variance,
        Named("z.score") = jt.z_score,
        Named("p.value") = jt.p_value,
        Named("alternative") = alternative,
        Named("approximate") = jt.approximate,
        Named("method") = jt.method
    );
}
