# 16SrRNA_taxonomy
A repository to store the code required to perform an ordered taxonomic adjustment on NCBI 16S rRNA sequences.


## Rationale

The insect microbiome is a relatively new area of research, with new taxa being identified regularly, thus making existing databases used in 16S rRNA metabarcoding analyses, such as RDP and Greengenes, taxonomically out of date.  Previous work had indicated that incorrectly assigned taxa were identified by BLASTing 16S rRNA sequences that were expected to be present in the insect microbiome.  As the NCBI 16S rRNA database is a more current source of information, this dataset was used as a source to make a new [QIIME2](https://qiime2.org/) compatible dataset, that could be classified for use within that environment.

In addition, bacterial taxonomy contains a large number of intermiediate taxonomic levels (e.g. suborders), which can complicate taxonomic analyses in tools such as QIIME2 when the taxonomy is split on certain characters (e.g. "__").


## Principle

A Perl script was written (XXXXXX) updated the NCBI taxonomy to parse the output so that suborders and tribes were removed. Three steps of analyses were required: 
  * simple taxonomy, where names were correctly classified;
  * complex taxonomy, where a specific taxonomic name needed to be removed;
  * names including the word "Group". 
  
The initial step resets the group naming issue for L3, and L6 - L9. This was conducted one at a time as some ‘groups’ changed their location as they were moved back through the taxonomy.


## Preparation of a custom 16S rRNA BLAST database
