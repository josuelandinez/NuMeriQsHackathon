#include <iostream>
#include <vector>
#include <mpi.h>
#include <cmath>

void compute_stencil(int start, int end, const std::vector<double>& data, std::vector<double>& new_data) {
    for (int i = start; i < end; ++i) {
        double val = (data[i - 1] + data[i] + data[i + 1]) / 3.0;
        for (int w = 0; w < 2; ++w) {
	  //val = std::sin(val) * std::cos(val) + 1.0;
	  //val = (val * 0.0125) + 0.001;
	  val = std::sin(val)+1.0;
        }
        new_data[i] = val;
    }
}

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    const int local_elements = 600000; 
    const int halo_size = 500000; 
    const int num_steps = 200; 

    std::vector<double> data(local_elements + 2 * halo_size, 1.0);
    std::vector<double> new_data(local_elements + 2 * halo_size, 1.0);

    int left = (rank == 0) ? MPI_PROC_NULL : rank - 1;
    int right = (rank == size - 1) ? MPI_PROC_NULL : rank + 1;

    MPI_Barrier(MPI_COMM_WORLD);
    double start_time = MPI_Wtime();

    for (int step = 0; step < num_steps; ++step) {
        MPI_Request reqs[4];
        int n = 0;

        if (left != MPI_PROC_NULL) {
            MPI_Irecv(&data[0], halo_size, MPI_DOUBLE, left, 0, MPI_COMM_WORLD, &reqs[n++]);
            MPI_Isend(&data[halo_size], halo_size, MPI_DOUBLE, left, 1, MPI_COMM_WORLD, &reqs[n++]);
        }
        if (right != MPI_PROC_NULL) {
            MPI_Irecv(&data[halo_size + local_elements], halo_size, MPI_DOUBLE, right, 1, MPI_COMM_WORLD, &reqs[n++]);
            MPI_Isend(&data[local_elements], halo_size, MPI_DOUBLE, right, 0, MPI_COMM_WORLD, &reqs[n++]);
        }

        // Overlap: Do the bulk of the math while data is in flight
        compute_stencil(halo_size + 1, halo_size + local_elements - 1, data, new_data);

        if (n > 0) MPI_Waitall(n, reqs, MPI_STATUSES_IGNORE);

        // Finish the edges
        compute_stencil(halo_size, halo_size + 1, data, new_data);
        compute_stencil(halo_size + local_elements - 1, halo_size + local_elements, data, new_data);

        data.swap(new_data);
    }

    double max_t, total = MPI_Wtime() - start_time;
    MPI_Reduce(&total, &max_t, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    if (rank == 0) std::cout << "ASYNC Overlap Time: " << max_t << "s" << std::endl;

    MPI_Finalize();
    return 0;
}
