#!/bin/sh

## the NCBI files

cat 16S_id_to_taxModDone.map | awk -F '[;\t]' '{print $1 "\t" "k__" $2 ";p__" $3 ";c__" $4 ";o__" $5 ";f__" $6 ";g__" $7 ";s__" $8 ";ss__" $9 }' > working2019.map

cat 16SMicrobial.fasta > working2019.fasta


## code correct for the QIIME2 2019.1 version

qiime tools import --input-path working2019.fasta --output-path workingSeqs2019.qza --type 'FeatureData[Sequence]'

qiime tools import --type 'FeatureData[Taxonomy]' --input-format HeaderlessTSVTaxonomyFormat --input-path working2019.map --output-path workingTaxonomy2019.qza
  
qiime feature-classifier extract-reads --i-sequences workingSeqs2019.qza --p-f-primer CCTACGGGAGGCAGCAG --p-r-primer GGACTACHVGGGTWTCTAAT --o-reads workingSeqsExtracted2019.qza
  
qiime feature-classifier fit-classifier-naive-bayes --i-reference-reads workingSeqsExtracted2019.qza --i-reference-taxonomy workingTaxonomy2019.qza --o-classifier workingClassifier.qza
  
