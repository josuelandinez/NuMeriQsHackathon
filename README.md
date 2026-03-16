# HPC Profiling Hackathon 2026

This repository contains C++ and Fortran examples designed for performance analysis and bottleneck identification using HPC profiling tools.

## Environment Setup

Before compiling or running any scripts, initialize your shell environment to load the necessary compilers and profiling toolchains (Stages/2026, GCC, OpenMPI, Score-P, and VTune).

```bash
source environment.sh

```

For theoretical background and detailed configuration of the tools, refer to the provided slides:
**HackathonNuMeriQs.pdf**

---

## Repository Structure

The exercises are organized into **Problem** (unoptimized) and **Solution** (optimized reference) directories.

### C++ Examples (Mandelbrot OMP)

```text
Examples/001/CPP/
├── Problem/
│   ├── build.sh            # Compilation script
│   ├── CMakeLists.txt      # Build configuration
│   ├── job_perf.sh         # perf sampling script
│   ├── job_scorep.sh       # Score-P instrumentation script
│   ├── job_vtune.sh        # Intel VTune collector script
│   └── mandelbrot_omp.cpp  # Source code
└── Solution/
    ├── build.sh
    ├── CMakeLists.txt
    ├── job_perf.sh
    ├── job_scorep.sh
    ├── job_vtune.sh
    └── mandelbrot_omp.cpp

```

### Fortran Examples (Halo Exchange)

```text
Examples/003/Fort/
├── Problem/
│   ├── build.sh            # Compilation script
│   ├── halo_exchange.f90   # Source code
│   ├── job_perf.sh         # perf sampling script
│   ├── job_scorep.sh       # Score-P instrumentation script
│   ├── job_vtune.sh        # Intel VTune collector script
│   └── Makefile            # Build configuration
└── Solution/
    ├── build.sh
    ├── halo_exchange.f90
    ├── job_perf.sh
    ├── job_scorep.sh
    ├── job_vtune.sh
    └── Makefile

```

---

## Usage Instructions

### 1. Build the Application

Navigate to the desired directory and execute the build script. Compilation options and optimization flags can be modified directly in the `CMakeLists.txt` or `Makefile`.

```bash
cd Examples/003/Fort/Problem
./build.sh

```

### 2. Submit Profiling Jobs

Submit the pre-configured Slurm job scripts to the queue using `sbatch`. These scripts are tailored for specific analysis types:

* **Score-P**: Recommended for analyzing MPI communication patterns and call-tree logic.
* **perf**: Recommended for lightweight sampling of CPU cycles and hardware performance counters.
* **VTune**: Recommended for comprehensive hardware analysis, including memory access and HPC characterization.

```bash
sbatch job_scorep.sh
sbatch job_perf.sh
sbatch job_vtune.sh

```

### 3. Result Visualization

Graphical user interfaces are available for in-depth data exploration:

* **Score-P**: Use the `cube` command to open `.cubex` files.
* **VTune**: Use the `vtune-gui` command to open result directories.

---

## Recommended Workflow

1. Use **Score-P** to establish a high-level overview of the application and MPI overhead.
2. Use **perf stat** to determine if the workload is compute-bound or memory-bound.
3. Use **perf report** or **VTune** to pinpoint the specific source code lines responsible for the identified bottlenecks.
