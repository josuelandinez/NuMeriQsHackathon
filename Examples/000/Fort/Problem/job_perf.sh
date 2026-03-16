#!/bin/bash -x
#SBATCH --job-name="profile-perf-test"
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=02:00:00
#SBATCH --output=test-perf-out-JobID-%j.txt
#SBATCH --error=test-perf-err-JobID-%j.txt
#SBATCH --partition=dc-cpu-devel
#SBATCH --account=zam
#SBATCH --disable-perfparanoid  # important to allow perf to make measurements
#SBATCH --disable-turbomode  #keep CPU frequency constant not on demand for reproducibility 


# Load Environment (Stage 2026)
module --force purge
echo "Loading Modules..."
module load Stages/2026
module load GCC/14.3.0
module load OpenMPI/5.0.8

# Disable OpenMPI CUDA                                                                                                                                                                                                          
export OMPI_MCA_opal_cuda_support=0
export OMPI_MCA_btl=^smcuda
export OMPI_MCA_pml=ucx #use ucx anyway

# Disable UCX GPU transports and memory types                                                                                                                                                                                   
export UCX_MEMTYPE_CACHE=n         # Don't cache GPU memory
export UCX_WARN_UNUSED_ENV_VARS=n  # Silence warnings unused vars 

# set omp number of tasks
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

#choose what test to run
#export BUILD_DIR="./build_regular"
export BUILD_DIR="./build_profile"

#binary or applcation path
export PROGRAM="${BUILD_DIR}/matmul"

#perf directory
export PERF_DIR="profile-report-perf-JobID-${SLURM_JOB_ID}";
mkdir ${PERF_DIR}

#create an perf file per rank
srun --ntasks=${SLURM_NTASKS} \
     --cpus-per-task=${SLURM_CPUS_PER_TASK} \
     --cpu-bind=cores \
     bash -c "perf record -e cycles:u -F 997 -g -o ${PERF_DIR}/perf_rank_\${SLURM_PROCID}.data ${PROGRAM}"
     
echo "Generating reports..."

# Set our target file to Rank 0's output
export PERF_DATA_FILE="${PERF_DIR}/perf_rank_0.data"

# FLAT HOTSPOTS: Like VTune's main table. Strips out the call tree and just lists the heaviest functions.
perf report -i ${PERF_DATA_FILE} --stdio --no-children -g none --sort comm,dso,symbol > ${PERF_DIR}/report_hotspots_flat.txt

#HOTSPOTS" Annotated to source code lines
perf report -i ${PERF_DATA_FILE} --stdio --no-children --sort comm,dso,symbol,srcline > ${PERF_DIR}/report_hotspots_srcline.txt

# We measure the total L1 cache misses to prove the memory bottleneck.
# The output is saved directly to a text file.
srun --ntasks=${SLURM_NTASKS} \
     --cpus-per-task=${SLURM_CPUS_PER_TASK} \
     --cpu-bind=cores --exact \
     bash -c "perf stat -e cycles:u,instructions:u,L1-dcache-load-misses -o ${PERF_DIR}/perf_stat_\${SLURM_PROCID}_summary.txt ${PROGRAM}"
     

echo "All reports saved in ${PERF_DIR}"
