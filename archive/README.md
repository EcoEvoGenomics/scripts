### Contents
```bash
.
├── ngs_analysis
│   └── mtdna_fitchi_network.slurm.sh
├── ngs_genotyping
│   ├── call_variants.sh
│   ├── filter_variants.sh
│   └── trim_and_align.sh
└── README.md
```
### Documentation

#### `./ngs_analysis`
Stand-alone analysis scripts for next-gen sequencing data

  - `mtdna_fitchi_network.slurm.sh`: For analyses of mitochondrial haplotypes, this scripts produces a bespoke haplotype network using the software [Fitchi](https://academic.oup.com/bioinformatics/article/32/8/1250/1744161?login=false). Takes as input aligned sequences, a sequence tree (as well as the logfile) from iqtree2, as well as a population map. Archived because of somewhat excessive hackiness and complexity. If you are looking to produce a haplotype network, the very same Fitchi algorithm is available in the software [Hapsolutely](https://academic.oup.com/bioinformaticsadvances/article/4/1/vbae083/7688355?login=false) and that is probably a "safer" approach.

#### `./ngs_genotyping`:
Batch scripts to run the legacy version of our in-house genotyping pipeline ([markravinet/genotyping_pipeline_v2](https://github.com/markravinet/genotyping_pipeline_v2)).
  
  - `call_variants.sh`: Runs the second stage of the pipeline
  - `trim_and_align.sh`: Runs the first stage of the pipeline
  - `filter_variants.sh`: Runs the third and final stage of the pipeline.
