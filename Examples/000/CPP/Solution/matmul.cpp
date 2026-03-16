#include <iostream>
#include <vector>
#include <chrono>
#include <cstdlib>

const int N = 1024;

// ---- optimised kernel -------------------------------------------------------
void matmul_fast(const std::vector<double>& A,
                 const std::vector<double>& B,
                 std::vector<double>&       C,
                 int n)
{
    // Initialise C to zero
    std::fill(C.begin(), C.end(), 0.0);

    //Exachange loop order
    for (int i = 0; i < n; ++i) {
        for (int k = 0; k < n; ++k) {
            const double a_ik = A[i*n + k];   // scalar, kept in register
            for (int j = 0; j < n; ++j) {
                // All three: stride-1, cache-friendly
                C[i*n + j] += a_ik * B[k*n + j];
            }
        }
    }
}
// -----------------------------------------------------------------------------

int main()
{
    std::vector<double> A(N*N), B(N*N), C(N*N, 0.0);
    srand(42);
    for (int i = 0; i < N*N; ++i) {
        A[i] = static_cast<double>(rand()) / RAND_MAX;
        B[i] = static_cast<double>(rand()) / RAND_MAX;
    }

    auto t0 = std::chrono::high_resolution_clock::now();
    matmul_fast(A, B, C, N);
    auto t1 = std::chrono::high_resolution_clock::now();

    double elapsed = std::chrono::duration<double>(t1 - t0).count();
    std::cout << "Matrix size  : " << N << " x " << N << "\n";
    std::cout << "Time (fast)  : " << elapsed << " s\n";
    std::cout << "Checksum C[0][0] = " << C[0] << "\n";
    return 0;
}
