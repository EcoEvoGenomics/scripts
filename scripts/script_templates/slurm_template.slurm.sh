#!/bin/bash

# ADMIN
#SBATCH --job-name=slurm_template
#SBATCH --output=SLURM-%j-%x.out
#SBATCH --error=SLURM-%j-%x.err
#SBATCH --account=nn10082k

# RESOURCE ALLOCATION
#SBATCH --nodes=1
#SBATCH --tasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1G
#SBATCH --time=00:01:00

# Prepare environment
set -o errexit
set -o nounset
module --quiet purge

# Begin work
echo "This is a Slurm job scheduler template for the Saga HPC."
# End work
