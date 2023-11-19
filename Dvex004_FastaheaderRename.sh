#!/bin/bash

# -------------------------------------------------------------------------------- #
# ------------------------------ Script Description ------------------------------ #
# This script is the next stage after "Dvex03_copyConsensus.sh". It does the following:
# It renames the header (">Descriptive_or_Identifying_text") of each fasta file of interest,
# to give relevant data by adding the barcode and medaka information to the header.
    # Invoke the script as below (parent directory should include the "Consensus_Collation" folder):
        # parentDir="/home/wordenp/projects/sangopore_project/analyses/Sangopore_Dvex_2-11-23/barcodes1-13_2-11-23/Consensus_Collation"
        # bash Dvex_stagDvex04_FastaheaderRename.sh $parentDir
# -------------------------------------------------------------------------------- #
# -------------------------------------------------------------------------------- #

# source /home/wordenp/mambaforge/etc/profile.d/conda.sh # Path to conda

# -------------------------------------------------------------------------------- #
# ---------------------------------EXTERNAL INPUT -------------------------------- #
parentDir=$1
# ------------------------------ END External Input ------------------------------ #
# -------------------------------------------------------------------------------- #

fullPathsToConsensus=($(find "$parentDir" -maxdepth 3 -type f -not -path "*_sp*" -name "*code*.fasta"))

# Loop through all FASTA files in the array
for fasta_file in "${fullPathsToConsensus[@]}"; do \
    # Check if the file exists
    if [ ! -e "$fasta_file" ]; then echo "Error: File '$fasta_file' not found." exit 1; else echo "File found"; fi
    # Read the first line of the file
    first_line=$(head -n 1 "$fasta_file")
    # Check if the first line starts with ">"
    if [[ $first_line == ">"* ]]; then echo "A FASTA header exists, therefore...continuing"; \
        old_header_line=$(awk '/^>/{print; exit}' "$fasta_file"); \
        old_header_line=${old_header_line/#>}; \
        fastaPath=${fasta_file%/*}; \
        filename=$(basename "$fasta_file"); \
        filename_no_extension="${filename%.*}"; \
            # # Add finename to header but keep original header string
            # awk -v new_tag=">$filename_no_extension" -v old_header_line="$old_header_line" 'NR==1 { print new_tag " " old_header_line } NR>1' $fasta_file > $parentDir/$filename_no_extension"_extended_name.fa";
        # Change the header to replect the filename and delete the original header
        awk -v new_tag=">$filename_no_extension" -v old_header_line="$old_header_line" 'NR==1 { print new_tag " " old_header_line} NR>1' $fasta_file > $parentDir/$filename_no_extension"_newHeader.fasta";
    else echo "The FASTA file '$fasta_file' does not have a header. skipping to next file."; fi
done
