#!/bin/bash

# # Run this script as follows:
# bash Dvex00_0_concat_all_fastq_runWrap.sh

# Activate the R conda environment
source "/home/wordenp/mambaforge/etc/profile.d/conda.sh"
conda activate r-base

# -------------------------------------------------------------------------------- #
# ------------------------------- DVEX000 SECTION -------------------------------- #

		# R_scriptPath000="/home/wordenp/Scripts/General_Scripts/Dvex_workflow_dev/Dvex000_setupUsingtable.R"
		# tableInputPath="/home/wordenp/projects/sangopore_project/raw/sequence_data/Sangopore_Dvex_2-11-23/fastq_pass/Run_metadata_template_2-11-23.txt"
		# parentOutputPath="/home/wordenp/projects/sangopore_project/analyses/Sangopore_Dvex_2-11-23"

# >>>>>>> USER INPUT <<<<<<< #
R_scriptPath000="/home/wordenp/Scripts/General_Scripts/Dvex_workflow_dev/Dvex000_setupUsingtable.R"
tableInputPath="/home/wordenp/Scripts/General_Scripts/Dvex_workflow_dev/Run_metadata_template.txt"
parentOutputPath="/home/wordenp/Scripts/General_Scripts/Dvex_workflow_dev/allBarcodes"
# >>>>> End User Input <<<<< #

# This script will read the input table and create folders for each separate analyses.
# With the folder for each analysis will be a primer fasta file and a TSV file with 
	# data for that specific analysis
# A text file of paths for each analysis will also be created and saved in the output parent directory
	# The directory holding all analyses outputs
Rscript $R_scriptPath000 $tableInputPath $parentOutputPath

# ----------------------------- End Dvex000 Section ------------------------------ #
# -------------------------------------------------------------------------------- #

##### NOTE: The remaining section of this script should not require any changes to the user input sections of the script
		# Unless the paths of the supporting scripts change.
		# Only the above inputs should need changing


# -------------------------------------------------------------------------------- #
# ------------------------------- DVEX001 SECTION -------------------------------- #

inputAnalysesDirsFile=$parentOutputPath"/pathsToAnalyses.txt"
# $parentOutputPath (variable with path) used in this "Dvex001_concatFastq.R" script is from previous section

# >>>>>>> USER INPUT <<<<<<< #
R_scriptPath001="/home/wordenp/Scripts/General_Scripts/Dvex_workflow_dev/Dvex001_concatFastq.R"
# >>>>> End User Input <<<<< #

# This script will read the input table and create folders for each separate analyses.
# With the folder for each analysis will be a primer fasta file and a TSV file with 
	# data for that specific analysis
# A text file of paths for each analysis will also be created and saved in the output parent directory
	# The directory holding all analyses outputs
Rscript $R_scriptPath001 $inputAnalysesDirsFile $parentOutputPath

# ----------------------------- End Dvex001 Section ------------------------------ #
# -------------------------------------------------------------------------------- #




# -------------------------------------------------------------------------------- #
# ------------------------------- DVEX002 SECTION -------------------------------- #

# >>>>>>> USER INPUT <<<<<<< #
bashScript_NGSpeciesNT_002="/home/wordenp/Scripts/General_Scripts/Dvex_workflow_dev/Dvex002_NGSpeciesNT.sh"
# >>>>> End User Input <<<<< #

# $parentOutputPath (variable with path) is again used as in in this Dvex001 Section
bash $bashScript_NGSpeciesNT_002 $parentOutputPath
# ----------------------------- End Dvex002 Section ------------------------------ #
# -------------------------------------------------------------------------------- #




# -------------------------------------------------------------------------------- #
# ------------------------------- DVEX003 SECTION -------------------------------- #
# >>>>>>> USER INPUT <<<<<<< #
Dvex03_copyConsensusScript="/home/wordenp/Scripts/General_Scripts/Dvex_workflow_dev/Dvex003_copyConsensus.sh"
# >>>>> End User Input <<<<< #

pathsToAnalysisArray=($(<$inputAnalysesDirsFile))
		# parentDir="/home/wordenp/projects/sangopore_project/analyses/Sangopore_Dvex_2-11-23/barcodes1-13_2-11-23"
		# outDirName="Consensus_Collation"
for parentDir in ${pathsToAnalysisArray[@]} ; do 
	outDirName="Consensus_Collation"
	bash $Dvex03_copyConsensusScript $parentDir $outDirName
done
# ----------------------------- End Dvex003 Section ------------------------------ #
# -------------------------------------------------------------------------------- #




# -------------------------------------------------------------------------------- #
# ------------------------------- DVEX004 SECTION -------------------------------- #
# >>>>>>> USER INPUT <<<<<<< #
Dvex004_FastaheaderRename="/home/wordenp/Scripts/General_Scripts/Dvex_workflow_dev/Dvex004_FastaheaderRename.sh"
# >>>>> End User Input <<<<< #
pathsToAnalysisArray=($(<$inputAnalysesDirsFile))
		# parentDir="/home/wordenp/projects/sangopore_project/analyses/Sangopore_Dvex_2-11-23/barcodes1-13_2-11-23" # <-- Single input only
for parentDir in ${pathsToAnalysisArray[@]} ; do 
	outputDir004=$parentDir"/Consensus_Collation"
	bash $Dvex004_FastaheaderRename $outputDir004
done
# ----------------------------- End Dvex004 Section ------------------------------ #
# -------------------------------------------------------------------------------- #




# -------------------------------------------------------------------------------- #
# ------------------------------- DVEX005 SECTION -------------------------------- #
# The parent directory containing all blast output folders 
	# parentDirForBlastInput="/home/wordenp/projects/sangopore_project/analyses/Sangopore_Dvex_2-11-23/barcodes1-13_2-11-23/Consensus_Collation"
# >>>>>>> USER INPUT <<<<<<< #
blast_remote_ScriptPath="/home/wordenp/Scripts/General_Scripts/Dvex_workflow_dev/Dvex005_1_blast_remote.sh"
blastDbPath="/home/wordenp/databases/blast_dbs/nt/nt"
targetSuffix="_newHeader.fasta"
# >>>>> End User Input <<<<< #

parentDirForBlastInput=( $( find $parentOutputPath -maxdepth 4 -type d -name "Consensus_Collation" ) )

for tempParentDirForBlastInput in "${parentDirForBlastInput[@]}"; do
    inputConsensusPaths=( $(find "$tempParentDirForBlastInput" -maxdepth 2 -type f -name "*$targetSuffix") )

    for inputFastaConsensus in "${inputConsensusPaths[@]}"; do
        bash "$blast_remote_ScriptPath" "$inputFastaConsensus" "$blastDbPath"
        echo "$inputFastaConsensus"
    done
done
# ----------------------------- End Dvex005 Section ------------------------------ #
# -------------------------------------------------------------------------------- #




# -------------------------------------------------------------------------------- #
# ------------------------------- DVEX006 SECTION -------------------------------- #
# >>>>>>> USER INPUT <<<<<<< #
# The $parentDirForBlastInput path variable was generated from above
Dvex06_1_rScriptPath="/home/wordenp/Scripts/General_Scripts/Dvex_workflow_dev/Dvex006_1_blastTableOrganise.R"
# >>>>> End User Input <<<<< #

# Find the number of analyses by finding all "Consensus_Collation" folders within the parent folder
for tempParentDirForBlastInput in "${parentDirForBlastInput[@]}"; do
	Rscript $Dvex06_1_rScriptPath $tempParentDirForBlastInput
done
# ----------------------------- End Dvex006 Section ------------------------------ #
# -------------------------------------------------------------------------------- #

