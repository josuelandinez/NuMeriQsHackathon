#include <iostream>
#include <vector>

const int NUM_PARTICLES = 10000000;
const int ITERATIONS = 200;

// BAD: Array of Structures (AoS)
struct Particle {
    double x, y, z;
    double vx, vy, vz;
};

// GOOD: Structure of Arrays (SoA)
struct ParticlesSoA {
    std::vector<double> x, y, z;
    std::vector<double> vx, vy, vz;
    
    ParticlesSoA(int size) {
        x.resize(size, 1.0); y.resize(size, 1.0); z.resize(size, 1.0);
        vx.resize(size, 0.1); vy.resize(size, 0.1); vz.resize(size, 0.1);
    }
};

void updateAoS(std::vector<Particle>& p, double dt) {
    for (int iter = 0; iter < ITERATIONS; ++iter) {
        for (int i = 0; i < NUM_PARTICLES; ++i) {
            p[i].x += p[i].vx * dt;
            p[i].y += p[i].vy * dt;
            p[i].z += p[i].vz * dt;
        }
    }
}

void updateSoA(ParticlesSoA& p, double dt) {
    for (int iter = 0; iter < ITERATIONS; ++iter) {
        // The compiler will easily vectorize these tight, contiguous loops
        for (int i = 0; i < NUM_PARTICLES; ++i) p.x[i] += p.vx[i] * dt;
        for (int i = 0; i < NUM_PARTICLES; ++i) p.y[i] += p.vy[i] * dt;
        for (int i = 0; i < NUM_PARTICLES; ++i) p.z[i] += p.vz[i] * dt;
    }
}

int main() {
    std::vector<Particle> aos(NUM_PARTICLES, {1.0, 1.0, 1.0, 0.1, 0.1, 0.1});
    ParticlesSoA soa(NUM_PARTICLES);
    
    double dt = 0.01;

    // We call both so you can compare them side-by-side in Score-P
    updateAoS(aos, dt);
    updateSoA(soa, dt);

    std::cout << "Done. Sample AoS X: " << aos[0].x << ", SoA X: " << soa.x[0] << std::endl;
    return 0;
}
