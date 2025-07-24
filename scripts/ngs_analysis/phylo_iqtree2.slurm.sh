#!/bin/bash

# ADMIN
#SBATCH --job-name=make_sequence_tree
#SBATCH --output=SLURM-%j-%x.out
#SBATCH --error=SLURM-%j-%x.err
#SBATCH --account=nn10082k
#
# RESOURCE ALLOCATION
#SBATCH --nodes=1
#SBATCH --tasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=1G
#SBATCH --time=48:00:00

# User definitions
work_directory=
input_fasta=
output_prefix=
bootstrap_reps=1000
model_selection= # e.g. GTR+I+G4

# Prepare environment
set -o errexit
set -o nounset
module --quiet purge

# Load modules
module load IQ-TREE/2.2.2.7-gompi-2023a

# Begin work
cd ${work_directory}
iqtree2 -s $input_fasta --prefix $output_prefix --ufboot $bootstrap_reps --out-format NEXUS -m $model_selection -T AUTO
# End work
