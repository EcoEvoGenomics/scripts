#!/bin/bash

# ADMIN
#SBATCH --job-name=concatenate_fasta_files
#SBATCH --output=SLURM-%j-%x.out
#SBATCH --error=SLURM-%j-%x.err
#SBATCH --account=nn10082k
#
# RESOURCE ALLOCATION
#SBATCH --nodes=1
#SBATCH --tasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1G
#SBATCH --time=00:30:00

# User definitions
input_fasta_directory=
input_fasta_pattern="*.fa"
output_fasta=

# Prepare environment
set -o errexit
set -o nounset
module --quiet purge

# Begin work
cd ${input_fasta_directory}
input_fasta_files=$(find . -maxdepth 1 -type f -name "$input_fasta_pattern")
echo ${input_fasta_files} | xargs cat > $output_fasta
# End work
