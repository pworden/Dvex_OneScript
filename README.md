
# Sangopore project

---

## Workflow Summary - ***Dvex000_001_runWrap.sh***

The ***Dvex000_001_runWrap.sh*** script takes as inputs one or more barcoded (or unbarcoded) reads from Minion or Gridion (ONT) sequencers, as well as a table of metadata, and uses that information to run ***NGSpeciesID*** which clusters similar reads from each barcode together and finds a consensus from each cluster. Other scripts including one directing blast searchs then correlates infomration so the user can identify species with the closest identity to each consensus.

* See the following site for more detail on all scripts: <https://github.com/pworden/Dvex_Scripts>

---

## Set up necessary conda environments

The scripts used in the workflow called by the wrapper script Dvex000_001_runWrap.sh will need to have the following conda environments installed (and named exactly as noted here), as well as the packages described below.

### 1. Conda Environment: ***NGSpecieID***

Install the *NGSpecieID* conda environment as described here:
<https://github.com/ksahlin/NGSpeciesID>

* Settings for the NGSpeciesID script have been defined in the initial user table.

### 2. Conda Environment: ***Blast***

Set up a conda environment to run blast searches. The set of scripts described here uses a "blastn" search.

```bash
# Create the conda environment
conda create --name blast
# Activate the blast conda environment
conda activate blast
# Install the "blast" conda package
conda install -c bioconda blast
```

### 3. Conda Environment: ***r-base***

Set up a conda environment to run R scripts

```R
# Create the conda environment
conda create --name r-base
# Activate the r-base conda environment
conda activate r-base
# Install a number of base R packages
conda install -c conda-forge r-base
```

#### ***Biostrings*** R package

The Biostrings R packages will also be required for a number of R scripts to work. It can be installed into the R conda environment that you are using to run R code (r-base).
<https://anaconda.org/bioconda/bioconductor-biostrings>

**Biostrings** can be installed within the ***r-base*** conda environment by activating this environment, starting R on the server (type "R" and then enter), and then paste in the code in the grey window below and press enter to run. This loads in the BiocManager which then installs "Biostrings".

```R
if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

BiocManager::install("Biostrings")
```

#### ***DECIPHER*** R Package

The "DECIPHER" R package is also required. It should be installed into the ***r-base*** conda environment that you are using to run R code.
<https://anaconda.org/bioconda/bioconductor-decipher>

**DECIPHER** can also be installed within the R environment by starting R on the server (type "R" and then enter) and then paste in the code in the grey window below and press enter to run. This loads in the Biodoc manager which then installs "DECIPHER".

```R
if (!require("BiocManager", quietly = TRUE))
  install.packages("DECIPHER")

BiocManager::install("DECIPHER")
```

---

# Individual script summaries

---

## Dvex000_setupUsingtable.R

This R-script is designed to take a table in TSV format and use the data in this table (including paths to files and folders) to calculate the number of analyses needed and for each analysis output needed files or folders. For example there will be one primer (fasta) file for each analysis, and parent analysis folder.

### Requirements - *Dvex000_setupUsingtable.R*

The "Biostrings" package is required for this script it should have been installed into the r-base environment as described in the summary section above.

### User Input - *Dvex000_setupUsingtable.R*

The script retrieves user input from command-line arguments. It expects two arguments.

1. The path to the tab-delimited input file (tableInputPath)
2. The parent output path (parentOutputPath).

These arguments can be either via the command line, or within the Dvex000_001_runWrap.sh script that performs the full workflow.

```R
# Paths set in wrapper script (Dvex000_001_runWrap.sh) that calls this script. For example:
R_scriptPath000="/path/to/RScript/Dvex000_setupUsingtable.R"
tableInputPath="/path/to/dataTable/Run_metadata_template.txt"
parentOutputPath="/path/to/parent/output/directory"

# To run the script (Dvex000_setupUsingtable.R) via the command line add the correct -
# paths to the files and the outputdirectory.
# Then type the following and press enter to run.
Rscript $R_scriptPath000 $tableInputPath $parentOutputPath
```

#### For more details on Dvex000_setupUsingtable.R

<https://github.com/pworden/Dvex_OneScript/blob/main/Sangopore_FullWorkflow.md>

---

## Dvex001_concatFastq.R

This R script finds a common string within a single folder of fastq files. Each folder represents a single barcode output. All fastq files within a single directory (barcode) is then concatenated into one fastq file, renamed to a common string and copied to a newly created output directory.

### Requirements - *Dvex001_concatFastq.R*

* No requirements. This Rscript only uses base R.

### User Input - *Dvex001_concatFastq.R*

The script expects two arguments.

1. To the file pathsToAnalyses.txt generated from the previous R-script (Dvex000_setupUsingtable.R)
   * that holds the paths to each parent analysis folder.
1. The second to the parent output folder.

```bash
# $parentOutputPath (path variable) used in this "Dvex001_concatFastq.R" script is from previous section
    # It will need to be declared if running this script outside of the workflow
    # i.e. parentOutputPath="/path/to/parent/output/directory"
inputAnalysesDirsFile=$parentOutputPath"/pathsToAnalyses.txt"
R_scriptPath001="/home/wordenp/Scripts/General_Scripts/Dvex_workflow_dev/Dvex001_concatFastq.R"
Rscript $R_scriptPath001 $inputAnalysesDirsFile $parentOutputPath
```

### Functions - *Dvex001_concatFastq.R*

1. **find_common_string**
   * Finds a common string from a set of FASTQ file names.
   * Assigns a basic string if no common string is found.

2. **readTableUnzipFastq**
   * Concatenates FASTQ files into one name for each barcode directory
   * Reads a sample table from each analysis directory.
   * Creates output directories and copies all concatenated fastq.gz files for each barcode into a single fastq file directory.
   * Fastq.gz files are unzipped
   * Writes an updated sample table to an output file.

#### For more details on Dvex001_concatFastq.R

<[https://github.com/pworden/Dvex_Scripts#readme](https://github.com/pworden/Dvex_OneScript/blob/main/Sangopore_FullWorkflow.md)>

---

## Dvex002_NGSpeciesNT.sh

1. Gathers data from TSV files with the prefix "_sp_extra.tsv," which contain inputs needed by NGSpeciesID.
   * Inputs include parameters such as espected amplicon length and number of threads, etc.
1. Performs analysis using NGSpeciesID on the gathered data using options for ONT (Oxford Nanopore Technologies).
1. Activates the NGSpeciesID conda environment.
1. Iterates through each TSV file, extracts relevant information, and performs NGSpeciesID analysis for each barcode.
   * Extracted information includes sequence length, variation, barcode, and corresponding FASTQ file paths.
   * NGSpeciesID is executed with specified parameters, including consensus, medaka, and primer file options.
   * The script assumes a specific structure of input TSV files and "_sp.fasta" primer files as ouput from the previous R-script.
1. Results are stored in output directories named after each barcode.

### Requirements - *Dvex002_NGSpeciesNT.sh*

Install the *NGSpecieID* conda environment as described in the summary section above. The settings for the NGSpeciesID script have been defined in the initial user table.

### User input - *Dvex002_NGSpeciesNT.sh*

```bash
bashScript_NGSpeciesNT_002="/path/to/script/Dvex002_NGSpeciesNT.sh"
# $parentOutputPath previously defined in wrapper script (see above)
bash $bashScript_NGSpeciesNT_002 $parentOutputPath
```

#### For more details on Dvex002_NGSpeciesNT.sh

<[https://github.com/pworden/Dvex_Scripts/blob/main/README.md](https://github.com/pworden/Dvex_OneScript/blob/main/Sangopore_FullWorkflow.md)>

---

## Dvex003_copyConsensus.sh

This script copies all the consensus.fasta files (sometimes more than one per barcode)
that were output from the previous script (Dvex02_NGSpeciesNT.sh) into a single directory.
Each copied file is also renamed with a name that includes its barcode
(from two directories up) and its medaka cluster number (from one directory up).

### User Input - *Dvex003_copyConsensus.sh*

```bash
Dvex03_copyConsensusScript="/path/to/script/Dvex003_copyConsensus.sh"
# This variable has been set previously: outDirName="Consensus_Collation"
# This 2nd variable has been set previously, above
# Run with the following command
bash $Dvex03_copyConsensusScript $parentDir $outDirName
```

#### For more details on Dvex003_copyConsensus.sh

<[https://github.com/pworden/Dvex_Scripts/blob/main/README.md](https://github.com/pworden/Dvex_OneScript/blob/main/Sangopore_FullWorkflow.md)>

---

## Dvex004_FastaheaderRename.sh

This script finds all the fasta files under the newly created directory holding all consensus fasta files that have been copied into the new directory and each fasta file renamed. It then:

1. Renames the header of each sequence within a fasta file
   * Adds barcode and medaka cluster information to the header.
   * Retains old header text (adding a space and moving the old text to the right)
      * The old header text is retained as it holds useful data, including the number of reads used to generate a consensus
   * The fasta file with a new header is then renamed *oldfilename*_newHeader.fasta and saved

### User input *Dvex003_copyConsensus.sh*

```bash
Dvex004_FastaheaderRename="/path/to/script/Dvex004_FastaheaderRename.sh"
parentDir="/path/to/output/Consensus_Collation"
bash $Dvex004_FastaheaderRename $parentDir
```

#### For more details on Dvex004_FastaheaderRename.sh

<[https://github.com/pworden/Dvex_Scripts/blob/main/README.md](https://github.com/pworden/Dvex_OneScript/blob/main/Sangopore_FullWorkflow.md)>

---

## Dvex005_1_blast_remote.sh

This script looks for all *oldfilename*_newHeader.fasta files within the "Consensus_Collation" directory for each NGSpeciesID analysis and then performs a blastn and a blastx search on the  consensus sequences within each fasta input. Outputs are TVS and XML.

### User Input - *Dvex005_1_blast_remote.sh*

The variables from above $blastOutPath and $outputFileBase are determined in script from the two inputs lited below ($queryInput and $blastDbPath)

```bash
queryInput=/path/to/parentDir/Consensus_Collation/barcodes49-50_1set_barcode49_medaka_cl_id_7_newHeader.fasta
blastDbPath="/home/wordenp/databases/blast_dbs/nt/nt"
```

#### Commands used for each single blastn and balstx search

```bash
# blastn
blastn -db $blastDbPath -query $queryInput -outfmt "6 qseqid sseqid qcovs qlen pident length mismatch gapopen qstart qend sstart send evalue bitscore staxids stitle qseq sseq" \
-max_target_seqs 10 -max_hsps 3 -evalue 1e-05  -num_threads 32 -out $blastOutPath/$outputFileBase"blastn.tsv"

#blastx
blastn -db $blastDbPath -query $queryInput -outfmt "5" -max_target_seqs 20 -max_hsps 20 -evalue 1e-05  -num_threads 32 -out $blastOutPath/$outputFileBase'_blastn.xml'
```

#### For more details on Dvex005_1_blast_remote.sh

<[https://github.com/pworden/Dvex_Scripts/blob/main/README.md](https://github.com/pworden/Dvex_OneScript/blob/main/Sangopore_FullWorkflow.md)>

---

## Dvex006_1_blastTableOrganise.R

The Dvex006_1_blastTableOrganise.R script processes BLASTN output in TSV format, refines the data, and generates summary files.

### R script requirements - *Dvex006_1_blastTableOrganise.R*

* This script (Dvex006_1_blastTableOrganise.R) requires "biostrings" but that should have been previously installed into your R environment from before (see above).
* The "DECIPHER" package is required. It can be installed into the R conda environment that you are using to run R code.
<https://anaconda.org/bioconda/bioconductor-decipher>

Or "DECIPHER" can be installed within the R environment by starting the R on the server (type "R" and then enter) and then paste in the code in the grey window below. This loads in the Biodoc manager which then installs "DECIPHER".

```R
if (!require("BiocManager", quietly = TRUE))
  install.packages("DECIPHER")

BiocManager::install("DECIPHER")
```

This script (Dvex006_1_blastTableOrganise.R) also requires biostrings but that should have been previously installed into your R environment from before (see above).

### Summary - Dvex006_1_blastTableOrganise.R

1. This script collects the directory path of each TSV output (..."_newHeaderblastn.tsv") from the previous script (Dvex005_1_blast_remote.sh).
1. Applies the `refineBlastnTSV` function to each file (..."_newHeaderblastn.tsv"), which does the following:
    * Gets each TSV path.
    * Reads the TSV file, assigns headers, and orders the the table (from the previous script) based on bit score and query coverage.
    * Refines the "Subject_Seq_id" column of the table to keep only gene identifiers.
    * Removes unnecessary characters from certain columns.
    * Saves the refined data as a CSV file.
    * Returns the refined data frame for later manipulations.
1. Creates a directory for storing summary files.
1. Combines all ordered CSV files into a single file named "blastAllOutput.csv."
1. Creates a summary table from selected columns and saves it as "blastSummary.csv."
   * With only one of blast results per analysis
1. Utilizes the Biostrings and DECIPHER packages to process DNA sequences.
1. Creates pairwise alignments.
1. Outputs alignments for visualization in the form of:
   * HTML files
     * The top row of sequences (labelled "1" for HTML output) is the query sequence
     * The lower row of sequences (labelled "2" for HTML output) is the subject sequence
   * Alignment files in text format

#### For more details on Dvex006_1_blastTableOrganise.R

<[https://github.com/pworden/Dvex_Scripts/blob/main/README.md](https://github.com/pworden/Dvex_OneScript/blob/main/Sangopore_FullWorkflow.md)https://github.com/pworden/Dvex_OneScript/blob/main/Sangopore_FullWorkflow.md>
