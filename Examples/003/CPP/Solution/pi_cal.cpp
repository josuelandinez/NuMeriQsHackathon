#include <iostream>
#include <mpi.h>
#include <random>

// Encapsulated for visibility in the profiler
// Using minstd_rand: A minimal standard LCG engine. 
// It is significantly faster than mt19937 and better than legacy rand().
long long run_monte_carlo_optimized(long long n, int rank) {
    std::minstd_rand rng(rank * 12345); 
    std::uniform_real_distribution<double> dist(0.0, 1.0);
    
    long long inside = 0;
    for (long long i = 0; i < n; ++i) {
        double x = dist(rng);
        double y = dist(rng);
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

    // This call will now show up as a clear USR region in Score-P
    long long local_inside = run_monte_carlo_optimized(points_per_rank, rank);

    long long global_inside = 0;
    MPI_Reduce(&local_inside, &global_inside, 1, MPI_LONG_LONG, MPI_SUM, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        double pi = 4.0 * (double)global_inside / (points_per_rank * size);
        std::cout << "Estimated Pi (minstd_rand): " << pi << std::endl;
    }

    MPI_Finalize();
    return 0;
}
