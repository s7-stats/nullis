#ifndef MOOD_MDTEST_H
#define MOOD_MDTEST_H

#include <vector>
#include <cstddef>
#include <Rcpp.h>

struct mdtObject {
    double statistic;
    double p_value;
    double df;
    Rcpp::IntegerMatrix cont_tab;
    double median;
};

mdtObject compute_mood(
    const double* values,
    const int* group_indices,
    int n_total,
    int k
);

double quickselect_median(Rcpp::NumericVector x);
Rcpp::IntegerMatrix create_contingency_table(const Rcpp::List& groups, double med);
double chi_square(const Rcpp::IntegerMatrix& cont_table);
double calculate_p_value(double chi_sq, int df);

#endif /* MOOD_MDTEST_H */
