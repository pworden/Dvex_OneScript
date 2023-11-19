#!/bin/bash

# Change the "Conda" environment
source /home/wordenp/mambaforge/etc/profile.d/conda.sh # Path to conda
# The conda activation is unnecessary as the path is set
	# But it is added for additional packages if needed
conda activate blast

		# # -------------------------------------------------------------------------------- #
		# # --------------------------- USER INPUT - for testing --------------------------- #
		# queryInput=/home/wordenp/Scripts/General_Scripts/Dvex_workflow_dev/oneBarcode/Consensus_Collation/barcodes49-50_1set_barcode49_medaka_cl_id_7_newHeader.fasta
		# blastDbPath="/home/wordenp/databases/blast_dbs/nt/nt"
		# # -------------------------------- End User Input -------------------------------- #
		# # -------------------------------------------------------------------------------- #

# Run this script with arguments:
# bash path/to/script/Dvex005_1_blast_remote.sh "$queryInput" "$blastDbPath"

# Input arguments from command line (example above)
queryInput="$1"
blastDbPath="$2"

# If the query input exists then run a blastn and blastx search
if [ -f "$queryInput" ]; then

	parentInputPath=${queryInput%/*}
	outputFileName=${queryInput##*/}
	outputFileBase=${outputFileName%.*}

	blastOutPath=$parentInputPath/"blast_"$outputFileBase

	if [ -e $blastOutPath ]; then echo "Folder exists!"; else mkdir $blastOutPath; echo "Creating folder: $blastOutPath"; fi

	cd $blastOutPath
	# Tabular TSV output with the following set of data in each column
	blastn -db $blastDbPath -query $queryInput -outfmt "6 qseqid sseqid qcovs qlen pident length mismatch gapopen qstart qend sstart send evalue bitscore staxids stitle qseq sseq" \
	-max_target_seqs 10 -max_hsps 3 -evalue 1e-05 -num_threads 32 -out $blastOutPath/$outputFileBase"blastn.tsv"
	
	# XML result
	blastn -db $blastDbPath -query $queryInput -outfmt "5" -max_target_seqs 10 -max_hsps 3 -evalue 1e-05  -num_threads 32 -out $blastOutPath/$outputFileBase'_blastn.xml'

	conda deactivate

else
	echo "File not found: $queryInput"
fi
