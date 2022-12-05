# New microbiological insights from the Bowland shale highlight heterogeneity of the hydraulically fractured shale microbiome 
# Workflow for meta-analysis
# Input: sequences downloaded from NCBI
# Download the SRR Acc list from run selector with the accession number
# Change directory to /SRAtoolkit/bin
# Copy SSR Acc list to bin

./prefetch --option-file SRR_Acc_List.txt

./fasterq-dump --split-files SRR

#Make the manifest file in google sheets and validate with Keemei. Save as sequences.tsv

# Activate QIIME2

conda activate qiime2-2021.4

# IMPORT SEQUENCES

#Paired end Illumina

qiime tools import --type 'SampleData[PairedEndSequencesWithQuality]' --input-path sequences.tsv --output-path sequences.qza --input-format PairedEndFastqManifestPhred33V2

# TRIM V4 primers

qiime cutadapt trim-single --i-demultiplexed-sequences sequences.qza --p-adapter ATTAGAWACCCBDGTAGTCC --p-front GTGCCAGCMGCCGCGGTAA --p-cores 1 --p-discard-untrimmed --o-trimmed-sequences trimmed-sequences.qza --verbose --p-match-read-wildcards

#DENOISE with DADA2
# Adjust --p-trunc len based on the quality breaking point. Since primers have been removed --p-trim are set at 0

qiime dada2 denoise-single --i-demultiplexed-seqs sequences.qza --p-trim-left 0 --p-trunc-len 120 --o-representative-sequences rep-seqs.qza --o-table table.qza --o-denoising-stats stats-dada.qza

#All the data sets have to be denoised individually (edit the output names to the reference data set i.e antrim-table.qza) and then they will be merged using the following step.
#MERGING STEP

qiime feature-table merge --i-tables antrim-table.qza --i-tables bakken-table.qza --i-tables bowland1-table.qza --i-tables bowland2-table.qza --i-tables duvernay-table.qza --i-tables marcellus-table.qza --i-tables niobrara-table.qza --i-tables sichuan2017-table.qza --i-tables sichuan2020-table.qza --o-merged-table shale-table.qza

qiime feature-table merge-seqs --i-data antrim-rep-seqs.qza --i-data bakken-rep-seqs.qza --i-data bowland1-rep-seqs.qza --i-data bowland2-rep-seqs.qza --i-data duvernay-rep-seqs.qza --i-data marcellus-rep-seqs.qza --i-data niobrara-rep-seqs.qza --i-data sichuan2017-rep-seqs.qza --i-data sichuan2020-rep-seqs.qza --o-merged-data shale-rep-seqs.qza

#INSERTION TREE
qiime fragment-insertion sepp --i-representative-sequences shale-rep-seqs.qza --i-reference-database sepp-refs-silva-128.qza  --p-threads 4 --o-tree insertion-tree.qza --o-placements insertion-placements.qza

qiime fragment-insertion filter-features --i-table final-shale-table.qza --i-tree insertion-tree.qza --o-filtered-table filtered_table.qza --o-removed-table removed_table.qza

qiime feature-table filter-seqs --i-data final-shale-rep-seqs.qza --i-table filtered_table.qza --o-filtered-data shale-filtered-rep 


# TAXONOMIC ASSIGNATION

qiime feature-classifier classify-sklearn --i-classifier silva-138-99-nb-classifier.qza --i-reads shale-rep-seqs.qza --o-classification taxonomy.qza

#DONE
