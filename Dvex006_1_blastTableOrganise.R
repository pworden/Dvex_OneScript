#!/usr/bin/Rscript

args=commandArgs(trailingOnly=TRUE)

# The following function will input a TSV table from blastn output, then 
# order it based on bit_score and then query_coverage.
# Also, column 2 will be refine to retain only the NCBI gene bank accessions
# while the "gi" identifiers (and other unnecessary character symbols) will be removed
# This function also saves these new results as a CSV file
refineBlastnTSV <- function(inputPath) {

  # Input TSV file without headers
  completeBlastTable = read.table(file=inputPath, header=FALSE, sep = "\t", stringsAsFactors = FALSE, check.names = FALSE)
  # Vector of header names
  df_headers = c(
    "Query_Seq_id",
    "Subject_Seq_id",
    "Query_Coverage",
    "Query_Length",
    "Percent_identical_matches",
    "Alignment_length",
    "Number_mismatches",
    "Number_gap_openings",
    "Start_alignment_in_query",
    "End_alignment_in_query",
    "Start_alignment_in_subject",
    "End_alignment_in_subject",
    "Expect_value",
    "Bit_score",
    "Subject_Taxonomy_ID",
    "Subject_Title",
    "Aligned_query_no_gaps",
    "Aligned_subject_no_gaps"
  )
  
  # Change header names 
  colnames(completeBlastTable) = df_headers
  # Order the table based on first bit-score and then query-coverage 
  completeBlastTable = completeBlastTable[order(completeBlastTable$Bit_score, completeBlastTable$Percent_identical_matches, decreasing = TRUE), ]
  # refine the "Subject_Seq_id" column of the data frame, keeping only gene identifier
  unpackSubjectIdCol = completeBlastTable$Subject_Seq_id
  unpackSubjectIdCol = gsub("^gi\\|.*\\|gb\\|(.*)\\|", "\\1", unpackSubjectIdCol)
  completeBlastTable$Subject_Seq_id = unpackSubjectIdCol
  completeBlastTable$Aligned_query_no_gaps = gsub("-", "", completeBlastTable$Aligned_query_no_gaps)
  completeBlastTable$Aligned_subject_no_gaps = gsub("-", "", completeBlastTable$Aligned_subject_no_gaps)
  # Get the input file name and directory name from the input path 
  inputDir = dirname(inputPath)
  inputFileName = basename(inputPath)
  inputFileBase = gsub("^(.*)_newHeader_blastn.tsv$", "\\1", inputFileName)
  outputPath = paste0(inputDir, "/", inputFileBase, "_ordered.csv")
  # Output the refined table to disk as a CSV file (removing from the output name: "_54_newHeader_blastn.tsv")
  write.csv(x = completeBlastTable, file = outputPath, row.names = FALSE)
  # Output the refined table to memory
  return(completeBlastTable)
}

    # # Read in path to input table - The following two lines are for single input only
    # inputBlastTSVAndPath = "/Users/paulworden/Library/CloudStorage/OneDrive-DPIE/Sangopore_Dev/Sangopore_R_Dev/Blastn_Make_Summaries/Consensus_Collation/blast_barcode25_medaka_cl_id_54_newHeader/barcode25_medaka_cl_id_54_newHeader_blastn.tsv"
    # refinedBlastnOneResult = refineBlastnTSV(inputBlastTSVAndPath)

# ----------
# Get file paths of interest
# Set your input directory
parentConsensusDir = args[1]
# parentConsensusDir="/home/wordenp/Scripts/General_Scripts/Dvex_workflow_dev/allBarcodesOut/Consensus_Collation"


# List files recursively with a maximum depth of 3 and filter by name
fileList = list.files(path = parentConsensusDir, pattern = "_newHeaderblastn.tsv$", recursive = TRUE, full.names = TRUE)
# --> Also need to insert code that checks for empty file
    # for (i in 1:length(fileList)) {
    #   refinedBlastnOneResult = refineBlastnTSV(fileList[i])
    # }


for (i in 1:length(fileList)) {
  tryCatch({
    refinedBlastnOneResult = refineBlastnTSV(fileList[i])
  }, error = function(e) {
    cat("Error processing file:", fileList[i], "\n")
    cat("Error message:", e$message, "\n")
  })
}


# Create a summary directory where all summaries for each barcode will be saved
outSummParentDir = paste0(parentConsensusDir, "/", "blastSummaryFiles")
if (!dir.exists(outSummParentDir)){
  dir.create(outSummParentDir)
}else{
  print("dir exists")
}

# Full output minus the query and subject sequences
CSVfileList = list.files(path = parentConsensusDir, pattern = "_ordered.csv$", recursive = TRUE, full.names = TRUE)
completeTable = data.frame(matrix(nrow = 0, ncol = length(refinedBlastnOneResult)))
for (a in 1:length(CSVfileList)){
  blastTable = read.csv(file = CSVfileList[a], stringsAsFactors = FALSE, check.names = FALSE)
  completeTable = rbind(completeTable, blastTable)
}
completeTable = completeTable[ , c(-(ncol(completeTable)), -(ncol(completeTable)-1))]
write.csv(x = completeTable, file = paste0(outSummParentDir, "/", "blastAllOutput.csv"), row.names = FALSE)


# Summary output 
CSVfileList = list.files(path = parentConsensusDir, pattern = "_ordered.csv$", recursive = TRUE, full.names = TRUE)
colHeaderSubset = c("Query_Seq_id", "Bit_score", "Percent_identical_matches", "Alignment_length", "Subject_Title", "Subject_Taxonomy_ID", "Subject_Seq_id", "Aligned_query_no_gaps", "Aligned_subject_no_gaps")
summaryTable = data.frame(matrix(nrow = 0, ncol = length(colHeaderSubset)))
for (a in 1:length(fileList)){
  summTab = read.csv(file = CSVfileList[a], stringsAsFactors = FALSE, check.names = FALSE)
  summTab = summTab[1, c(colHeaderSubset)]
  summaryTable = rbind(summaryTable, summTab)
}
summaryTableFinal = summaryTable[ , c(-(ncol(summaryTable)),-(ncol(summaryTable)-1))]
write.csv(x = summaryTableFinal, file = paste0(outSummParentDir, "/", "blastSummary.csv"), row.names = FALSE)



# Load the Biostrings package
library(Biostrings)
library(DECIPHER)

for (b in 1:nrow(summaryTable)) {
  # Define the Query and Subject DNA sequences
  currentQuerySeq = DNAString(summaryTable$Aligned_query_no_gaps[b])
  currentSubjectSeq = DNAString(summaryTable$Aligned_subject_no_gaps[b])
  currentAlnBaseName = paste0(summaryTable$Query_Seq_id[b])
  currentAlnBaseDir = paste0(outSummParentDir, "/", currentAlnBaseName)

    if (!dir.exists(currentAlnBaseDir)){
      dir.create(currentAlnBaseDir)
      print("Creating Directory")
    }else{
      print("dir exists")
    }

  currentAlnPathOut = paste0(currentAlnBaseDir, "/", currentAlnBaseName,  "_alnSeq.aln")
  alg = pairwiseAlignment(currentQuerySeq, currentSubjectSeq)
  writePairwiseAlignments(x = alg, file = paste0(currentAlnBaseDir, "/", currentAlnBaseName, ".aln"))
  seq <- c(alignedPattern(alg), alignedSubject(alg))
  # currentHTMLAlnName = paste0(summaryTable$Query_Seq_id[b], ".html")


  tryCatch({
    BrowseSeqs(seq, htmlFile = paste0(currentAlnBaseDir, "/", currentAlnBaseName, ".html"))
    browseURL(path.expand(htmlFile))
    BrowseSeqs(seq, htmlFile = paste0(currentAlnBaseDir, "/", currentAlnBaseName, ".html"))
  }, error = function(e) {
  })

}
