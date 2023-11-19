#!/usr/bin/Rscript

# library(Biostrings)

# --------------------------------------------------------------------------------
# ----------------------------------  DESCRIPTION --------------------------------
# This script ...
# -------------------------------  End Description -------------------------------
# --------------------------------------------------------------------------------

args = commandArgs(trailingOnly = TRUE)

# --------------------------------------------------------------------------------
# ----------------------------------  USER INPUT ---------------------------------
analysisDirsFile  = args[1]
outPathAllAnalysis = args[2]

    # analysisDirsFile = "/home/wordenp/Scripts/General_Scripts/Dvex_workflow_dev/noBarcode/pathsToAnalyses.txt"
    # outPathAllAnalysis = "/home/wordenp/Scripts/General_Scripts/Dvex_workflow_dev/noBarcode"
# --------------------------------  End User Input -------------------------------
# --------------------------------------------------------------------------------


# --------------------------------------------------------------------------------
# ----------------------------------- FUNCTIONS ----------------------------------

# ---------- Find a common string from a set of fastq files ----------
# A basic string will be assigned if no common string is found
find_common_string <- function(file_names) {
  # Find the length of the shortest file name
  min_length <- min(nchar(file_names))
  # Initialize the common string
  common_string <- ""
  # Loop through each position in the file names
  for (i in 1:min_length) {
    # Extract characters at position 'i' for all file names
    chars <- substr(file_names, i, i)
    # Check if all characters at position 'i' are the same
    if (all(chars == chars[1])) {
      # Append the character to the common string
      common_string = paste0(common_string, chars[1])
    } else {
      # If characters are not the same, break the loop
      break
    }
  }
  return(common_string)
}


# ---------- FUNCTION: Concatenate fastq files within an analyses ----------
readTableUnzipFastq <- function(inputTablePath) {
  # i = 1
  # inputTablePath = inputAnalysesParents[i]
  readTableSingleAnalysisPath = list.files(inputTablePath, pattern = "_sp.tsv", full.names = TRUE)
  
  if (!file.exists(readTableSingleAnalysisPath)) {
    cat("Your sample table is missing.\n")
  }
  readTableSingleAnalysis = read.delim(file = readTableSingleAnalysisPath, check.names = FALSE)
  barCodenames = readTableSingleAnalysis$barcode_number
  barCodePaths = readTableSingleAnalysis$barcode_paths
    # # For the single barcodes of nobarcodes?
    # barCodePaths = unique(readTableSingleAnalysis$barcode_paths)
  barCodeCount = length(barCodePaths)
  fastqPaths = readTableSingleAnalysis$parent_fastq_paths
  if (barCodeCount < 1) {
    print("Your table is empty. Please add data")
  }
  
  # Create parent output to copy over concatenated fastq files for each barcode
  uniqueBarcodeOutDir = unique(readTableSingleAnalysis$subparent_analysis_name)
  outPathSingleAnalysis = paste0(outPathAllAnalysis, "/", uniqueBarcodeOutDir)


  if (!dir.exists(outPathSingleAnalysis)){
    dir.create(outPathSingleAnalysis)
  } else {
    print("Directory already exists!")
  }
  
  outConcatFastqPaths = c()
  for (a in 1:barCodeCount) {
    currentFastqDir = barCodePaths[a]
    currentFastqFiles = list.files(currentFastqDir, pattern = "*.fastq.gz$")
    currentSample = barCodenames[a]
    common_string = find_common_string(currentFastqFiles)
    common_string = gsub("_$", "", common_string)
    currentOutFile = paste0(common_string, "_", currentSample, "_cat", ".fastq.gz")
    originalConcatFilePath = paste0(currentFastqDir, "/", currentOutFile)
    outConcatFilePath = paste0(outPathSingleAnalysis, "/", currentOutFile)
    concatOutCommand = paste0("cat ", '"', currentFastqDir, '"', "/", "*.fastq.gz > ", outConcatFilePath)
    system(concatOutCommand)
    print(concatOutCommand)
    gunzipCommand = paste0("gunzip ", outConcatFilePath)
    system(gunzipCommand)
    # file.remove(outConcatFilePath)
    tempPath = outConcatFilePath
    outConcatFastqPaths = c(outConcatFastqPaths, tempPath)
    print(gunzipCommand)
  }
  readTableSingleAnalysis["fastq_paths"] = outConcatFastqPaths
  readTableSingleAnalysisOut = gsub(".tsv", "_extra.tsv", readTableSingleAnalysisPath)
  write.table(x = readTableSingleAnalysis, file = readTableSingleAnalysisOut, sep = "\t", row.names = FALSE, quote = FALSE)
}

# --------------------------------- End Functions --------------------------------
# --------------------------------------------------------------------------------

inputAnalysesParents = readLines(analysisDirsFile)

for (i in 1:length(inputAnalysesParents)){
  readTableUnzipFastq(inputAnalysesParents[i])
}
