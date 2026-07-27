#ifndef CQ_TEST_H
#define CQ_TEST_H

#include <vector>
#include <Rcpp.h>

struct cqObject {
    double Q;
    double df;
    double p_value;
};

cqObject compute_cq(
        const double* values,
        int n,
        int k
);

#endif /* CQ_TEST_H */
