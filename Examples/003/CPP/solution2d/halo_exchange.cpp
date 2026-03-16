#include <iostream>
#include <vector>
#include <mpi.h>
#include <cmath>

#define INDEX(i, j, cols) ((i) * (cols) + (j))

void compute_stencil_2d(int start_row, int end_row, int start_col, int end_col, 
                       int total_cols, const std::vector<double>& data, std::vector<double>& new_data) {
    for (int i = start_row; i <= end_row; ++i) {
        for (int j = start_col; j <= end_col; ++j) {
            double val = (data[INDEX(i-1, j, total_cols)] + data[INDEX(i+1, j, total_cols)] +
                          data[INDEX(i, j-1, total_cols)] + data[INDEX(i, j+1, total_cols)] + 
                          data[INDEX(i, j, total_cols)]) / 5.0;
            // Standard stencil math
            val = std::sin(val) + 1.0;
            new_data[INDEX(i, j, total_cols)] = val;
        }
    }
}

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    const int N = 2000; 
    const int halo_rows = 250; // Heavy Payload: 250 rows (~4MB)
    int full_cols = N + 2;
    int total_rows = N + 2 * halo_rows;

    std::vector<double> data(total_rows * full_cols, 1.0);
    std::vector<double> new_data(total_rows * full_cols, 1.0);

    int north = (rank >= (size/2)) ? rank - (size/2) : MPI_PROC_NULL;
    int south = (rank < (size/2)) ? rank + (size/2) : MPI_PROC_NULL;

    MPI_Barrier(MPI_COMM_WORLD);
    double start_time = MPI_Wtime();

    for (int step = 0; step < 100; ++step) {
        MPI_Request reqs[4];
        int n = 0;

        // ASYNC: Start moving the 4MB payload
        if (north != MPI_PROC_NULL) {
            MPI_Irecv(&data[0], halo_rows * full_cols, MPI_DOUBLE, north, 0, MPI_COMM_WORLD, &reqs[n++]);
            MPI_Isend(&data[halo_rows * full_cols], halo_rows * full_cols, MPI_DOUBLE, north, 1, MPI_COMM_WORLD, &reqs[n++]);
        }
        if (south != MPI_PROC_NULL) {
            MPI_Irecv(&data[(halo_rows + N) * full_cols], halo_rows * full_cols, MPI_DOUBLE, south, 1, MPI_COMM_WORLD, &reqs[n++]);
            MPI_Isend(&data[N * full_cols], halo_rows * full_cols, MPI_DOUBLE, south, 0, MPI_COMM_WORLD, &reqs[n++]);
        }

        // OVERLAP: Compute the INNER part of the 2D grid
        // We calculate rows [halo_rows+1 to halo_rows+N-1]
        compute_stencil_2d(halo_rows + 1, halo_rows + N - 1, 1, N, full_cols, data, new_data);

        // WAIT: Now the network HAS to be finished
        if (n > 0) MPI_Waitall(n, reqs, MPI_STATUSES_IGNORE);

        // CLEANUP: Finalize the boundary rows
        compute_stencil_2d(halo_rows, halo_rows, 1, N, full_cols, data, new_data);
        compute_stencil_2d(halo_rows + N, halo_rows + N, 1, N, full_cols, data, new_data);

        data.swap(new_data);
    }

    double total = MPI_Wtime() - start_time, max_t;
    MPI_Reduce(&total, &max_t, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    if (rank == 0) std::cout << "2D HEAVY-ASYNC Time: " << max_t << "s" << std::endl;

    MPI_Finalize();
    return 0;
}
