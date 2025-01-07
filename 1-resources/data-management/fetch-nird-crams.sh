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
#     nohup bash fetch-nird-crams.sh > name-of-outfile.out &
#
# NB!

# User definitions
species="domesticus"
id_list_file=
to_directory=

# Work start
cd ${to_directory}

while read sample_id; do
    rsync -ravzhP /nird/projects/NS10082K/crams/${species}/${sample_id}* .
done <${id_list_file}

find "$PWD"/ -type f -name "*.cram" | sort > crams.list
find "$PWD"/ -type f -name "*.cram.crai" | sort > crais.list
# Work end
