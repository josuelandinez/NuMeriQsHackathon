#include <iostream>
#include <mpi.h>
#include <cstdlib>

// Encapsulated for visibility in the profiler
long long run_monte_carlo(long long n) {
    long long inside = 0;
    for (long long i = 0; i < n; ++i) {
        double x = (double)rand() / RAND_MAX;
        double y = (double)rand() / RAND_MAX;
        if (x * x + y * y <= 1.0) {
            inside++;
        }
    }
    return inside;
}

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long long points_per_rank = 500000000;
    srand(rank * 12345); 

    // Calculation is now its own region in Score-P
    long long local_inside = run_monte_carlo(points_per_rank);

    long long global_inside = 0;
    MPI_Reduce(&local_inside, &global_inside, 1, MPI_LONG_LONG, MPI_SUM, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        double pi = 4.0 * (double)global_inside / (points_per_rank * size);
        std::cout << "Estimated Pi (Slow Rand): " << pi << std::endl;
    }

    MPI_Finalize();
    return 0;
}
