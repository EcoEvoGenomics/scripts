#!/bin/bash

# ADMIN
#SBATCH --job-name=quantify_read_duplication
#SBATCH --output=SLURM-%j-%x.out
#SBATCH --error=SLURM-%j-%x.err
#SBATCH --account=nn10082k
#
# RESOURCE ALLOCATION
#SBATCH --nodes=1
#SBATCH --tasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=6G
#SBATCH --time=12:00:00

# User definitions
reads_directory=/path/to/directory/with/reads

# Prepare environment
set -o errexit
set -o nounset
module --quiet purge

# Load modules
module load SeqKit/2.3.1

# Begin work
cd $reads_directory
mkdir rmdup

echo "Writing list of read files in directory ${reads_directory} ..."
find "$PWD"/ -type f | grep .fastq.gz | sort > rmdup/reads_rmdup.list

echo "Calculating stats before rmdup ..."
seqkit stats -To rmdup/seqkit_stats.tsv *.fastq.gz

while read read_file; do
    read_basename=$(basename $read_file ".fastq.gz")
    echo "Quantifying read duplication in: ${read_basename}.fastq.gz ..."
    seqkit rmdup ${read_basename}.fastq.gz -n -o rmdup/${read_basename}_rmdup.fastq.gz -j 4
done <rmdup/reads_rmdup.list

cd rmdup
echo "Calculating stats after rmdup ..."
seqkit stats -To seqkit_stats_rmdup.tsv *.fastq.gz
# End work
