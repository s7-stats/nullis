#include <algorithm>
#include <numeric>
#include <vector>
#include <unordered_map>
#include <boost/math/distributions/chi_squared.hpp>
#include <Rcpp.h>
#include "friedman.h"

// [[Rcpp::depends(BH)]]

using Rcpp::as;
using Rcpp::List;
using Rcpp::Named;
using Rcpp::NumericVector;
using Rcpp::NumericMatrix;
using Rcpp::CharacterVector;
using Rcpp::stop;
using Rcpp::warning;

static fmObject compute_fm(
        const double* values,
        int n,
        int k
) {
    std::vector<double> ranks(n * k);

    // Rank within each block (row)
    // Values are stored column-major: treatment t, block i → values[t * n + i]
    for (int i = 0; i < n; ++i) {
        std::vector<size_t> indices(k);
        std::iota(indices.begin(), indices.end(), 0);
        std::sort(indices.begin(), indices.end(),
                  [&](size_t a, size_t b) { return values[a * n + i] < values[b * n + i]; });

        // Handle ties: assign average rank
        for (int j = 0; j < k;) {
            int m = j + 1;
            while (m < k && values[indices[j] * n + i] == values[indices[m] * n + i]) ++m;
            double avg_rank = (j + m - 1) / 2.0 + 1.0;
            for (int x = j; x < m; ++x) {
                ranks[indices[x] * n + i] = avg_rank;
            }
            j = m;
        }
    }

    // Rank sums per treatment
    std::vector<double> rank_sums(k, 0.0);
    for (int i = 0; i < k; ++i) {
        rank_sums[i] = std::accumulate(ranks.begin() + i * n, ranks.begin() + (i + 1) * n, 0.0);
    }

    double sum_sq_ranks = 0.0;
    for (int i = 0; i < k; ++i) {
        sum_sq_ranks += rank_sums[i] * rank_sums[i];
    }

    double statistic = (12.0 / (n * k * (k + 1))) * sum_sq_ranks - 3.0 * n * (k + 1);
    statistic = std::max(0.0, statistic);
    double df = static_cast<double>(k - 1);

    double p_value;
    try {
        boost::math::chi_squared_distribution<double> chi2(df);
        p_value = boost::math::cdf(boost::math::complement(chi2, statistic));
    } catch (const std::exception& e) {
        warning("Chi-squared p-value computation failed: %s. Returning NA.", e.what());
        p_value = NA_REAL;
    }

    return {statistic, p_value, df};
}

// [[Rcpp::export]]
List friedman_test_matrix(const NumericMatrix& data) {
    int n = data.nrow();
    int k = data.ncol();

    // Copy matrix into column-major flat array:
    // treatment t, block i -> values[t * n + i]
    std::vector<double> values(n * k);
    for (int i = 0; i < k; ++i) {
        for (int j = 0; j < n; ++j) {
            values[i * n + j] = data(j, i);
        }
    }

    fmObject fr = compute_fm(values.data(), n, k);

    return List::create(
        Named("statistic") = fr.statistic,
        Named("p_value") = fr.p_value,
        Named("df") = fr.df
    );
}

// [[Rcpp::export]]
List friedman_test_group(
        const NumericVector& x,
        const CharacterVector& treatment,
        const CharacterVector& block
) {
    if (x.size() != treatment.size() || x.size() != block.size()) {
        stop("Lengths of 'x', 'treatment', and 'block' must match.");
    }

    int n_obs = x.size();

    std::unordered_map<Rcpp::String, int> treatment_map;
    std::unordered_map<Rcpp::String, int> block_map;

    for (int i = 0; i < n_obs; ++i) {
        if (treatment_map.find(treatment[i]) == treatment_map.end()) {
            treatment_map[treatment[i]] = static_cast<int>(treatment_map.size());
        }
        if (block_map.find(block[i]) == block_map.end()) {
            block_map[block[i]] = static_cast<int>(block_map.size());
        }
    }

    int k = static_cast<int>(treatment_map.size());
    int n = static_cast<int>(block_map.size());

    std::vector<double> values(n * k, NA_REAL);

    for (int i = 0; i < n_obs; ++i) {
        int t = treatment_map[treatment[i]];
        int b = block_map[block[i]];
        values[t * n + b] = x[i];
    }

    fmObject fr = compute_fm(values.data(), n, k);

    return List::create(
        Named("statistic") = fr.statistic,
        Named("p_value") = fr.p_value,
        Named("df") = fr.df
    );
}
