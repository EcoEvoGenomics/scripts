#!/bin/bash

# ADMIN
#SBATCH --job-name=subsample_reads
#SBATCH --output=SLURM-%j-%x.out
#SBATCH --error=SLURM-%j-%x.err
#SBATCH --account=nn10082k
#
# RESOURCE ALLOCATION
#SBATCH --nodes=1
#SBATCH --tasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4G
#SBATCH --time=02:00:00

# User definitions
reads_directory=
sampled_reads=

# Keep low for large FASTA files to reduce memory use!
proportion_of_reads_sampled_from=0.1

# Prepare environment
set -o errexit
set -o nounset
module --quiet purge

# Load modules
module load SeqKit/2.3.1

# Begin work
cd $reads_directory
mkdir sample

echo "Writing list of read files in directory ${reads_directory} ..."
find "$PWD"/ -type f | grep .fastq.gz | sort > sample/reads_sample.list

echo "Subsampling reads ..."
while read read_file; do
    read_basename=$(basename $read_file ".fastq.gz")
    echo "Subsampling: ${read_basename}.fastq.gz ..."
    seqkit sample -p ${proportion_of_reads_sampled_from} ${read_basename}.fastq.gz |\
    seqkit head -n ${sampled_reads} -o sample/${read_basename}_sample.fastq.gz
done <sample/reads_sample.list

echo "Done subsampling!"
# Work end
