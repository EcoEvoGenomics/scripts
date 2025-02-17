#!/bin/bash

# ADMIN
#SBATCH --job-name=make_haplotype_network
#SBATCH --output=SLURM-%j-%x.out
#SBATCH --error=SLURM-%j-%x.err
#SBATCH --account=nn10082k
#
# RESOURCE ALLOCATION
#SBATCH --nodes=1
#SBATCH --tasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3G
#SBATCH --time=02:00:00

# User definitions
work_directory=
input_iqtree_nexus_uniqueseq_alignment=
input_iqtree_treefile=
input_iqtree_logfile=
pop_map_csv=
fitchi_options="--seed 123"
fitchi_svg_options="-e svg_simple"
pop_colors="['000080']"
line_color="002B36"
line_width=0.75
dot_radius=0.1
remove_node_labels=TRUE
output_name="fitchi_output"

# Prepare environment
set -o errexit
set -o nounset
module --quiet purge

# Load modules
module load Miniconda3/22.11.1-1
module list

# Load conda environment for fitchi
source ${EBROOTMINICONDA3}/bin/activate
conda activate /cluster/projects/nn10082k/conda_users/eriksro/fitchi
conda list
echo ""

# Begin work
cd ${work_directory}

# Filenames for output
fitchi_input_file=${output_name}.fitchi.nex
fitchi_output_html=${output_name}.fitchi.html
fitchi_output_svg=${output_name}.fitchi.svg

if [ -f $fitchi_input_file ]; then
    echo "Using existing fitchi input file $fitchi_input_file!"
else
    echo "Parsing input IQ-TREE files ..."

    # Filenames for temporary files
    fitchi_tmp_alignment=${output_name}_tmp.fitchi.nex
    fitchi_tmp_treefile=${output_name}_tmp.fitchi.treefile
    fitchi_tmp_input_file=${output_name}_tmp2.fitchi.nex

    # Remove closing statement, i.e. two last lines (incl. newline character), from the iqtree unique sequences alignment
    head -n \
        $(( $(wc -l < $input_iqtree_nexus_uniqueseq_alignment) - 2 )) \
        $input_iqtree_nexus_uniqueseq_alignment \
        > $fitchi_tmp_alignment

    # Find and reintroduce non-unique haplotypes in iqtree alignment file using the iqtree logfile
    grep "^NOTE:.*is ignored but added at the end" $input_iqtree_logfile \
    | awk -F'[() ]' '{print $2 ", " $6}' \
    | while IFS=, read -r omitted_haplotype_id identical_haplotype_id; do
        
        # Remove whitespace from IDs
        omitted_haplotype_id=$(echo "$omitted_haplotype_id" | xargs)
        identical_haplotype_id=$(echo "$identical_haplotype_id" | xargs)

        # Obtain the shared haplotype sequence and append to the alignment file
        shared_haplotype_seq=$(grep $identical_haplotype_id $input_iqtree_nexus_uniqueseq_alignment | awk '{print $2}' )
        printf "\t%s %s\n" $omitted_haplotype_id $shared_haplotype_seq >> $fitchi_tmp_alignment

    done

    # Replace the alignment closing statement and output alignment section of Fitchi input
    printf "\t%s\n%s\n" ";" "end;" >> $fitchi_tmp_alignment
    cat $fitchi_tmp_alignment > $fitchi_tmp_input_file

    # Now parse the phylogeny - first remove support values from iqtree treefile
    sed 's/)[0-9]\{1,3\}:/):/g' $input_iqtree_treefile > $fitchi_tmp_treefile

    # Bind treefile and nexus formatting to alignment made above
    printf "\n%s\n\t%s%s\n%s\n" \
        "begin trees;"\
        "tree input = " "$(cat $fitchi_tmp_treefile)" \
        "end;" \
        >> $fitchi_tmp_input_file

    # Finally, map population to each sample and replace all "sample" ids with "population_sample" ids
    declare -A pop_map
    while IFS=, read -r sample population; do
        pop_map["$sample"]="${population}_${sample}"
    done < $pop_map_csv

    # This is extremely inefficient, but the whole script does not take prohibitively long anyways
    while IFS= read -r line; do
        for sample in "${!pop_map[@]}"; do
            line=$(echo "$line" | sed "s/\b$sample\b/${pop_map[$sample]}/g")
        done
        echo "$line"
    done < $fitchi_tmp_input_file > $fitchi_input_file

    echo "Removing temporary parsing files ... "
    rm -v $fitchi_tmp_alignment $fitchi_tmp_treefile $fitchi_tmp_input_file
    
    echo "Done parsing input data! Saved parsed input data to $fitchi_input_file."
fi

# Clone fitchi repository
echo "Cloning Fitchi repository ..."
git clone https://github.com/mmatschiner/Fitchi

# Remove genealogical sorting index code - breaks when using multiple populations
sed "2754, 2758 d" ./Fitchi/fitchi.py | sed "3209, 3239 d" > ./Fitchi/fitchi_tmp.py

# Replace population colours and other aesthetic preferences that are not "official" Fitchi options
sed -i "2642a\\# Overwrite colours\ncolors = ${pop_colors}\n" ./Fitchi/fitchi_tmp.py
sed -i "s/stroke_color = '93a1a1'/stroke_color = '${line_color}'/" ./Fitchi/fitchi_tmp.py
sed -i "s/stroke_width = 1.0/stroke_width = ${line_width}/" ./Fitchi/fitchi_tmp.py
sed -i "s/dot_radius = 1.5/dot_radius = ${dot_radius}/" ./Fitchi/fitchi_tmp.py

# Restore original file name
mv ./Fitchi/fitchi_tmp.py ./Fitchi/fitchi.py

# Fitchi has no built-in option not to plot node labels, but the labelling code can be removed
if [ "$remove_node_labels" == "TRUE" ]; then
    node_labeller_start_line=1267
    node_labeller_end_line=1290
    sed "${node_labeller_start_line},${node_labeller_end_line} d" ./Fitchi/fitchi.py > ./Fitchi/fitchi_tmp.py
    mv ./Fitchi/fitchi_tmp.py ./Fitchi/fitchi.py
fi

# Run fitchi
echo "Constructing haplotype network, saving Fitchi report to $fitchi_output_html ... "
echo " $fitchi_options" | xargs python3 ./Fitchi/fitchi.py $fitchi_input_file $fitchi_output_html
echo " $fitchi_svg_options" | xargs python3 ./Fitchi/fitchi_extract.py $fitchi_output_html $fitchi_output_svg

# Tidy up fitchi
echo "Tidying up Fitchi repository ..."
rm -rv ./Fitchi
echo "Done."

# End work

# To cite Fitchi, see:
# - Matschiner M (2015) Fitchi: Haplotype genealogy graphs based on the Fitch algorithm. Bioinformatics, 32:1250-252.
