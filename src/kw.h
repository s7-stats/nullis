#ifndef KW_H
#define KW_H

#include <vector>
#include <cstddef>

struct kwObject {
    double h;
    double p_value;
    double df;
};

kwObject compute_kw(
        const double* values,
        const int* group_indices,
        int n_total,
        int k
);

#endif /* KW_H */
