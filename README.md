# 16SrRNA_taxonomy
A repository to store the code required to perform an ordered taxonomic adjustment on NCBI 16S rRNA sequences.


## Rationale

The insect microbiome is a relatively new area of research, with new taxa being identified regularly, thus making existing databases used in 16S rRNA metabarcoding analyses, such as RDP and Greengenes, taxonomically out of date.  Previous work had indicated that incorrectly assigned taxa were identified by BLASTing 16S rRNA sequences that were expected to be present in the insect microbiome.  As the NCBI 16S rRNA database is a more current source of information, this dataset was used as a source to make a new [QIIME2](https://qiime2.org/) compatible dataset, that could be classified for use within that environment.

In addition, bacterial taxonomy contains a number of intermediate taxonomic levels (e.g. suborders), which can complicate taxonomic analyses in tools such as QIIME2 wherein the taxonomy becomes an array, and is split on certain delimiters (e.g. "__", or ";"), as described below.  This situation is more complex for eukaryotes, but the work described here refers to bacteria and archaea, and the parsing code is only applicable to these domains only.


## Principle

### The NCBI Taxonomic Database

The [NCBI Taxonomy](https://www.ncbi.nlm.nih.gov/taxonomy) page lists the taxonomy for known organisms.  For a given organism, there is a Full and an Abbreviated version.  For example, for *Gemmata obscuriglobus* (NCBI:txid114):

 * Lineage (full):
    * cellular organisms; Bacteria; PVC group; Planctomycetes; Planctomycetia; Planctomycetales; Gemmataceae; Gemmata; Gemmata obscuriglobus
 * Lineage (abbreviated): 
    * Bacteria; Planctomycetes; Planctomycetia; Planctomycetales; Gemmataceae; Gemmata; Gemmata obscuriglobus

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

Going back to our exmpmle of *Gemmata obscuriglobus*, it is a member of the Planctomycetes phylum, but with the full NCBI taxonomy, it is also a member of the PVC group (between the levels of kingdom and phylum), which therefore offsets all subsequent taxonomic assignments by one. In an automated way, this offset causes problems in subsequent analyses.


## Preparation of a custom 16S rRNA BLAST database

### Required dependencies

The Perl script described here has the following dependencies:

```
BioPerl - specifically Bio::Seq Bio::SeqIO
Perl modules DBI and DBD::MySQL
A MySQL or equivalent database
```

### Input files



### Perl script

A Perl script was written (XXXXXX) updated the NCBI taxonomy to parse the output so that suborders and tribes were removed. Three steps of analyses were required: 
  * simple taxonomy, where names were correctly classified;
  * complex taxonomy, where a specific taxonomic name needed to be removed;
  * names including the word "Group". 
  
The initial step resets the group naming issue for L3, and L6 - L9. This was conducted one at a time as some ‘groups’ changed their location as they were moved back through the taxonomy.

### Procedure


