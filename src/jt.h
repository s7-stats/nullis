#ifndef JT_H
#define JT_H

#include <vector>
#include <Rcpp.h>

struct jtObject {
    double statistic;
    double mean;
    double variance;
    double z_score;
    double p_value;
    bool approximate;
    std::string method;
};

double jt_stat(const Rcpp::NumericVector& x, const Rcpp::IntegerVector& g);

std::vector<double> jt_pdf(const std::vector<int>& group_sizes);

jtObject compute_jt(
        const Rcpp::NumericVector& values,
        const Rcpp::IntegerVector& groups,
        const std::string& alternative,
        bool approximate
);

#endif /* JT_H */
