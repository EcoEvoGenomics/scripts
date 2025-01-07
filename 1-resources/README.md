# Resources

Holds re-usable general purpose scripts for sharing between projects, organised in topical subfolders.

## Index of Contents
### Contents
```bash
.
├── README.md
├── data-management
│   ├── fetch-nird-crams.sh
│   └── fetch-nird-reads.sh
└── ngs-utils
    ├── quantify-read-duplication.slurm.sh
    └── subsample-reads.slurm.sh
```

### Contents documentation
- `data-management`: Scripts for managing data on our HPC and remote storage resources

  - `fetch-nird-crams.sh`: Downloads CRAMs and CRAIs for a list of individuals from NIRD. See script for additional documentation.

  - `fetch-nird-reads.sh`: Downloads FASTQC reads for a list of individuals from NIRD. See script for additional documentation.

- `ngs-utils`: Scripts for performing miscellaneous utility tasks on next-generation sequencing data

  - `quantify-read-duplication.sh`: Runs `seqkit stats` (https://bioinf.shenwei.me/seqkit/usage/#stats) to quantify the number of reads across all FASTQ files in a directory before and after removing duplicates with `seqkit rmdup` (https://bioinf.shenwei.me/seqkit/usage/#rmdup). The reports can be compared to quantify read duplication. De-duplicated reads are stored as FASTQC files in a new subfolder `rmdup`.

  - `subsample-reads.sh`: Subsamples reads for all FASTQC files in a directory. This can be useful for e.g. creating toy datasets for test-runs or diagnostics. Runs `seqkit sample` (https://bioinf.shenwei.me/seqkit/usage/#sample) first to randomly downsample the file to some proportion of its original size, and then `seqkit head` (https://bioinf.shenwei.me/seqkit/usage/#head) to select a given number of reads. Downsampled reads are stored as FASTQC files in a new subfolder `sample`.
