#!/bin/bash -x
#SBATCH --job-name="profile-test"
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --cpus-per-task=1
#SBATCH --time=02:00:00
#SBATCH --output=test-scorep-out-JobID-%j.txt
#SBATCH --error=test-scorep-err-JobID-%j.txt
#SBATCH --partition=dc-cpu-devel
#SBATCH --account=zam
#SBATCH --disable-turbomode # set frequency constant 


# Load Environment (Stage 2026)
module --force purge
echo "Loading Modules..."
module load Stages/2026
module load GCC/14.3.0
module load OpenMPI/5.0.8
#Needed to  build and measure with Score-P
module load Score-P/9.4


# Disable OpenMPI CUDA
export OMPI_MCA_opal_cuda_support=0
export OMPI_MCA_btl=^smcuda
export OMPI_MCA_pml=ucx # use ucx anyway

# Disable UCX GPU transports and memory types
export UCX_MEMTYPE_CACHE=n         # Don't cache GPU memory
export UCX_WARN_UNUSED_ENV_VARS=n  # Silence warnings unused vars 

# Force eager protocol limit 4 bytes
#export OMPI_MCA_pml_ob1_eager_limit=4


# set omp number of tasks
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

#score-p configuration flags
export SCOREP_ENABLE_PROFILING=1; #to profile 
export SCOREP_ENABLE_TRACING=0; #to trace 
export SCOREP_EXPERIMENT_DIRECTORY="profile-report-scorep-JobID-${SLURM_JOB_ID}";
export SCOREP_TOTAL_MEMORY=1G; # set memory for colelction
export SCOREP_TIMER=clock_gettime; # set timer or clock
# Tell Score-P to look at the Call Stack (unwind it) just like perf does
#export SCOREP_ENABLE_UNWINDING=true
# Tell Score-P to pause the program every number (10000) of CPU cycles and look at the call stack to see libc functions!
export SCOREP_SAMPLING_EVENTS=perf_cycles@10000

#write cache misses
#export SCOREP_METRIC_PERF=L1-dcache-load-misses

#choose what test to run
#export BUILD_DIR="./build_regular"
export BUILD_DIR="./build_scorep"
export PROGRAM="${BUILD_DIR}/halo_exchange"


srun --ntasks=${SLURM_NTASKS} \
     --cpus-per-task=${SLURM_CPUS_PER_TASK} \
     --distribution=block:block \
     --hint=nomultithread \
     --cpu-bind=cores \
      ${PROGRAM}

# Simple analysis scorep-score
# The output file is always named profile.cubex inside the experiment directory
CUBEX_FILE="${SCOREP_EXPERIMENT_DIRECTORY}/profile.cubex"

# Hotspot Report: Expand all regions (-r) and sort by time (-s time)
echo "Generating detailed hotspot report..."
scorep-score -r -s totaltime ${CUBEX_FILE} > ${SCOREP_EXPERIMENT_DIRECTORY}/scorep_hotspots.txt

echo "Score-P reports successfully saved in ${SCOREP_EXPERIMENT_DIRECTORY}"
    
# Print the top 15 lines of the hotspot report directly to the SLURM output log
echo "--- TOP 10 HOTSPOTS ---"
head -n 25 ${SCOREP_EXPERIMENT_DIRECTORY}/scorep_hotspots.txt
