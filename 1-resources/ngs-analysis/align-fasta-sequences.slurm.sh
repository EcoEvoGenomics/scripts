#!/bin/bash

# ADMIN
#SBATCH --job-name=align_fasta_sequences
#SBATCH --output=SLURM-%j-%x.out
#SBATCH --error=SLURM-%j-%x.err
#SBATCH --account=nn10082k
#
# RESOURCE ALLOCATION
#SBATCH --nodes=1
#SBATCH --tasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=2G
#SBATCH --time=02:00:00

# User definitions
work_directory=
input_fasta=
aligned_fasta=$(basename ${input_fasta%.*})_mafft.fa

# Prepare environment
set -o errexit
set -o nounset
module --quiet purge

# Load modules
module load MAFFT/7.490-GCC-11.2.0-with-extensions Miniconda3/22.11.1-1
module list

# Load conda environment for modeltest-ng
source ${EBROOTMINICONDA3}/bin/activate
conda activate /cluster/projects/nn10082k/conda_users/eriksro/modeltest-ng
conda list
echo ""

# Begin work
cd ${work_directory}

# Align sequences in input file
echo "Aligning sequences in $input_fasta with MAFFT ..."
mafft --maxiterate 1000 --thread ${OMP_NUM_THREADS} $input_fasta > $aligned_fasta

# Find best alignment model
echo "Testing sequence alignment in $aligned_fasta with modeltest-NG ..."
modeltest-ng -i $aligned_fasta -o ${aligned_fasta%.*}_modeltest.out -p ${OMP_NUM_THREADS}

echo "Done."

# - END OF SCRIPT ----------------------- #
#                                         #
#   Originally developed by Mark Ravinet  #
#                                         #
#   Revised by:                           #
#   - Erik Sandertun Røed (Jan 2025)      #
#                                         #
# --------------------------------------- #
