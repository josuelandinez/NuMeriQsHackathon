#include <iostream>
#include <mpi.h>

// Encapsulated for visibility in the profiler
int compute_row(int y, int width, int height, int max_iter) {
    int row_iters = 0;
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
            row_iters++;
        }
    }
    return row_iters;
}

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    int width = 800, height = 800, max_iter = 100000;
    int rows_per_rank = height / size;
    int local_work_done = 0;

    // BLOCK DISTRIBUTION: Each rank takes a contiguous block of rows
    int start_row = rank * rows_per_rank;
    int end_row = (rank + 1) * rows_per_rank;

    for (int y = start_row; y < end_row; ++y) {
        local_work_done += compute_row(y, width, height, max_iter);
    }

    int global_work;
    MPI_Reduce(&local_work_done, &global_work, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
    
    if (rank == 0) std::cout << "Total iterations: " << global_work << std::endl;

    MPI_Finalize();
    return 0;
}
