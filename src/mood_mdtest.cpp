#include <algorithm>
#include <numeric>
#include <vector>
#include <unordered_map>
#include <boost/math/distributions/chi_squared.hpp>
#include <Rcpp.h>
#include "mood_mdtest.h"

// [[Rcpp::depends(BH)]]

using Rcpp::as;
using Rcpp::List;
using Rcpp::Named;
using Rcpp::NumericVector;
using Rcpp::CharacterVector;
using Rcpp::IntegerMatrix;
using Rcpp::Nullable;
using Rcpp::stop;
using Rcpp::warning;
using Rcpp::clone;

double quickselect_median(NumericVector x) {
    size_t n = x.size();
    size_t k = n / 2;
    NumericVector x_copy = clone(x);

    std::nth_element(x_copy.begin(), x_copy.begin() + k, x_copy.end());

    if (n % 2 == 0) {
        double right = x_copy[k];
        std::nth_element(x_copy.begin(), x_copy.begin() + k - 1, x_copy.end());
        double left = x_copy[k - 1];
        return (left + right) / 2.0;
    }
    return x_copy[k];
}

// row 1 = value <= med (below-or-equal), row 0 = value > med (above).
// compute_mood's k == 1 branch must match this orientation.
IntegerMatrix create_contingency_table(const double* values, const int* group_indices, int n_total, int k, double med) {
    IntegerMatrix cont_table(2, k);
    for (int i = 0; i < n_total; ++i) {
        cont_table(values[i] <= med, group_indices[i])++;
    }
    return cont_table;
}

double chi_square(const IntegerMatrix& cont_table) {
    double n = sum(cont_table);
    double chi_sq = 0.0;
    NumericVector row_sums(2);
    NumericVector col_sums(cont_table.ncol());

    for (int i = 0; i < 2; ++i) {
        for (int j = 0; j < cont_table.ncol(); ++j) {
            row_sums[i] += cont_table(i, j);
            col_sums[j] += cont_table(i, j);
        }
    }

    for (int i = 0; i < 2; ++i) {
        for (int j = 0; j < cont_table.ncol(); ++j) {
            double observed = cont_table(i, j);
            double expected = (row_sums[i] * col_sums[j]) / n;

            if (expected > 0 && observed >= 0) {
                double diff = observed - expected;
                chi_sq += (diff * diff) / expected;
            }
        }
    }

    return std::max(0.0, chi_sq);
}

double calculate_p_value(double chi_sq, int df) {
    try {
        boost::math::chi_squared_distribution<> dist(df);
        return 1.0 - boost::math::cdf(dist, chi_sq);
    } catch (const std::exception& e) {
        warning("Error calculating p-value: %s. Returning NA.", e.what());
        return NA_REAL;
    }
}

mdtObject compute_mood(
        const double* values,
        const int* group_indices,
        int n_total,
        int k,
        double med
) {
    IntegerMatrix cont_table = create_contingency_table(values, group_indices, n_total, k, med);

    double chi_sq;
    int df;

    if (k == 1) {
        // The generic 2xk chi-square test is degenerate at k == 1: with a
        // single column, expected always equals observed and chi_sq is
        // identically 0. This branch instead compares the group's counts
        // against a hypothesized 50/50 split, so it's only meaningful when
        // `med` is a hypothesized value rather than the sample's own median.
        int above = cont_table(0, 0);
        int below_or_equal = cont_table(1, 0);
        double expected = n_total / 2.0;

        chi_sq = 0.0;
        if (expected > 0.0) {
            double diff_above = above - expected;
            double diff_below = below_or_equal - expected;
            chi_sq = (diff_above * diff_above + diff_below * diff_below) / expected;
        }
        df = 1;
    } else {
        chi_sq = chi_square(cont_table);
        df = k - 1;
    }

    double p_value = calculate_p_value(chi_sq, df);

    return {chi_sq, p_value, static_cast<double>(df), cont_table, med};
}

// [[Rcpp::export]]
List mood_median_test_cpp(const List& groups, Nullable<double> custom_median = R_NilValue) {
    int k = groups.size();
    if (k == 0) {
        stop("No groups provided.");
    }

    int n_total = 0;
    for (int i = 0; i < k; ++i) {
        NumericVector grp = as<NumericVector>(groups[i]);
        if (grp.size() == 0) {
            stop("Empty group detected.");
        }
        n_total += grp.size();
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

    double med;
    if (custom_median.isNotNull()) {
        med = as<double>(custom_median);
    } else {
        NumericVector all_data(values.begin(), values.end());
        med = quickselect_median(all_data);
    }

    mdtObject mdt = compute_mood(values.data(), group_indices.data(), n_total, k, med);

    IntegerMatrix cont_table = mdt.cont_tab;
    CharacterVector group_names = groups.names();
    if (group_names.size() == k) {
        Rcpp::colnames(cont_table) = group_names;
    }

    return List::create(
        Named("statistic") = mdt.statistic,
        Named("df") = mdt.df,
        Named("p_value") = mdt.p_value,
        Named("cont_table") = cont_table,
        Named("median") = mdt.median,
        Named("n_groups") = k
    );
}

// [[Rcpp::export]]
List mood_median_test_group(const NumericVector& x, const CharacterVector& g, Nullable<double> custom_median = R_NilValue) {
    if (x.size() != g.size()) {
        stop("Lengths of 'x' and 'g' must match.");
    }

    int n_total = x.size();

    std::unordered_map<Rcpp::String, int> group_map;
    std::vector<std::string> group_names;

    for (int i = 0; i < n_total; ++i) {
        Rcpp::String label = g[i];
        if (group_map.find(label) == group_map.end()) {
            group_map[label] = static_cast<int>(group_names.size());
            group_names.push_back(label);
        }
    }
    int k = static_cast<int>(group_names.size());

    std::vector<double> values(x.begin(), x.end());
    std::vector<int> group_indices(n_total);
    for (int i = 0; i < n_total; ++i) {
        group_indices[i] = group_map[g[i]];
    }

    double med;
    if (custom_median.isNotNull()) {
        med = as<double>(custom_median);
    } else {
        med = quickselect_median(x);
    }

    mdtObject mdt = compute_mood(values.data(), group_indices.data(), n_total, k, med);

    IntegerMatrix cont_table = mdt.cont_tab;
    Rcpp::colnames(cont_table) = Rcpp::wrap(group_names);

    return List::create(
        Named("statistic") = mdt.statistic,
        Named("df") = mdt.df,
        Named("p_value") = mdt.p_value,
        Named("cont_table") = cont_table,
        Named("median") = mdt.median,
        Named("n_groups") = k
    );
}
