#!/bin/bash

# ADMIN
#SBATCH --job-name=extract_consensus_mtdna
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
#SBATCH --time=12:00:00
#
# ARRAY RANGE (NB! Match to BAMs/CRAMs in bam_or_cram_list, e.g. '--array 0-9' for ten BAMs/CRAMs)
#SBATCH --array=0-0

# User definitions
work_directory=
output_directory=
bam_or_cram_list=
reference_ploidy=
reference_genome=/cluster/projects/nn10082k/ref/house_sparrow_genome_assembly-18-11-14_masked.fa

# Prepare environment
set -o errexit
set -o nounset
module --quiet purge

# Load modules
module load BCFtools/1.19-GCC-13.2.0 SAMtools/1.19.2-GCC-13.2.0

# Begin work
cd ${work_directory}
echo "Working in or under $work_directory with ${OMP_NUM_THREADS} thread(s) ..."

# Read list of input files, select one file per array job, get file basename
readarray input_paths < ${bam_or_cram_list}
input_path=${input_paths[${SLURM_ARRAY_TASK_ID}]}
input_basename=$(basename ${input_path%.*})

# Define path of final consensus sequence fasta output
output_fasta_path=${output_directory}/${input_basename}.fa.gz

# Create and enter temporary directory
tmp_directory=tmp${SLURM_JOBID}_${input_basename}
mkdir ${tmp_directory}
cd ${tmp_directory}

# Begin analysis steps
echo "Creating consensus genome sequence for $input_path in $tmp_directory ..."

# Call aligned variants in bam or cram to vcf and index
bcftools mpileup -a DP -Ou -f $reference_genome $input_path \
| bcftools call --threads ${OMP_NUM_THREADS} --ploidy-file $reference_ploidy -mv -O z -o ${input_basename}_calls.vcf.gz
bcftools index --threads ${OMP_NUM_THREADS} ${input_basename}_calls.vcf.gz

# Normalise vcf, convert vcf to bcf
bcftools norm --threads ${OMP_NUM_THREADS} -f $reference_genome ${input_basename}_calls.vcf.gz -O b -o ${input_basename}_calls.norm.bcf

# Filter, convert back to vcf, index
bcftools filter --threads ${OMP_NUM_THREADS} --IndelGap 5 ${input_basename}_calls.norm.bcf \
-i 'QUAL>20 & FMT/DP>5 & FMT/DP<75' \
-O z -o ${input_basename}_calls.norm.filt.vcf.gz
bcftools index --threads ${OMP_NUM_THREADS} ${input_basename}_calls.norm.filt.vcf.gz

# Obtain sample ID from file (may not correspond to $input_basename)
sample_id=$(bcftools query -l ${input_basename}_calls.norm.filt.vcf.gz)

# Create consensus fasta and index it
cat $reference_genome \
| bcftools consensus -s $sample_id ${input_basename}_calls.norm.filt.vcf.gz \
| bgzip -c > $output_fasta_path
samtools faidx $output_fasta_path

# Extract mtDNA
echo "Extracting consensus mitogenome sequence from $output_fasta_path ..."
samtools faidx $output_fasta_path mtDNA > ${output_fasta_path%%.*}_mtDNA.fa
sed -i_bak -e 's/>mtDNA/>'"${sample_id}"'_mtDNA/g' ${output_fasta_path%%.*}_mtDNA.fa

# Tidy up
echo "Returning to $work_directory and tidying up temporary files ... "
cd ${work_directory}
rm ${output_fasta_path%%.*}_mtDNA.fa_bak
rm ${output_fasta_path%%.*}.fa.gz
rm ${output_fasta_path%%.*}.fa.gz.fai
rm ${output_fasta_path%%.*}.fa.gz.gzi
rm -rv ${tmp_directory}

echo "Done."

# - END OF SCRIPT ----------------------- #
#                                         #
#   Originally developed by Mark Ravinet  #
#                                         #
#   Revised by:                           #
#   - Erik Sandertun Røed (Jan 2025)      #
#                                         #
# --------------------------------------- #
