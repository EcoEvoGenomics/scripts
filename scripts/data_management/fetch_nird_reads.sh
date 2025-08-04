#!/bin/bash

# NB!
#
#     1. This script requires that NIRD is mounted.
#     On Saga, this is not the case on compute nodes.
#     Run this from a login node.
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
    rsync -ravzhP /nird/projects/NS10082K/reads/${species}/${sample_id}* .
done <${id_list_file}

find "$PWD"/ -type f -name "*R1_*" | sort > fetched_reads_R1.list
find "$PWD"/ -type f -name "*R2_*" | sort > fetched_reads_R2.list
cat reads_forward.list reads_reverse.list | sort > fetched_reads.list
# Work end
