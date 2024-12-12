#!/bin/bash

# NB!
#
#     1. This script requires an internet connection.
#     On e.g. Saga, this is limited on compute nodes. Run
#     this from a login node.
#
#     2. This script can take a long time to complete.
#     To ensure it runs to completion, run it on a
#     screen terminal or using nohup.
#
#     To call it with nohup, use:
#
#     nohup bash fetch-nird-reads.sh > name-of-outfile.out &
#
# NB!

# User definitions
species="domesticus"
id_list_file=
to_directory=

# Work start
cd ${to_directory}

while read sample_id; do
    rsync -ravzhP /nird/projects/NS10082K/${species}/${sample_id}* .
done <${id_list_file}

find "$PWD"/ -type f | grep R1_* | sort > reads_forward.list
find "$PWD"/ -type f | grep R2_* | sort > reads_reverse.list
find "$PWD"/ -type f | grep .fastq.gz* | sort > reads_all.list
# Work end
