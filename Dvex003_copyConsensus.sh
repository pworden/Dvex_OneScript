
#!/bin/bash

# -------------------------------------------------------------------------------- #
# ------------------------------ Script Description ------------------------------ #
# This script is the next stage after "Dvex02_NGSpeciesNT.sh". It does the following:
# For each barcode it copies all the consensus.fasta files (sometimes more than one per barcode)
# that were output from the previous script (Dvex02_NGSpeciesNT.sh) into a single directory.
# Each copied file is also renamed with a name that includes its barcode
# (from one directory up from the parent) and its medaka number (from the parent directory).
# Invoke the script as below:
    # parentDir="/home/wordenp/projects/sangopore_project/analyses/Sangopore_Dvex_2-11-23/barcodes1-13_2-11-23"
    # outDirName="Consensus_Collation"
    # bash Dvex03_copyConsensus.sh $parentDir $outDirName
# -------------------------------------------------------------------------------- #
# -------------------------------------------------------------------------------- #

# source /home/wordenp/mambaforge/etc/profile.d/conda.sh # Path to conda

# -------------------------------------------------------------------------------- #
# ---------------------------------EXTERNAL INPUT -------------------------------- #
parentDir=$1
outDirName=$2
# ------------------------------ END External Input ------------------------------ #
# -------------------------------------------------------------------------------- #

parentDirName=${parentDir##*/}
outputDir=$parentDir/$outDirName

if [ -e "$outputDir" ]; then echo "Folder exists!"; else mkdir "$outputDir"; echo "Creating folder: " "$outputDir"; fi

fullPathsToConsensus=($( find $parentDir -maxdepth 5 -type f -name "consensus.fasta" ))

# path=${fullPathsToConsensus[0]}
for path in ${fullPathsToConsensus[@]}; do \
    # Remove all text before the target word ($parentDirName)
    string="${path#*$parentDirName\/}"; \
    string2="${string/_SpecID_Out\//_}"; \
    string3="${string2/\/consensus/}";
    out_name="${string3/\//_}"; \
    cp $path $outputDir/$out_name; \
done
