#include <iostream>
#include <vector>

const int NUM_PARTICLES = 10000000;
const int ITERATIONS = 200;

// FIXED: Structure of Arrays (SoA). Perfect for CPU vectorization and cache lines.
struct ParticlesSoA {
    std::vector<double> x, y, z;
    std::vector<double> vx, vy, vz;
    
    ParticlesSoA(int size) {
        x.resize(size, 1.0); y.resize(size, 1.0); z.resize(size, 1.0);
        vx.resize(size, 0.1); vy.resize(size, 0.1); vz.resize(size, 0.1);
    }
};

void updateSoA(ParticlesSoA& p, double dt) {
    for (int iter = 0; iter < ITERATIONS; ++iter) {
        // These loops are now perfectly contiguous in memory
        for (int i = 0; i < NUM_PARTICLES; ++i) p.x[i] += p.vx[i] * dt;
        for (int i = 0; i < NUM_PARTICLES; ++i) p.y[i] += p.vy[i] * dt;
        for (int i = 0; i < NUM_PARTICLES; ++i) p.z[i] += p.vz[i] * dt;
    }
}

int main() {
    ParticlesSoA soa(NUM_PARTICLES);
    double dt = 0.01;

    updateSoA(soa, dt);

    std::cout << "Done. Final SoA X for particle 0: " << soa.x[0] << std::endl;
    return 0;
}
