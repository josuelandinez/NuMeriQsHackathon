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
    const int halo_rows = 250; // Heavy Payload (~4MB)
    int full_cols = N + 2;
    int total_rows = N + 2 * halo_rows;

    std::vector<double> data(total_rows * full_cols, 1.0);
    std::vector<double> new_data(total_rows * full_cols, 1.0);

    // Simple 1D decomposition for 2D grid (Rank 0 top, Rank 1 bottom)
    int north = (rank == 0) ? MPI_PROC_NULL : rank - 1;
    int south = (rank == size - 1) ? MPI_PROC_NULL : rank + 1;

    MPI_Barrier(MPI_COMM_WORLD);
    double start_time = MPI_Wtime();

    for (int step = 0; step < 100; ++step) {
        // --- SYNC EXCHANGE ---
        // Send to North, Recv from South
        MPI_Sendrecv(&data[halo_rows * full_cols], halo_rows * full_cols, MPI_DOUBLE, north, 0,
                     &data[(halo_rows + N) * full_cols], halo_rows * full_cols, MPI_DOUBLE, south, 0,
                     MPI_COMM_WORLD, MPI_STATUS_IGNORE);

        // Send to South, Recv from North
        MPI_Sendrecv(&data[N * full_cols], halo_rows * full_cols, MPI_DOUBLE, south, 1,
                     &data[0], halo_rows * full_cols, MPI_DOUBLE, north, 1,
                     MPI_COMM_WORLD, MPI_STATUS_IGNORE);

        // Compute everything AFTER communication finishes
        compute_stencil_2d(halo_rows, halo_rows + N, 1, N, full_cols, data, new_data);

        data.swap(new_data);
    }

    double total = MPI_Wtime() - start_time, max_t;
    MPI_Reduce(&total, &max_t, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    if (rank == 0) std::cout << "2D HEAVY-SYNC Time: " << max_t << "s" << std::endl;

    MPI_Finalize();
    return 0;
}
