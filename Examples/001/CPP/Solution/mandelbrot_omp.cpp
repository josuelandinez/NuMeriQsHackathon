#include <iostream>
#include <omp.h>

// Encapsulated math for profiler visibility
int compute_row(int y, int width, int height, int max_iter) {
    int iterations = 0;
    for (int x = 0; x < width; ++x) {
        double cx = (x - width/2.0) * 4.0/width;
        double cy = (y - height/2.0) * 4.0/width;
        double zx = 0, zy = 0;
        int iter = 0;
        while (zx*zx + zy*zy <= 4.0 && iter < max_iter) {
            double tmp = zx*zx - zy*zy + cx;
            zy = 2.0*zx*zy + cy;
            zx = tmp;
            iter++;
        }
        iterations += iter;
    }
    return iterations;
}

int main() {
    int width = 800, height = 800, max_iter = 100000;
    long long total_work = 0;

    double start_time = omp_get_wtime();

    // Fixed with dynamic scheduling: Threads balance themselves
    #pragma omp parallel for reduction(+:total_work) schedule(dynamic)
    for (int y = 0; y < height; ++y) {
        total_work += compute_row(y, width, height, max_iter);
    }

    double end_time = omp_get_wtime();
    std::cout << "Total iterations: " << total_work << std::endl;
    std::cout << "Time taken: " << end_time - start_time << " seconds" << std::endl;

    return 0;
}
