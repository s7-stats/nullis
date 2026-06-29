#include <algorithm>
#include <numeric>
#include <vector>
#include <unordered_map>
#include <boost/math/distributions/chi_squared.hpp>
#include <Rcpp.h>
#include "kw.h"

// [[Rcpp::depends(BH)]]

using Rcpp::as;
using Rcpp::List;
using Rcpp::Named;
using Rcpp::NumericVector;
using Rcpp::CharacterVector;
using Rcpp::stop;
using Rcpp::warning;

kwObject compute_kw(
        const double* values,
        const int* group_indices,
        int n_total,
        int k
) {
    std::vector<size_t> indices(n_total);
    std::vector<double> group_rank_sums(k, 0.0);
    std::vector<int> group_sizes(k, 0);

    std::iota(indices.begin(), indices.end(), 0);
    std::sort(
        indices.begin(),
        indices.end(),
        [values](size_t a, size_t b) { return values[a] < values[b]; }
    );

    for (int i = 0; i < n_total; ++i) {
        group_sizes[group_indices[indices[i]]]++;
    }

    double expected_rank_mean = (n_total + 1.0) / 2.0;
    double tie_correction = 0.0;

    // Values originate from R's NumericVector (IEEE 754), so exact equality
    // comparison is valid for detecting ties in the sorted order
    for (int i = 0; i < n_total;) {
        int j = i + 1;
        while (j < n_total && values[indices[i]] == values[indices[j]]) ++j;

        double avg_rank = (i + j - 1) / 2.0 + 1.0;

        if (j - i > 1) {
            double t = j - i;
            tie_correction += t * t * t - t;
        }

        for (int x = i; x < j; ++x) {
            int grp = group_indices[indices[x]];
            group_rank_sums[grp] += (avg_rank - expected_rank_mean);
        }

        i = j;
    }

    double h = 0.0;
    double n_plus_1 = n_total + 1.0;

    for (int i = 0; i < k; ++i) {
        if (group_sizes[i] > 0) {
            double d = group_rank_sums[i];
            h += (d * d) / group_sizes[i];
        }
    }
    h *= 12.0 / (n_total * n_plus_1);

    if (tie_correction > 0.0) {
        double denom = static_cast<double>(n_total) * n_total * n_total - n_total;
        double tie_factor = 1.0 - (tie_correction / denom);
        if (tie_factor > 0.0) h /= tie_factor;
    }

    h = std::max(0.0, h);
    double df = static_cast<double>(k - 1);

    double p_value;
    try {
        boost::math::chi_squared_distribution<double> chi2(df);
        p_value = boost::math::cdf(boost::math::complement(chi2, h));
    } catch (const std::exception& e) {
        warning("Chi-squared p-value computation failed: %s. Returning NA.", e.what());
        p_value = NA_REAL;
    }

    return {h, p_value, df};
}

// [[Rcpp::export]]
List kruskal_wallis_cpp(const List& groups) {
    int k = groups.size();
    int n_total = 0;

    for (int i = 0; i < k; ++i) {
        n_total += as<NumericVector>(groups[i]).size();
    }

    std::vector<double> values(n_total);
    std::vector<int> group_indices(n_total);

    int offset = 0;
    for (int i = 0; i < k; ++i) {
        NumericVector grp = as<NumericVector>(groups[i]);
        int grp_size = grp.size();
        std::copy(grp.begin(), grp.end(), values.begin() + offset);
        std::fill(group_indices.begin() + offset, group_indices.begin() + offset + grp_size, i);
        offset += grp_size;
    }

    kwObject kw = compute_kw(values.data(), group_indices.data(), n_total, k);

    return List::create(
        Named("statistic") = kw.h,
        Named("p_value") = kw.p_value,
        Named("df") = kw.df
    );
}

// [[Rcpp::export]]
List kruskal_wallis_group(const NumericVector& x, const CharacterVector& g) {
    if (x.size() != g.size()) {
        stop("Lengths of 'x' and 'g' must match.");
    }

    int n_total = x.size();

    std::unordered_map<Rcpp::String, int> group_map;
    for (int i = 0; i < n_total; ++i) {
        if (group_map.find(g[i]) == group_map.end()) {
            group_map[g[i]] = static_cast<int>(group_map.size());
        }
    }
    int k = static_cast<int>(group_map.size());

    std::vector<double> values(x.begin(), x.end());
    std::vector<int> group_indices(n_total);
    for (int i = 0; i < n_total; ++i) {
        group_indices[i] = group_map[g[i]];
    }

    kwObject kw = compute_kw(values.data(), group_indices.data(), n_total, k);

    return List::create(
        Named("statistic") = kw.h,
        Named("p_value") = kw.p_value,
        Named("df") = kw.df
    );
}
