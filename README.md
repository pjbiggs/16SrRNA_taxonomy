# 16SrRNA_taxonomy
A repository to store the code required to perform an ordered taxonomic adjustment on NCBI 16S rRNA sequences.


## Introduction

The work described here has come from the analysis of the honey bee microbiome which is a part of Michelle Taylor's ongoing PhD.  Michelle is a scientist based at [The New Zealand Institute for Plant and Food Research Limited](https://www.plantandfood.co.nz/), Hamilton, New Zealand.


## Rationale

The honey bee microbiome is a relatively new area of research, with new bacterial strains being identified and reclassified frequently. Previous work indicated that incorrectly assigned taxa were correctly identified by BLASTing 16S rRNA sequences that were expected to be present in the honey bee microbiome. To ensure honey bee classifications were current, the 16S rRNA BLAST (Basic Local Alignment Search Tool) database was downloaded from National Center for Biotechnology Information (NCBI) at (ftp://ftp.ncbi.nlm.nih.gov/blast/db/) and customised to make a [QIIME2](https://qiime2.org/) compatible reference dataset.

In addition, bacterial taxonomy contains a number of intermediate taxonomic levels (e.g. suborders), which can complicate taxonomic analyses in tools such as QIIME2 wherein the taxonomy becomes an array, and is split on certain delimiters (e.g. "__", or ";"), as described below.  This situation is more complex for eukaryotes, but the parsing code described here refers to bacteria and archaea, and is only applicable to these domains.


## Principle

### The NCBI Taxonomic Database

The [NCBI Taxonomy](https://www.ncbi.nlm.nih.gov/taxonomy) page lists the taxonomy for known organisms.  For a given organism, there is a Full and an Abbreviated version.  For example, for *Lactobacllus mellifer* (NCBI:txid1218492):

Lineage (full)
    cellular organisms; Bacteria; Terrabacteria group; Firmicutes; Bacilli; Lactobacillales; Lactobacillaceae; Lactobacillus; Lactobacillus mellifer 
Lineage (abbreviated)
    Bacteria; Firmicutes; Bacilli; Lactobacillales; Lactobacillaceae; Lactobacillus; Lactobacillus mellifer

We presume the following taxonomic ranks:

   * L1: domain/kingdom
   * L2: phylum
   * L3: class
   * L4: order
   * L5: family
   * L6: genus
   * L7: species 
   
The goal therefore is to optimise the number of members in any taxonomic sequence database that have within their full taxonomic classification names that end in "*-ales*" for the taxonomic level of order (L4), and "*-ceae*" for the taxonomc order of family (L5).  In other words, there is the requirement to convert the Full taxonomy to an Abbreviated version for use in tools such as QIIME2.

### Intermediate taxonomic classifications

Going back to our example of *Lactobacllus mellifer*, it is a member of the Firmicutes phylum, but with the full NCBI taxonomy, it is also a member of the Terrabacteria group (between the levels of kingdom and phylum), which therefore offsets all subsequent taxonomic assignments by one. In an automated way, this offset causes problems in subsequent analyses.


## Preparation of a custom 16S rRNA BLAST database

### Required dependencies

The Perl script described here has the following dependencies:

```
BioPerl: specifically Bio::Seq Bio::SeqIO
Perl modules: DBI and DBD::MySQL
A MySQL database
```

### Retrieve data from NCBI and parse

1. Download the file `16SMicrobial.tar.gz` from the NCBI FTP BLAST database site (ftp://ftp.ncbi.nlm.nih.gov/blast/db/), and uncompress it.
2. Convert it back to a fasta format file using the BLAST+ tool `blastdbcmd`.  This results in a file called `16SMicrobial.fasta`.
3. Execute the shell script `id_to_tax_mapmaker.sh` (the instructions for which can be found at the [QIIME_utilities](https://github.com/mtruglio/QIIME_utilities) page) that generates a taxonomic file ("16S_id_to_tax.map"), linking the GenBank GI accession IDs to the headers in the fasta filed.  This script downloads files from the NCBI taxonomy server and matches the GI accession number in the fasta file with the taxonomy description.  This process resulted in a pair of files each with 18,773 entries present (as of August 2018).


### Perl script for taxonomy parsing on the mapping file

The input mapping file is defined as being of two columns, the first being the GI accession ID, and the second being the taxonomy.  The data structure of the NCBI taxonomy was a character string delimited by semicolons, and it was this string that is parsed using the Perl script (`NCBI_16StaxaParse.pl`) and stored in a MySQL database.

The taxonomy string was split into an array, which for the reason described above had a variable number of elements.  The split array was loaded into a table within MySQL and the taxonomy was analysed at the L2 level.  Archaea were analysed first, and then bacteria.  Whilst these subsets were manually inspected initally to work out the taxonomic situation (by name), the building of a new taxonomic table was done by writing a Perl/MySQL script that would process the taxonomy if necessary and move the curated data from that subset into a new table.

The Perl script (`NCBI_16StaxaParse.pl`) updates the downloaded NCBI taxonomy to parse the output so that suborders and tribes were removed. Three steps of analyses were required: 
  * simple taxonomy, where names were correctly classified;
  * complex taxonomy, where a specific taxonomic name needed to be removed;
  * names including the word "Group". 
 
 With the data as analysed, the simple taxonomy phyla to process were:

| Domain   | Phylum                          | number   |
|----------|---------------------------------|---------:|
| Archaea  | DPANN_group                     |        1 |
| Archaea  | Euryarchaeota                   |      800 |
| Bacteria | Acidobacteria                   |       39 |
| Bacteria | Aquificae                       |       44 |
| Bacteria | Caldiserica                     |        3 |
| Bacteria | Chrysiogenetes                  |        6 |
| Bacteria | Deferribacteres                 |       14 |
| Bacteria | Dictyoglomi                     |        5 |
| Bacteria | Elusimicrobia                   |        3 |
| Bacteria | Fusobacteria                    |       75 |
| Bacteria | Nitrospirae                     |       13 |
| Bacteria | Spirochaetes                    |      160 |
| Bacteria | Synergistetes                   |       34 |
| Bacteria | Thermodesulfobacteria           |       13 |
| Bacteria | Thermotogae                     |       70 |
| Bacteria | unclassified_Bacteria           |        7 |
 
With the data as analysed, the more complex taxonomy phyla to process were:
	
| Domain   | Phylum                          | number   |
|----------|---------------------------------|---------:|
| Archaea  | TACK_group                      |      120 |
| Bacteria | FCB_group                       |     1713 |
| Bacteria | Nitrospinae/Tectomicrobia_group |        1 |
| Bacteria | Proteobacteria                  |     6826 |
| Bacteria | PVC_group                       |      132 |
| Bacteria | Terrabacteria_group             |     8694 | 
 
For working with taxonomic names with the word "group" in them, the process was slightly more complicated.  The initial step resets the group naming issue for L3, and L6 - L9. This was conducted one at a time as some ‘groups’ changed their location as they were moved back through the taxonomy.  Overall, this process involved two rounds of analysis as there were examples of taxonomic names with the word "group" in them twice.  


### Downstream use in QIIME2

The updated taxonomy file `16S_id_to_taxModDone.map` and the fasta file `16SMicrobial.fasta` are able to be used as per the QIIME2 tutorials for feature classification.  An example of such a process can be found in the script `NCBIclassifier.sh`.
