#!/bin/bash -x
#SBATCH --job-name="profile-test"
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --cpus-per-task=1
#SBATCH --time=02:00:00
#SBATCH --output=test-vtune-out-JobID-%j.txt
#SBATCH --error=test-vtune-err-JobID-%j.txt
#SBATCH --partition=dc-cpu-devel
#SBATCH --account=zam
##############SBATCH --disable-perfparanoid  # important to allow perf to make measurements
#SBATCH --disable-turbomode  #keep CPU frequency constant not on demand for reproducibility 

# Load Environment (Stage 2026)
module --force purge
echo "Loading Modules..."
module load Stages/2026
module load GCC/14.3.0
module load OpenMPI/5.0.8
module load VTune/2025.4.0

# Disable OpenMPI CUDA
export OMPI_MCA_opal_cuda_support=0
export OMPI_MCA_btl=^smcuda
export OMPI_MCA_pml=ucx # use ucx anyway

# Disable UCX GPU transports and memory types
export UCX_MEMTYPE_CACHE=n         # Don't cache GPU memory
export UCX_WARN_UNUSED_ENV_VARS=n  # Silence warnings unused vars

# set omp number of tasks
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}


#main options vtune profiler

#| Analysis         | Command                    | What it measures         |
#| ---------------- | -------------------------- |--------------------------|
#| CPU hotspots     | `-collect hotspots`        |CPU time per function     |
#| HPC MPI profile  | `-collect hpc-performance` |MPI + compute imbalance   |
#| Memory analysis  | `-collect memory-access`   |cache misses, bandwidth   |
#| threading issues | `-collect threading`       |OpenMP/thread contention  |


#select your analysis
# General
export analysis="hotspots"
#export analysis="threading"
# Works only in Intel's CPU it needs intel counters 
#export analysis="hpc-performance"  
#export analysis="memory-access"



#choose test to run: build and/or applicaton path
export BUILD_DIR="./build_profile"
export PROGRAM="${BUILD_DIR}/halo_exchange"

# directory where VTune results will be stored
export PROFILE_DIR="profile-report-vtune-${analysis}-${SLURM_JOB_ID}"

srun --ntasks=${SLURM_NTASKS} \
     --cpus-per-task=${SLURM_CPUS_PER_TASK} \
     --cpu-bind=cores \
     vtune -collect ${analysis}\
     -result-dir ${PROFILE_DIR} \
     -trace-mpi \
     -- \
     ${PROGRAM}
