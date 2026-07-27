#include <algorithm>
#include <numeric>
#include <vector>
#include <unordered_map>
#include <boost/math/distributions/chi_squared.hpp>
#include <cmath>
#include <Rcpp.h>
#include "cq_test.h"

// [[Rcpp::depends(BH)]]

using Rcpp::as;
using Rcpp::List;
using Rcpp::Named;
using Rcpp::NumericVector;
using Rcpp::NumericMatrix;
using Rcpp::CharacterVector;
using Rcpp::stop;
using Rcpp::warning;

cqObject compute_cq(
        const double* values,
        int n,
        int k
) {
    NumericVector row_sums(n);
    NumericVector col_sums(k);
    double total_sum = 0.0;

    for (int i = 0; i < k; ++i) {
        for (int j = 0; j < n; ++j) {
            double v = values[i * n + j];
            if (!NumericVector::is_na(v)) {
                row_sums[j] += v;
                col_sums[i] += v;
                total_sum += v;
            }
        }
    }

    double sum_col_squared = std::inner_product(col_sums.begin(), col_sums.end(), col_sums.begin(), 0.0);
    double sum_row_squared = std::inner_product(row_sums.begin(), row_sums.end(), row_sums.begin(), 0.0);

    double Q = (k - 1) * (k * sum_col_squared - total_sum * total_sum) / (k * total_sum - sum_row_squared);
    double df = k - 1;
    boost::math::chi_squared_distribution<double> chi_squared(df);
    double p_value = boost::math::cdf(
        boost::math::complement(chi_squared, Q)
    );

    return {Q, df, p_value};
}

// [[Rcpp::export]]
List cochran_q_test_cpp(const List& blocks) {
    int n = as<NumericVector>(blocks[0]).size();
    int k = blocks.size();

    std::vector<double> values(n * k);

    for (int i = 0; i < k; ++i) {
        NumericVector col = blocks[i];
        if (col.size() != n) {
            stop("All elements of 'blocks' must have the same length.");
        }
        for (int j = 0; j < n; ++j) {
            values[i * n + j] = col[j];
        }
    }

    cqObject cqtest = compute_cq(values.data(), n, k);

    return List::create(
        Named("statistic") = cqtest.Q,
        Named("df") = cqtest.df,
        Named("p_value") = cqtest.p_value,
        Named("n_groups") = k
    );
}

// // [[Rcpp::export]]
// List cochran_q_test_matrix(const NumericMatrix& data) {
//     int n = data.nrow();
//     int k = data.ncol();
//
//     std::vector<double> values(n * k);
//     for (int i = 0; i < k; ++i) {
//         for (int j = 0; j < n; ++j) {
//             values[i * n + j] = data(j, i);
//         }
//     }
//
//     cqObject cqtest = compute_cq(values.data(), n, k);
//
//     return List::create(
//         Named("statistic") = cqtest.Q,
//         Named("df") = cqtest.df,
//         Named("p_value") = cqtest.p_value,
//         Named("n_groups") = k
//     );
// }

// [[Rcpp::export]]
List cochran_q_test_group(
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

    cqObject cqtest = compute_cq(values.data(), n, k);

    return List::create(
        Named("statistic") = cqtest.Q,
        Named("df") = cqtest.df,
        Named("p_value") = cqtest.p_value,
        Named("n_groups") = k
    );
}

/*** R
outcome = c(0,1,1,0,0,1,0,1,1,1,1,1,0,0,1,1,0,1,0,1,1,0,0,1,0,1,1,0,0,1)
treatment = gl(3,1,30,labels=LETTERS[1:3])
participant = gl(10,3,labels=letters[1:10])

cochran_q_test_group(outcome, treatment, participant)
*/

