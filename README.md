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

Going back to our example of *Gemmata obscuriglobus*, it is a member of the Planctomycetes phylum, but with the full NCBI taxonomy, it is also a member of the PVC group (between the levels of kingdom and phylum), which therefore offsets all subsequent taxonomic assignments by one. In an automated way, this offset causes problems in subsequent analyses.


## Preparation of a custom 16S rRNA BLAST database

### Required dependencies

The Perl script described here has the following dependencies:

```
BioPerl: specifically Bio::Seq Bio::SeqIO
Perl modules: DBI and DBD::MySQL
A MySQL database
```

### Retrieve data from NCBI and parse

1. Download the file "16SMicrobial.tar.gz" from the [NCBI FTP BLAST database site](ftp://ftp.ncbi.nlm.nih.gov/blast/db/), and uncompress it.
2. Convert it back to a fasta format file using the BLAST+ tool blastdbcmd.  This results in a files called "16SMicrobial.fasta".
3. Execute the shell script "id_to_tax_mapmaker.sh" (the instructions for which can be found at the [QIIME_utilities](https://github.com/mtruglio/QIIME_utilities) page) that generates a taxonomic file ("16S_id_to_tax.map") linking the GenBank GI accession IDs to the headers in the fasta filed.  This script downloads files from the NCBI taxonomy server and matches the GI accession number in the fasta file with the taxonomy description.  This process resulted in a pair of files each with 18,773 entries present (as of August 2018).


### Perl script for taxonomy parsing on the mapping file

The input mapping file is defined as being of two columns, the first being the GI accession ID, and the second being the taxonomy.  The data structure of the NCBI taxonomy was a character string delimited by semicolons, and it was this string that is parsed using the Perl script (NCBI_16StaxaParse.pl) and stored in a MySQL database.

The Perl script (NCBI_16StaxaParse.pl) updates the downloaded NCBI taxonomy to parse the output so that suborders and tribes were removed. Three steps of analyses were required: 
  * simple taxonomy, where names were correctly classified;
  * complex taxonomy, where a specific taxonomic name needed to be removed;
  * names including the word "Group". 
  
*The initial step resets the group naming issue for L3, and L6 - L9. This was conducted one at a time as some ‘groups’ changed their location as they were moved back through the taxonomy.

*The string was split into an array, which for the reason described above had a variable number of elements.    The split array was loaded into a table within MySQL and the taxonomy was analysed as a group at the L2 level.  Archaea were analysed first, and then bacteria.  Whilst these subsets were manually curated to work out the most parsimonious taxonomic situation, the building of a new taxonomic table was done by writing MySQL scripts that would process the taxonomy if necessary and move the curated data from that subset into a new table.

