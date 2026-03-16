#include <iostream>
#include <vector>
#include <mpi.h>
#include <cmath>

void compute_stencil(int start, int end, const std::vector<double>& data, std::vector<double>& new_data) {
    for (int i = start; i < end; ++i) {
        double val = (data[i - 1] + data[i] + data[i + 1]) / 3.0;
        for (int w = 0; w < 2; ++w) { // Very light math
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
    const int halo_size = 500000; // Heavy 4MB Payload
    const int num_steps = 200; 

    std::vector<double> data(local_elements + 2 * halo_size, 1.0);
    std::vector<double> new_data(local_elements + 2 * halo_size, 1.0);

    int left = (rank == 0) ? MPI_PROC_NULL : rank - 1;
    int right = (rank == size - 1) ? MPI_PROC_NULL : rank + 1;

    MPI_Barrier(MPI_COMM_WORLD);
    double start_time = MPI_Wtime();

    for (int step = 0; step < num_steps; ++step) {
        // Sync communication: CPU idles during the 4MB transfer
        MPI_Sendrecv(&data[local_elements], halo_size, MPI_DOUBLE, right, 0,
                     &data[0],              halo_size, MPI_DOUBLE, left,  0,
                     MPI_COMM_WORLD, MPI_STATUS_IGNORE);

        MPI_Sendrecv(&data[halo_size],                       halo_size, MPI_DOUBLE, left,  1,
                     &data[halo_size + local_elements],      halo_size, MPI_DOUBLE, right, 1,
                     MPI_COMM_WORLD, MPI_STATUS_IGNORE);

        compute_stencil(halo_size, halo_size + local_elements, data, new_data);
        data.swap(new_data);
    }

    double max_t, total = MPI_Wtime() - start_time;
    MPI_Reduce(&total, &max_t, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    if (rank == 0) std::cout << "SYNC Heavy-Net Time: " << max_t << "s" << std::endl;

    MPI_Finalize();
    return 0;
}
