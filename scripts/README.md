### Contents
```bash
.
├── data_management
│   ├── fetch_nird_crams.sh
│   └── fetch_nird_reads.sh
├── ngs_analysis
│   ├── mtdna_get_consensus.slurm.sh
│   ├── phylo_iqtree2.slurm.sh
│   ├── phylo_mafft.slurm.sh
│   ├── pop_admixture.sh
│   ├── pop_plink_filter.sh
│   ├── pop_plink_initialize.sh
│   ├── pop_plink_missing_report.sh
│   ├── pop_plink_pca.sh
│   ├── pop_plink_prune.sh
│   ├── pop_plink_remove.sh
│   ├── pop_plink_to_vcf.sh
│   ├── pop_triangulaR.sh
│   └── pop_triangulaR.sh.R
├── ngs_utils
│   ├── fasta_concatenate.slurm.sh
│   ├── fasta_downsample.slurm.sh
│   ├── fasta_quantify_duplication.slurm.sh
│   ├── vcf_concatenate.sh
│   ├── vcf_merge.sh
│   ├── vcf_remove_samples.sh
│   └── vcf_rename_samples.sh
└── script_templates
    └── slurm_template.slurm.sh
```

### Documentation
#### `./data_management`
Scripts for managing data on our HPC and remote storage resources

  - `fetch_nird_crams.sh`: Downloads CRAMs and CRAIs for a list of individuals from NIRD. See script for additional documentation.

  - `fetch_nird_reads.sh`: Downloads FASTQC reads for a list of individuals from NIRD. See script for additional documentation.

#### `./ngs_analysis`
Stand-alone analysis scripts for next-gen sequencing data

  - `mtdna_get_consensus.slurm.sh`: Extracts the consensus mtDNA sequence for each BAM / CRAM in a list you provide. The consensus mtDNA sequences are output as FASTA. Uses `bcftools` to call variants relative to the reference genome for each individual and then `samtools` to generate the consensus sequence of each indivudal.

  - `phylo_iqtree2.slurm.sh`: Produces a sequence tree in NEXUS format with the software `iqtree2`. Uses ultrafast bootstrapping, but still takes a long time for long sequences like full mtDNAs. Takes as input a sequence alignment in FASTA format, such as from MAFFT.

  - `phylo_mafft.slurm.sh`: Produces an alignment with the software `mafft`, as well as testing alignment models with `modeltest-ng`. Takes a *single* fasta file (you can use `scripts/ngs_utils/fasta_concatenate.slurm.sh`) as input and outputs an aligned fasta file.

  - `pop_admixture.slurm.sh`: Runs the software ADMIXTURE as described on the [Speciation Genomics tutorial by Mark and Joana Meier](https://speciationgenomics.github.io/ADMIXTURE/). You need binary input files created by PLINK. Performs cross-validation. The output can be parsed for plotting in R using our `eegr` R package at [EcoEvoGenomics/eegr](https://github.com/EcoEvoGenomics/eegr).

  - `pop_plink_*.slurm.sh`: A series of scripts to perform various operations with the software [PLINK 1.9](https://www.cog-genomics.org/plink/1.9/). This includes running a PCA as described on the [Speciation Genomics tutorial](https://speciationgenomics.github.io/ADMIXTURE/). The output of a PLINK PCA can be parsed for plotting in R using our `eegr` R package at [EcoEvoGenomics/eegr](https://github.com/EcoEvoGenomics/eegr).

  - `pop_triangulaR.slurm.sh`: Identifies ancestry-informative markers (AIMs) and calculates the statistics required to construct triangle plots using the R package [`triangulaR`](https://doi.org/10.1038/s41437-025-00760-2). See also [this paper](https://doi.org/10.1111/1755-0998.14039) for how to user triangle plots to delimit hybridisation from isolation-by-distance. Depends on the companion script `pop_triangulaR.R` found in this directory.

#### `./ngs_utils`
Scripts for performing miscellaneous utility tasks on next-generation sequencing data

  - `concatenate_fasta_files.slurm.sh`: Concatenates all (fasta) files in a given directory to produce a single file. Can strictly speaking be used to concatenate other files with appropriate formats, too.

  - `quantify_read_duplication.sh`: Runs `seqkit stats` (https://bioinf.shenwei.me/seqkit/usage/#stats) to quantify the number of reads across all FASTQ files in a directory before and after removing duplicates with `seqkit rmdup` (https://bioinf.shenwei.me/seqkit/usage/#rmdup). The reports can be compared to quantify read duplication. De-duplicated reads are stored as FASTQC files in a new subfolder `rmdup`.

  - `subsample_reads.sh`: Subsamples reads for all FASTQC files in a directory. This can be useful for e.g. creating toy datasets for test-runs or diagnostics. Runs `seqkit sample` (https://bioinf.shenwei.me/seqkit/usage/#sample) first to randomly downsample the file to some proportion of its original size, and then `seqkit head` (https://bioinf.shenwei.me/seqkit/usage/#head) to select a given number of reads. Downsampled reads are stored as FASTQC files in a new subfolder `sample`.

#### `./script_templates`
Templates to assist your scripting, if e.g. you are new to how a batch script looks on the Saga HPC.

  - `slurm_template.slurm.sh`: A template Slurm script for the Saga HPC, including most headers you are likely to need and some useful commands to set the environment for your job.
