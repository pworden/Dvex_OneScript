#!/usr/bin/Rscript

# --------------------------------------------------------------------------------
# -------------------------------  PACKAGE INSTALLS ------------------------------
if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

BiocManager::install("Biostrings")
# ----------------------------  End Package Installs -----------------------------
# --------------------------------------------------------------------------------



library(Biostrings)

# --------------------------------------------------------------------------------
# ----------------------------------  DESCRIPTION --------------------------------
# This script will read the user created tab-delimited file that contains all the
# necessary information that the script NGSpeciesID will require as well as some 
# additional information such as where the output will be saved, their file-names, 
# and some basic analysis.
# -------------------------------  End Description -------------------------------
# --------------------------------------------------------------------------------

args = commandArgs(trailingOnly = TRUE)

# --------------------------------------------------------------------------------
# ----------------------------------  USER INPUT ---------------------------------
# Only initial input is the table of paths and values
tableInputPath = args[1]
parentOutputPath = args[2]
# tableInputPath = "/home/wordenp/projects/sangopore_project/raw/sequence_data/Sangopore_Dvex_2-11-23/fastq_pass/Run_metadata_template_2-11-23.txt"
  # This input is important or the output path will be missing
# parentOutputPath = "/home/wordenp/projects/sangopore_project/analyses/Sangopore_Dvex_2-11-23"
# --------------------------------  End User Input -------------------------------
# --------------------------------------------------------------------------------


# --------------------------------------------------------------------------------
# ----------------------------------- FUNCTIONS ----------------------------------
# This function creates a new folder for each analysis and into each new analysis folder
# and a TSV file with all necessary metadata will be created (excluding primer data).
# A fasta primer file will also be created
tableSplit = function(listNum) {
  print("Running table split")
    table_sub = split_input_table[[listNum]]
    # Create a directory for each analysis, and into it write:
    outputDir = paste0(parentOutputPath, "/", unique(table_sub$subparent_analysis_name))
    if (!dir.exists(outputDir)) {
      dir.create(outputDir)
      print(paste0("Created ", outputDir))
    } else {
      (dir.exists(outputDir))
      print(paste0(outputDir, " already exists"))
    }
    # Create a fasta primer table
    seqTable = unique(table_sub[,c(6:9)])
    
  # Need to catch error HERE if there are unequal numbers of F and R primers (line above)
  
    # Extract both forward and reverse primer sequences and names from seqTable
    f_sequences = DNAStringSet(seqTable$primer_F_seq)
    r_sequences = DNAStringSet(seqTable$primer_R_seq)
    # Set names for the forward and reverse primers
    names(f_sequences) = seqTable$primer_F_name
    names(r_sequences) = seqTable$primer_R_name
    # Combine forward and reverse primers into a single DNAStringSet
    combined_primers = c(f_sequences, r_sequences)
    # Define the output file name
    outputFastaPath = paste0(outputDir, "/", unique(table_sub$subparent_analysis_name), "_sp.fasta")
    collapsedBarcodeNames = paste(table_sub$barcode_number, collapse = "|")
    # barcodesAndPaths = table_sub$parent_fastq_paths

    if(length(table_sub$barcode_number) > 1){
      barcodesAndPaths = list.files(unique(table_sub$parent_fastq_paths), pattern = collapsedBarcodeNames, full.names = TRUE, include.dirs = TRUE)
    } else {
      barcodesAndPaths = table_sub$parent_fastq_paths
    }

    # collapsedBarcodeNames = paste(table_sub$barcode_number, collapse = "|")
      # barcodesAndPaths = list.files(unique(table_sub$parent_fastq_paths), pattern = collapsedBarcodeNames, full.names = TRUE, include.dirs = TRUE)
      # Or
      # barcodesAndPaths = table_sub$parent_fastq_paths
    outputTablepath = paste0(outputDir, "/", unique(table_sub$subparent_analysis_name), "_sp.tsv")
    extended_table_sub = table_sub[,c(1:5)]
    extended_table_sub$barcode_paths = barcodesAndPaths
    extended_table_sub = extended_table_sub[, c(1, length(extended_table_sub), 2:(length(extended_table_sub)-1))]
    write.table(x = extended_table_sub, file = outputTablepath, row.names = FALSE, quote = FALSE, sep = "\t")
    
    # Write the combined DNAStringSet to the multi-FASTA file
    writeXStringSet(combined_primers, outputFastaPath)
    parentAnalysesFolder = parentOutputPath
    outAnalysisName = unique(table_sub$subparent_analysis_name)
    fileSummOut = paste0(parentAnalysesFolder, "/", "pathsToAnalyses.txt")
    cat(outputDir, file=fileSummOut,append=TRUE, sep = "\n")
}

# Function will run if there are no barcodes or only one set of primers for all barcodes
oneTable = function(sangoInputTable) {
      # table_sub = sangoporeInputTable # For testing
    table_sub = sangoInputTable
    # Create a directory for the single analysis, and into it write:
    outputDir = paste0(parentOutputPath, "/", unique(table_sub$subparent_analysis_name))
    if (!dir.exists(outputDir)) {
      dir.create(outputDir)
      print(paste0("Created ", outputDir))
    } else {
      (dir.exists(outputDir))
      print(paste0(outputDir, " already exists"))
    }
    # Create a fasta primer table
    seqTable = unique(table_sub[,c(6:9)])
    
  # Need to catch error HERE if there are unequal numbers of F and R primers (line above)
  
    # Extract both forward and reverse primer sequences and names from seqTable
    f_sequences = DNAStringSet(seqTable$primer_F_seq)
    r_sequences = DNAStringSet(seqTable$primer_R_seq)
    # Set names for the forward and reverse primers
    names(f_sequences) = seqTable$primer_F_name
    names(r_sequences) = seqTable$primer_R_name
    # Combine forward and reverse primers into a single DNAStringSet
    combined_primers = c(f_sequences, r_sequences)
    # Define the output file name
    outputFastaPath = paste0(outputDir, "/", unique(table_sub$subparent_analysis_name), "_sp.fasta")
    
    # collapsedBarcodeNames = paste(table_sub$barcode_number, collapse = "|")
    barcodesAndPaths = table_sub$parent_fastq_paths
    outputTablepath = paste0(outputDir, "/", unique(table_sub$subparent_analysis_name), "_sp.tsv")
    extended_table_sub = table_sub[,c(1:5)]
    extended_table_sub$barcode_paths = barcodesAndPaths
    extended_table_sub = extended_table_sub[, c(1, length(extended_table_sub), 2:(length(extended_table_sub)-1))]
    write.table(x = extended_table_sub, file = outputTablepath, row.names = FALSE, quote = FALSE, sep = "\t")
    
    # Write the combined DNAStringSet to the multi-FASTA file
    writeXStringSet(combined_primers, outputFastaPath)
          # outAnalysisName = unique(table_sub$subparent_analysis_name)
    fileSummOut = paste0(parentOutputPath, "/", "pathsToAnalyses.txt")
    cat(outputDir, file=fileSummOut, append=TRUE, sep = "\n")
}

# --------------------------------- End Functions --------------------------------
# --------------------------------------------------------------------------------

# Read in the initial user generated TSV with all required information
sangoporeInputTable = read.delim(file = tableInputPath, check.names = FALSE)

if (!dir.exists(parentOutputPath)) {
  dir.create(parentOutputPath)
  print(paste0("Created ", parentOutputPath))
}

# Determine the names and number of analyses
analysesNames = unique(sangoporeInputTable$subparent_analysis_name)
numberOfAnalyses = length(analysesNames)

# Remove the any old "pathsToAnalyses.txt" file if present
checkFilePath = paste0(dirname(tableInputPath), "/", "pathsToAnalyses.txt")
if (checkFilePath == TRUE) {
  file.remove(checkFilePath)
  print(paste0("Removed: ", dirname(tableInputPath), "/", "pathsToAnalyses.txt"))
}


if (nrow(sangoporeInputTable) > 1) {
  # Split the table if more than one analysis is required
    # Determined by whether there are more than one unique set of "subparent_analysis_names"
  split_input_table = split(sangoporeInputTable, sangoporeInputTable$subparent_analysis_name)
  # Loop through the tableSplit function described above for each analysis
    for (i in 1:numberOfAnalyses) {
      tableSplit(i)
    }
} else {
  oneTable(sangoporeInputTable)
}
