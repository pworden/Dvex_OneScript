# Sangopore project - Description of scripts

---

## Overview

Below is a detailed description of what the actions of the various scripts that are called by the wrapper bash script *Dvex000_001_runWrap.sh*.

---
---
## Dvex000_setupUsingtable.R


### Loading Libraries

After installing the necessary packages, the script loads the "Biostrings" library to utilize its functionalities.

```R
library(Biostrings)
```

### User Input

The script retrieves user input from command-line arguments. It expects two arguments: the path to the tab-delimited input file (tableInputPath) and the parent output path (parentOutputPath).

```R
args = commandArgs(trailingOnly = TRUE)
tableInputPath = args[1]
parentOutputPath = args[2]
```

### Functions

The script defines two functions:

### tableSplit(listNum)

This function processes a subset of the input table, creating a new folder for each analysis. It generates a TSV file with metadata and a FASTA primer file.

### oneTable(sangoInputTable)

This function is similar to tableSplit but is used when there is only one set of primers for all barcodes or no barcodes.

### Read Input Table

The script reads the user-generated tab-delimited file into a data frame named sangoporeInputTable.

```R
sangoporeInputTable = read.delim(file = tableInputPath, check.names = FALSE)
```

### Output Directory Creation

The script checks if the parent output directory exists; if not, it creates the directory.

```R
if (!dir.exists(parentOutputPath)) {
  dir.create(parentOutputPath)
  print(paste0("Created ", parentOutputPath))
}
```

### Analysis Processing
The script determines the unique analysis names and their count. It then checks for and removes any existing "pathsToAnalyses.txt" file.

```R
analysesNames = unique(sangoporeInputTable$subparent_analysis_name)
numberOfAnalyses = length(analysesNames)

checkFilePath = paste0(dirname(tableInputPath), "/", "pathsToAnalyses.txt")
if (checkFilePath == TRUE) {
  file.remove(checkFilePath)
  print(paste0("Removed: ", dirname(tableInputPath), "/", "pathsToAnalyses.txt"))
}
```

### Table Splitting

If there is more than one analysis, the script splits the input table into subsets based on unique subparent analysis names and processes each subset using the tableSplit function.

```R
if (nrow(sangoporeInputTable) > 1) {
  split_input_table = split(sangoporeInputTable, sangoporeInputTable$subparent_analysis_name)
  for (i in 1:numberOfAnalyses) {
    tableSplit(i)
  }
} else {
  oneTable(sangoporeInputTable)
}

```

## Summary

This script is designed to streamline the preparation of input data for NGSpeciesID analysis and ensures organized output in separate directories for each analysis.

---
---

## Dvex001_concatFastq.R

### Description

This R script performs a workflow that involves concatenating fastq files within specified analysis directories. The script takes input from the user, reads sample tables, and performs file concatenation for each barcode within the analyses. The final concatenated fastq files are stored in a specified output directory.

### User Input

The user is required to provide two command-line arguments:

1. `analysisDirsFile`: Path to a file containing a list of analysis directories.
2. `outPathAllAnalysis`: Path to the output directory where the concatenated fastq files will be stored.

Example:
```bash
./script.R /path/to/analysisDirs.txt /path/to/outputDirectory
```

### Functions
find_common_string

- This function finds a common string among a set of fastq files. If no common string is found, a basic string is assigned.

readTableUnzipFastq

- This function reads a sample table from a specified analysis directory, retrieves information about barcodes and fastq file paths, and concatenates the fastq files for each barcode. The concatenated files are then stored in the output directory.

***Script Execution***

The script starts by parsing command-line arguments and reading the list of analysis directories. For each analysis directory, the readTableUnzipFastq function is called to perform the concatenation of fastq files.

### Command-line arguments

```R
args = commandArgs(trailingOnly = TRUE)
analysisDirsFile  = args[1]
outPathAllAnalysis = args[2]
```

### Read list of analysis directories
```R
inputAnalysesParents = readLines(analysisDirsFile)
```

### Loop through each analysis directory and perform the file concatenation

```R
for (i in 1:length(inputAnalysesParents)){
  readTableUnzipFastq(inputAnalysesParents[i])
}
```

### Conclusion

This script is designed to streamline the process of concatenating fastq files within specified analysis directories, providing a consolidated output for further analysis. Feel free to adjust the user input and modify the script to suit your specific requirements.

***Note:** Make sure to replace `/path/to/analysisDirs.txt` and `/path/to/outputDirectory` with the actual paths when running the script.*

---
---

# NGSpeciesID Analysis Script

## Script Description

This Bash script is designed as the next stage after "Dvex001_concatFastq.R". It performs the following tasks:

1. Gathers data from TSV files with the prefix "_extra.tsv," containing inputs required by NGSpeciesID.
2. Executes analysis using NGSpeciesID.

---

## Script Structure

### Activates the "NGSpeciesID" Conda environment

```bash
source /home/wordenp/mambaforge/etc/profile.d/conda.sh
conda activate NGSpeciesID
```

### Get external input

Defines the parent output path as the first argument passed to the script.

```bash
parentOutputPath=$1
```

### File Path Discovery

Uses the find command to locate files with specific suffixes in the specified output path.

```bash
sp_extra_List=($( find $parentOutputPath -maxdepth 2 -type f -name *"_sp_extra.tsv" ))
primersFileAndPath=($( find $parentOutputPath -maxdepth 2 -type f -name *"_sp.fasta" ))
```

### Analysis Loop

Iterates over each TSV file, extracts relevant information, and performs NGSpeciesID analysis for each associated FASTQ file.

```bash
for tsv_file_path in ${sp_extra_List[@]}; do
    # Extracts information from each TSV file
    seqLength=($( tail -n +2 ${tsv_file_path} | cut -f5 | uniq ))
    variation=($( tail -n +2 ${tsv_file_path} | cut -f6 | uniq ))
    tempOutBaseDir=${tsv_file_path%/*}
    tempPrimersFileAndPath=${primersFileAndPath[i]}
    tempBarcodes=($( tail -n +2 ${tsv_file_path} | cut -f1 ))
    tsvFastqList=($( tail -n +2 ${tsv_file_path} | cut -f7 ))

    for fastq_input_path_gz in ${tsvFastqList[@]}; do
        # Performs NGSpeciesID analysis for each FASTQ file
        fastq_input_path=${fastq_input_path_gz%.*}
        tempAnanlysisOutDir=$tempOutBaseDir/${tempBarcodes[a]}"_SpecID_Out"
        NGSpeciesID --ont --consensus --medaka --fastq $fastq_input_path --m $seqLength --s $variation --t 16 --primer_file $tempPrimersFileAndPath --outfolder $tempAnanlysisOutDir
    done
done
```

An argument specifying the parent output path must be added to the script execution.

```bash
./script.sh /path/to/parent/output
```

---
---

## Dvex03_copyConsensus.sh

This script is designed to perform a specific set of tasks related to file manipulation. Below is a step-by-step explanation of the script's functionality:

### Script Description

The `Dvex03_copyConsensus.sh` script is designed as the next stage after "Dvex02_NGSpeciesNT.sh." It copies `consensus.fasta` files generated by the previous script for each barcode, renaming them with barcode and medaka number information.

### Usage Example

Invoke the script with the following command:

```bash
parentDir="/home/wordenp/projects/sangopore_project/analyses/Sangopore_Dvex_2-11-23/barcodes1-13_2-11-23"
outDirName="Consensus_Collation"
bash Dvex03_copyConsensus.sh $parentDir $outDirName
```

### External Input

The script expects two command-line arguments:

- parentDir ($1): The parent directory containing the output from the previous script.
- outDirName ($2): The name of the output directory where copied files will be stored.

### Main Script

#### Variable Initialization

- parentDirName: Extracts the last part of the parent directory path
- outputDir: Forms the path to the output directory using the parent directory and the provided output directory name.

#### Output Directory Check and Creation:

- Checks if the output directory already exists.
- If it doesn't exist, it creates the directory.

#### Finding consensus.fasta Files:

- Uses the find command to locate all consensus.fasta files within the specified directory (parentDir) and its subdirectories (up to a depth of 5).

#### File Copy and Renaming Loop

- Iterates over each found consensus.fasta file path
- Processes the path to extract relevant information, including the barcode and medaka number
- Copies the file to the output directory with a new name that includes the barcode and medaka number

---
---

## Dvex_stagDvex04_FastaheaderRename.sh

This script is intended to be the next stage after the execution of "Dvex03_copyConsensus.sh." The main purpose of this script is to rename the header lines of selected FASTA files by incorporating relevant data, specifically adding barcode and medaka information to each header.

### Usage

The script expects one command-line argument, the parentDir ($1) path, which should include the "Consensus_Collation" folder.

```bash
parentDir="/home/wordenp/projects/sangopore_project/analyses/Sangopore_Dvex_2-11-23/barcodes1-13_2-11-23/Consensus_Collation"
bash Dvex_stagDvex04_FastaheaderRename.sh $parentDir
```

#### File Path Retrieval:

Utilizes the find command to retrieve full paths to FASTA files within the specified parent directory.

- Excludes files with names containing "_sp*" in the path.
- Selects files with names containing "code.fasta" in the path.

#### File Processing Loop:

Iterates through each identified FASTA file.

- Checks if the file exists; if not, an error is reported, and the script exits.
- Reads the first line of the file to determine if it starts with ">" (indicating a FASTA header).

#### Header Renaming Logic

If a FASTA header exists, it continues processing.

- Extracts the original header line, excluding the ">" symbol.
- Extracts information such as the file path, filename, and filename without extension
- Creates a new header line incorporating the filename.
- Changes the header in the file to reflect the new information, creating a new file with an extended name (appending "_newHeader.fasta").

#### Error Handling

If a FASTA file does not have a header, it skips to the next file.
Note

- The script appends "_newHeader.fasta" to the original filename for the modified FASTA files.
- Original header lines are retained in the modified files

---
---

## Dvex005_0_blast_remote_batchWrapper.sh

## Script Overview

This Bash script is designed to perform a BLAST (Basic Local Alignment Search Tool) analysis against the `nt` (nucleotide) database. The script automates the process for multiple barcode sequences, organizing the results into folders corresponding to each barcode.

## Script Structure

### User Input Section

The script begins with a user input section where key parameters are defined. Users can customize these parameters according to their specific requirements:

- `parentDirForBlastInput`: The parent directory containing all blast output folders.
- `blast_remote_ScriptPath`: Path to the script (`Dvex005_1_blast_remote.sh`) responsible for remote execution of BLAST.
- `blastDbPath`: Path to the `nt` database for BLAST.
- `targetSuffix`: Suffix used to identify the target files for BLAST analysis (e.g., "_newHeader.fasta").

### BLAST Analysis Section

The script then proceeds to perform the following steps:

1. **Collect Input Files:**
   - It identifies all files with the specified `targetSuffix` within the `parentDirForBlastInput` directory.

```bash
inputConsensusPaths=( $( find $parentDirForBlastInput -maxdepth 2 -type f -name "*"$targetSuffix ) )
```

### Iterate Over Input Files

The following scrit iterates through the identified input files and executes the blast_remote_ScriptPath script for each file.

```bash
for inputFastaConsensus in ${inputConsensusPaths[@]}; do \
    bash $blast_remote_ScriptPath $inputFastaConsensus $blastDbPath
    echo ${inputFastaConsensus}; \
done
```

Inside the loop, the blast_remote_ScriptPath script is invoked with the current input file and the specified blastDbPath.

The script then prints the path of the processed input file.
The script assumes that the BLAST remote execution script (Dvex005_1_blast_remote.sh) is correctly configured and available at the specified path.

Users should ensure that the nt database for BLAST (blastDbPath) is up-to-date and accessible.

This script provides a basic framework for automating BLAST analysis for multiple barcode sequences, and users may need to adapt it based on their specific use case and directory structure.

## ADDITIONAL - Dvex005_1_blast_remote.sh --->

## BLAST Analysis Script

This Bash script performs a BLAST (Basic Local Alignment Search Tool) analysis using the `blastn` command. It assumes the environment is managed using Conda and activates the 'blast' Conda environment before execution.

## Script Overview

### Activation of Conda Environment

The script starts by sourcing the Conda environment configuration and activating the 'blast' environment:

```bash
source /home/wordenp/mambaforge/etc/profile.d/conda.sh # Path to conda
conda activate blast
```

Input Validation
The script then checks if the specified query input file ($1) exists

queryInput="\$1"
blastDbPath="\$2"

if [ -f "\$queryInput" ]; then

Output Path Setup
If the query input file exists, the script extracts information about the file and sets up the output directory path:

```bash
parentInputPath=${queryInput%/*}
outputFileName=${queryInput##*/}
outputFileBase=${outputFileName%.*}

blastOutPath=$parentInputPath/"blast_"$outputFileBase
```

If the specified output directory does not exist, it creates the directory:

```bash
if [ -e $blastOutPath ]; then echo "Folder exists!"; else mkdir $blastOutPath; echo "Creating folder: $blastOutPath"; fi
```

BLAST Execution
The script then moves to the output directory and performs two BLAST queries:

Tabular Format:
Executes blastn with specific output format options, producing a tab-separated values (TSV) file:

```bash
blastn -db $blastDbPath -query $queryInput -outfmt "6 qseqid sseqid qcovs qlen pident length mismatch gapopen qstart qend sstart send evalue bitscore staxids stitle qseq sseq" \
-max_target_seqs 10 -max_hsps 3 -evalue 1e-05  -num_threads 32 -out $blastOutPath/$outputFileBase"blastn.tsv"
  ```

```bash
blastn -db $blastDbPath -query $queryInput -outfmt "5" -max_target_seqs 20 -max_hsps 20 -evalue 1e-05  -num_threads 32 -out $blastOutPath/$outputFileBase'_blastn.xml'
```

---
---

## Dvex006_1_blastTableOrganise.R - R Script Summary

## `refineBlastnTSV` Function

The script defines a function, `refineBlastnTSV`, which takes a path to a blastn output TSV file as input. The function reads the TSV file, reorders its rows based on bit score and query coverage, refines the "Subject_Seq_id" column, removes unnecessary characters, and saves the refined table as a CSV file. The function returns the refined blast table.

## Main Script Flow

1. The script parses command-line arguments to get the parent directory path.
2. It lists blastn output files recursively in the specified directory.
3. It iterates over the blastn output files, applying the `refineBlastnTSV` function. Errors during processing are caught and reported.
4. It creates a summary directory for saving refined blast tables.
5. It combines all ordered CSV files into a single CSV file named "blastAllOutput.csv."
6. It creates a summary table with selected columns from the ordered CSV files and saves it as "blastSummary.csv."

## Bioinformatics Analysis

1. The script uses the Biostrings and DECIPHER packages.
2. It performs pairwise sequence alignments for each entry in the summary table.
3. It creates directories for each alignment and saves alignment files.
4. It generates HTML files for visualizing the alignments.

Note: The script assumes specific file naming conventions for input blastn files and generates output files accordingly.

## ADDITIONAL --->

# R Script Overview and Detailed Summary

## Purpose
The following R script performs post-processing on blastn output files, specifically in the context of bioinformatics analysis. It includes functions for refining and ordering blast results, as well as generating summary tables and visualizations for sequence alignments.

## Functions

### `refineBlastnTSV` Function

#### Input
- Path to a blastn output TSV file.

#### Steps
1. Reads the TSV file into a data frame.
2. Defines column names based on blastn output format.
3. Orders the table based on bit score and query coverage.
4. Refines the "Subject_Seq_id" column, keeping only gene identifiers.
5. Saves the refined table as a CSV file.
6. Returns the refined blast table.

## Main Script Flow

### 1. Command-Line Argument Parsing
- The script uses the commandArgs function to parse command-line arguments.
- It extracts the parent directory path from the arguments.

### 2. Blastn Output File Processing
- Recursively lists blastn output files in the specified directory.
- Iterates over the list and applies the `refineBlastnTSV` function to each file.
- Catches and reports errors during file processing.

### 3. Summary Output Generation
- Creates a summary directory for saving refined blast tables.
- Combines all ordered CSV files into a single CSV file named "blastAllOutput.csv."
- Creates a summary table with selected columns from the ordered CSV files.
- Saves the summary table as "blastSummary.csv."

## Bioinformatics Analysis

### 1. Required Packages
- The script loads the Biostrings and DECIPHER packages, indicating a focus on sequence analysis.

### 2. Pairwise Sequence Alignments
- Iterates over entries in the summary table.
- Performs pairwise sequence alignments for each entry.
- Creates directories for each alignment and saves alignment files.

### 3. Visualization
- Generates HTML files for visualizing sequence alignments.
- Uses functions from the Biostrings and DECIPHER packages for sequence manipulation and alignment.

## Assumptions
- The script assumes specific file naming conventions for input blastn files and generates output files accordingly.
- It assumes that the blastn output files are in TSV format.

## Conclusion
This script streamlines the post-processing of blastn results, providing refined tables and visualizations for further bioinformatics analysis.

---
---

## Dvex006_1_blastTableOrganise.R

### Function Definition: refineBlastnTSV

Defines a function refineBlastnTSV that takes a path to a blastn output TSV file as input, refines the data, and returns the refined data frame. The refinement includes sorting based on bit score and query coverage, modifying column names, and saving the results as a CSV file.

```R
refineBlastnTSV <- function(inputPath) {
# ... (function implementation)
return(completeBlastTable)
}
```

### Reading Input Paths and Processing Files

Reads the parent directory path from command line arguments, lists files recursively with a specific pattern, and iteratively applies the refineBlastnTSV function to each file, handling errors with tryCatch.

```R
parentConsensusDir = args[1]

fileList = list.files(path = parentConsensusDir, pattern = "_newHeaderblastn.tsv$", recursive = TRUE, full.names = TRUE)

for (i in 1:length(fileList)) {
  tryCatch({
    refinedBlastnOneResult = refineBlastnTSV(fileList[i])
  }, error = function(e) {
    cat("Error processing file:", fileList[i], "\n")
    cat("Error message:", e$message, "\n")
  })
}
```

### Creating a Summary Directory

Creates a directory for storing summary files if it doesn't exist.

```R
outSummParentDir = paste0(parentConsensusDir, "/", "blastSummaryFiles")

if (!dir.exists(outSummParentDir)){
  dir.create(outSummParentDir)
}else{
  print("dir exists")
}
```

### Aggregating and Writing Summary Data

Aggregates and writes summary data from ordered CSV files into two separate CSV files (blastAllOutput.csv and blastSummary.csv).

```R
# Full output minus the query and subject sequences
# ... (omitted for brevity)

# Summary output 
# ... (omitted for brevity)
```

### Creating DNA Sequence Alignments

Iterates over the summary data and creates DNA sequence alignments using the pairwiseAlignment function from the Biostrings package. It then saves the alignments in different formats and generates HTML files to visualize the alignments using the BrowseSeqs function.

```R
# ... (omitted for brevity)
```

## Summary

This script is designed for processing blastn output TSV files, refining the data, creating summaries, and visualizing sequence alignments.
