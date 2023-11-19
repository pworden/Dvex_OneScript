#!/bin/bash

# -------------------------------------------------------------------------------- #
# ------------------------------ Script Description ------------------------------ #
# This script is the next stage after "Dvex001_concatFastq.R". It does the following:
# 1. Gathers the data from the TSV files with the prefix "_extra.tsv" which hold all inputs needed by NGSpeciesID 
# 2. Perform analysis using NGSpeciesID
# -------------------------------------------------------------------------------- #
# -------------------------------------------------------------------------------- #

source /home/wordenp/mambaforge/etc/profile.d/conda.sh # Path to conda
conda activate NGSpeciesID
# -------------------------------------------------------------------------------- #
# -------------------------------- EXTERNAL INPUT -------------------------------- #
                # parentOutputPath="/home/wordenp/projects/sangopore_project/analyses/Sangopore_Dvex_2-11-23"
parentOutputPath=$1
# ------------------------------ END External Input ------------------------------ #
# -------------------------------------------------------------------------------- #

sp_extra_List=($( find $parentOutputPath -maxdepth 2 -type f -name *"_sp_extra.tsv" ))
echo ${sp_extra_List[@]}
primersFileAndPath=($( find $parentOutputPath -maxdepth 2 -type f -name *"_sp.fasta" ))
echo ${primersFileAndPath[@]}


# Read the file paths from the file variable and copy each file with a new name into a new output directory 
i=0
for tsv_file_path in ${sp_extra_List[@]}; do
        # tsv_file_path=${sp_extra_List[i]}
        seqLength=($( tail -n +2 ${sp_extra_List[i]} | cut -f5 | uniq ))
        variation=($( tail -n +2 ${sp_extra_List[i]} | cut -f6 | uniq ))
        tempOutBaseDir=${tsv_file_path%/*}
        tempPrimersFileAndPath=${primersFileAndPath[i]}
        tempBarcodes=($( tail -n +2 ${sp_extra_List[i]} | cut -f1 ))
        tsvFastqList=($( tail -n +2 ${sp_extra_List[i]} | cut -f7 ))
        echo ${tempBarcodes[@]}
        echo ${tsvFastqList[@]}

                        # primerfiles=$(tail -n +2 ${sp_extra_List[i]} | cut -f2 )
                        # file_path=${sp_extra_List[i]}
                        # tempInputPath=${file_path%/*}
                        # outputFileName=${tempInputPath##*/}
                        # outputFolder=$tempInputPath/$outputFileName"_SpecID_Out"
        a=0
        for fastq_input_path_gz in ${tsvFastqList[@]}; do
                # fastq_input_path_gz=${tsvFastqList[a]}
                fastq_input_path=${fastq_input_path_gz%.*}
                tempAnanlysisOutDir=$tempOutBaseDir/${tempBarcodes[a]}"_SpecID_Out"
	        NGSpeciesID --ont --consensus --medaka --fastq $fastq_input_path --m $seqLength --s $variation --t 16 --primer_file $tempPrimersFileAndPath --outfolder $tempAnanlysisOutDir
        a=$(( $a+1 ))
        done
i=$(( $i+1 ))
done
