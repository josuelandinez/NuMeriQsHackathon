#include <iostream>
#include <vector>
#include <cmath>
#include <chrono>
#include <cstdlib>

const int N = 1024; 

// ---- hotspot function ------------------------------------------------------
void matmul(const std::vector<double>& A,
                  const std::vector<double>& B,
                  std::vector<double>&       C,
                  int n)
{
  for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            double sum = 0.0;
            for (int k = 0; k < n; ++k) {
                sum += A[i*n + k] * B[k*n + j];
            }
            C[i*n + j] = sum;
        }
    }
}
// ----------------------------------------------------------------------------

int main()
{
    std::vector<double> A(N*N), B(N*N), C(N*N, 0.0);
    srand(42);
    for (int i = 0; i < N*N; ++i) {
        A[i] = static_cast<double>(rand()) / RAND_MAX;
        B[i] = static_cast<double>(rand()) / RAND_MAX;
    }

    auto t0 = std::chrono::high_resolution_clock::now();
    matmul(A, B, C, N);
    auto t1 = std::chrono::high_resolution_clock::now();

    double elapsed = std::chrono::duration<double>(t1 - t0).count();
    std::cout << "Matrix size : " << N << " x " << N << "\n";
    std::cout << "Time (naive): " << elapsed << " s\n";
    std::cout << "Checksum C[0][0] = " << C[0] << "\n";
    return 0;
}
