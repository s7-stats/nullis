#ifndef FRIEDMAN_H
#define FRIEDMAN_H

#include <vector>
#include <cstddef>

struct fmObject {
    double statistic;
    double p_value;
    double df;
};

fmObject compute_fm(
        const double* values,
        const int* group_indices,
        int n_total,
        int k
);

#endif /* FRIEDMAN_H */
