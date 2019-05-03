#!/usr/bin/perl
#
# last edited by pjb on: 2019-05-03
#
#	this is a script to parse the NCBI taxonomy  
#	output to make it 'simpler' without suborders, tribes etc.
#	there are three parts to the analysis:
#		simple taxonomy where names are fine
#		complex ones where have to remove a specific taxonomic name	
#		'group' names
#
######################################################


use strict;
use warnings;
use DBI;
use Bio::Seq;
use Bio::SeqIO;

my ($dbh, $sth, $datasource, $count, $rowcount, $statement, $joiner, $querystring);
my ($size, $L2, $L1, $L3, $i, $tempName, $empty, $specificT, $new);

my (@taxa, @array);

my $root		= ("/path/to/root/folder/");			## will need to be changed
my $log			= ($root ."logOfActivity2k18.txt");
my $cleanTax	= ($root . "16S_id_to_tax.map");
my $finalTax	= ($root . "16S_id_to_taxModNew.map");
my $doneTax		= ($root . "16S_id_to_taxModDone.map");
my $tax1		= ($root . "2k18_16Sparse1.txt");
my $tax2		= ($root . "2k18_16Sparse2.txt");

my $name		= ("n01664Taxa2018");
my $loadT		= ($name . "_base");
my $workingT	= ($name . "_working");
my $finalT		= ($name . "_final");

open (LOG, ">$log") or die ("couldn't open $log: $!\n");

print ("Process started at " . scalar(localtime) . ".\n");
print LOG ("Process started at " . scalar(localtime) . ".\n");


## connect to the db and parse the taxonomy ##

&dbConnect();


## on with the work ##

&theWork();

print ("Process complete at " . scalar(localtime) . ".\n");
print LOG ("Process complete at " . scalar(localtime) . ".\n");

close LOG;


#####################
#                   #
#    subroutines    #
#                   #
#####################


sub theWork {

	## initial parsing of the file  ##

	if (-e $tax1) {	print ("The file has already been made.\n");
	} else {		system "cat $cleanTax | perl -lpe 's/\\ /\\_/g' > $tax1";
	}

	open (IN, "<$tax1") or die ("couldn't open $tax1: $!\n");
	open (OUT, ">$tax2") or die ("couldn't open $tax2: $!\n");

	while (<IN>) {
		chomp;
		my ($GI, $fullTax)	= split;
		@taxa	= split("\;", $fullTax);
		$size	= @taxa;
			
		print OUT ($GI, "\t", $size, "\t", join("\t", @taxa), "\n");	
	}

	close IN;
	close OUT;


	## load the base table ##

	$sth = $dbh->prepare (qq{drop table if exists $loadT});	$sth->execute();
	$sth = $dbh->prepare (qq{create table $loadT (GIid varchar(40), taxCol smallint, L1tax varchar(80), L2tax varchar(80), L3tax varchar(80), L4tax varchar(80), L5tax varchar(80), L6tax varchar(80), L7tax varchar(80), L8tax varchar(80), L9tax varchar(80), L10tax varchar(80), L11tax varchar(80), L12tax varchar(80))});	$sth->execute();
	
	$sth = $dbh->prepare (qq{drop table if exists $workingT});	$sth->execute();
	$sth = $dbh->prepare (qq{create table $workingT (tableID mediumint, GIid varchar(40), taxCol smallint, happy enum('y', 'n'), L1tax varchar(80), L2tax varchar(80), L3tax varchar(80), L4tax varchar(80), L5tax varchar(80), L6tax varchar(80), L7tax varchar(80), L8tax varchar(80), L9tax varchar(80), L10tax varchar(80), L11tax varchar(80), L12tax varchar(80))});	$sth->execute();	
	
	$sth = $dbh->prepare (qq{drop table if exists $finalT});	$sth->execute();
	$sth = $dbh->prepare (qq{create table $finalT (tableID mediumint, GIid varchar(40), taxCol smallint, happy enum('y', 'n'), L1tax varchar(80), L2tax varchar(80), L3tax varchar(80), L4tax varchar(80), L5tax varchar(80), L6tax varchar(80), L7tax varchar(80), L8tax varchar(80), L9tax varchar(80), L10tax varchar(80), L11tax varchar(80), L12tax varchar(80))});	$sth->execute();	
	
	$sth = $dbh->prepare (qq{load data local infile '$tax2' into table $loadT});	$sth->execute();
	$sth = $dbh->prepare (qq{alter table $loadT add column tableID mediumint auto_increment primary key first});	$sth->execute();
	$sth = $dbh->prepare (qq{alter table $loadT add column happy enum('y', 'n') default 'n' after taxCol});	$sth->execute();


	## sort out the 'simple' taxonomy ##
		
	my @simple	= ('DPANN_group', 'Euryarchaeota', 'Acidobacteria', 'Aquificae', 'Caldiserica', 'Chrysiogenetes', 'Deferribacteres', 'Dictyoglomi', 'Elusimicrobia', 'Fusobacteria', 'Nitrospirae', 'Spirochaetes', 'Synergistetes', 'Thermodesulfobacteria', 'Thermotogae', 'unclassified_Bacteria');
	
	foreach my $simpleTax (@simple) {
		$sth = $dbh->prepare (qq{update $loadT set happy = 'y' where L2tax = '$simpleTax'});	$sth->execute();	
		&moveHappy($simpleTax, $empty);		
	}


	## sort out the 'complex' taxonomy ##
	
	$sth = $dbh->prepare (qq{update $loadT set happy = 'y' where L2tax = 'TACK_group'});	$sth->execute();		
	&moveHappy("TACK_group", $empty);
	&columnTrim("Archaea", "TACK_group", "");

	$sth = $dbh->prepare (qq{update $loadT set L3tax = 'Bacteroidetes_Chlorobi_group' where L3tax = 'Bacteroidetes/Chlorobi_group'});	$sth->execute();		
	$sth = $dbh->prepare (qq{update $loadT set happy = 'y' where L2tax = 'FCB_group' and L3Tax != 'Bacteroidetes_Chlorobi_group'});	$sth->execute();	
	&moveHappy("FCB_group_partA", $empty);		
	&columnTrim("Bacteria", "FCB_group", "cond1");

	$sth = $dbh->prepare (qq{update $loadT set happy = 'y' where L2tax = 'FCB_group' and L3Tax = 'Bacteroidetes_Chlorobi_group'});	$sth->execute();	
	&moveHappy("FCB_group_partB", $empty);		
	&columnTrim("Bacteria", "FCB_group", "Bacteroidetes_Chlorobi_group");	
	
	$sth = $dbh->prepare (qq{update $loadT set L2tax = 'Nitrospinae_Tectomicrobia_group' where L2tax = 'Nitrospinae/Tectomicrobia_group'});	$sth->execute();	
	$sth = $dbh->prepare (qq{update $loadT set happy = 'y' where L2tax = 'Nitrospinae_Tectomicrobia_group'});	$sth->execute();	
	&moveHappy("Nitrospinae_Tectomicrobia_group", $empty);		
	&columnTrim("Bacteria", "Nitrospinae_Tectomicrobia_group", "");
		
	$sth = $dbh->prepare (qq{update $loadT set L3tax = 'delta_epsilon_subdivisions' where L3tax = 'delta/epsilon_subdivisions'});	$sth->execute();		
	$sth = $dbh->prepare (qq{update $loadT set happy = 'y' where L2tax = 'Proteobacteria' and L3Tax != 'delta_epsilon_subdivisions'});	$sth->execute();	
	&moveHappy("Proteobacteria_partA", $empty);		

	$sth = $dbh->prepare (qq{update $loadT set happy = 'y' where L2tax = 'Proteobacteria' and L3Tax = 'delta_epsilon_subdivisions'});	$sth->execute();	
	&moveHappy("Proteobacteria_partB", $empty);		
	&columnTrim("Bacteria", "Proteobacteria", "delta_epsilon_subdivisions");	
	
	$sth = $dbh->prepare (qq{update $loadT set happy = 'y' where L2tax = 'PVC_group'});	$sth->execute();	
	&moveHappy("PVC_group", $empty);		
	&columnTrim("Bacteria", "PVC_group", "");
	
	$sth = $dbh->prepare (qq{update $loadT set L3tax = 'Cyanobacteria_Melainabacteria_group' where L3tax = 'Cyanobacteria/Melainabacteria_group'});	$sth->execute();
	$sth = $dbh->prepare (qq{update $loadT set happy = 'y' where L2tax = 'Terrabacteria_group'});	$sth->execute();	
	&moveHappy("Terrabacteria_group", $empty);		
	&columnTrim("Bacteria", "Terrabacteria_group", "");		
			

	## sort out the groups issue ##
	
	for ($i = 3; $i <= 9; $i++) {
		my $curTax	= ("L" . $i . "tax");

		$sth = $dbh->prepare (qq{insert into $loadT select * from $workingT where $curTax like '%group%'});	$sth->execute();		
		$sth = $dbh->prepare (qq{delete from $workingT where $curTax like '%group%'});	$sth->execute();
	}

	$sth = $dbh->prepare (qq{update $loadT set happy = 'n'});	$sth->execute();	

	for ($i = 3; $i <= 9; $i++) {
		&groupTrim($i, $empty);
	}

	for ($i = 3; $i <= 9; $i++) {
		&groupTrim($i, $empty);
	}


	## generate final output ##	

	$sth = $dbh->prepare (qq{insert into $finalT select * from $workingT});	$sth->execute();

	for ($i = 1; $i <= 12; $i++) {
		my $curTax	= ("L" . $i . "tax");
		
		$sth = $dbh->prepare (qq{update $finalT set $curTax = '' where $curTax = NULL});	$sth->execute();
		
		push(@array, $curTax);
	}

	my $taxList = join(",", @array);
	
	$sth = $dbh->prepare (qq{alter table $finalT drop column tableID});	$sth->execute();	
	$sth = $dbh->prepare (qq{alter table $finalT drop column taxCol});	$sth->execute();	
	$sth = $dbh->prepare (qq{alter table $finalT drop column happy});	$sth->execute();	
	
	open (OUT, ">$finalTax") or die ("couldn't open $finalTax: $!\n");

	$statement = ("select GIid, concat_ws(';', $taxList) from $finalT order by GIid");

	&statementPull ($statement, "\t");

	close OUT;		
	
	## tidy that up ##
	
	system "cat $finalTax | perl -lpe 's/;;;;//g;s/;;;//g;s/;;//g;s/NULL//g' > $doneTax";
}


sub moveHappy {
	($tempName, $empty)	= @_;
	
	
	## do the move ##
	
	$sth = $dbh->prepare (qq{insert into $workingT select * from $loadT where happy = 'y'});	$sth->execute();	
	$sth = $dbh->prepare (qq{delete from $loadT where happy = 'y'});	$sth->execute();

	print ("Just moved $tempName at " . scalar(localtime) . ".\n");	
	print LOG ("Just moved $tempName at " . scalar(localtime) . ".\n");
}


sub groupTrim {
	($i, $empty)	= @_;

	my $h			= $i - 1;
	my $j			= $i + 1;
	my $k			= $i + 2;
	my $cut			= ("-f" . ($i + 4));
	my $curTax		= ("L" . $i . "tax");
	my $taxA		= ("L" . $h . "tax");
	my $taxB		= ("L" . $j . "tax");
	my $taxC		= ("L" . $k . "tax");
	my $compact		= ($taxA . "_to_" . $taxC);
	my $retrieve	= ($root . $compact . ".txt");	
	my $new			= ($root . $compact . "Mod.txt");	
	
	$sth = $dbh->prepare (qq{update $loadT set happy = 'y' where $curTax like '%group%'});	$sth->execute();

	$sth = $dbh->prepare (qq{insert into $workingT select * from $loadT where happy = 'y'});	$sth->execute();	
	$sth = $dbh->prepare (qq{delete from $loadT where happy = 'y'});	$sth->execute();


	## retrieve data ##

	open (OUT, ">$retrieve") or die ("couldn't open $retrieve: $!\n");

	$statement = ("select * from $workingT where $curTax like '%group%'");
		
	&statementPull ($statement, "\t");

	close OUT;

	$sth = $dbh->prepare (qq{delete from $workingT where $curTax like '%group%'});	$sth->execute();

	system "cut --complement $cut $retrieve > $new";

	&tableLoad($specificT, $new);
	
	system "rm $retrieve $new";

	return ($i, $empty);
}


sub columnTrim {
	($L1, $L2, $L3)	= @_;
	
	my $compact		= ("L1" . substr($L1, 0, 10) . "_L2" . substr($L2, 0, 10) . "_L3" . substr($L3, 0, 10));	
	my $retrieve	= ($root . $compact . ".txt");	
	$new			= ($root . $compact . "Mod.txt");	
	$specificT		= ("specific_". $compact);
	

	## retrieve data ##

	open (OUT, ">$retrieve") or die ("couldn't open $retrieve: $!\n");

	if ($L3 eq 'cond1') {
		$statement = ("select * from $workingT where L2tax = '$L2' and L3tax != 'Bacteroidetes_Chlorobi_group'");
	} elsif ($L3 eq 'cond2') {
		$statement = ("select * from $workingT where L2tax = '$L2' and L3tax != 'delta_epsilon_subdivisions'");
	} elsif ($L3 eq 'Bacteroidetes_Chlorobi_group') {
		$statement = ("select * from $workingT where L2tax = '$L2' and L3tax = 'Bacteroidetes_Chlorobi_group'");
	} elsif ($L3 eq 'delta_epsilon_subdivisions') {
		$statement = ("select * from $workingT where L2tax = '$L2' and L3tax = 'delta_epsilon_subdivisions'");
	} else {
		$statement = ("select * from $workingT where L2tax = '$L2'");
	}
		
	&statementPull ($statement, "\t");

	close OUT;	

	if ($L3 eq 'cond1') {
		$sth = $dbh->prepare (qq{delete from $workingT where L1tax = '$L1' and L2tax = '$L2' and L3tax != 'Bacteroidetes_Chlorobi_group'});	$sth->execute();
	} elsif ($L3 eq 'cond2') {
		$sth = $dbh->prepare (qq{delete from $workingT where L1tax = '$L1' and L2tax = '$L2' and L3tax != 'delta_epsilon_subdivisions'});	$sth->execute();
	} elsif ($L3 eq 'Bacteroidetes_Chlorobi_group') {
		$sth = $dbh->prepare (qq{delete from $workingT where L1tax = '$L1' and L2tax = '$L2' and L3tax = 'Bacteroidetes_Chlorobi_group'});	$sth->execute();
	} elsif ($L3 eq 'delta_epsilon_subdivisions') {
		$sth = $dbh->prepare (qq{delete from $workingT where L1tax = '$L1' and L2tax = '$L2' and L3tax = 'delta_epsilon_subdivisions'});	$sth->execute();
	} else {
		$sth = $dbh->prepare (qq{delete from $workingT where L1tax = '$L1' and L2tax = '$L2'});	$sth->execute();		
	}
	
	
	## adjust and reload ##

	if ($L3 eq 'cond1' || $L3 eq 'cond2') {
		system "cat $retrieve | perl -lpe 's/\t$L2//g;s/\tn\t/\ty\t/g' > $new";			
	} elsif ($L3 eq 'Bacteroidetes_Chlorobi_group' || $L3 eq 'delta_epsilon_subdivisions') {
		system "cat $retrieve | perl -lpe 's/\t$L2\t$L3//g;s/\tn\t/\ty\t/g' > $new";	
	} else {
		system "cat $retrieve | perl -lpe 's/\t$L2//g;s/\tn\t/\ty\t/g' > $new";	
	}

	&tableLoad($specificT, $new);
	
	
	## clean up ##

	$sth = $dbh->prepare (qq{drop table if exists $specificT});	$sth->execute();

	system "rm $retrieve $new";	
	
	return ($L1, $L2, $L3);
}


sub tableLoad {
	($specificT, $new)	= @_;
	
	$sth = $dbh->prepare (qq{drop table if exists $specificT});	$sth->execute();
	$sth = $dbh->prepare (qq{create table $specificT (tableID mediumint, GIid varchar(40), taxCol smallint, happy enum('y', 'n'), L1tax varchar(80) default '', L2tax varchar(80) default '', L3tax varchar(80) default '', L4tax varchar(80) default '', L5tax varchar(80) default '', L6tax varchar(80) default '', L7tax varchar(80) default '', L8tax varchar(80) default '', L9tax varchar(80) default '', L10tax varchar(80) default '', L11tax varchar(80) default '')});	$sth->execute();	
	$sth = $dbh->prepare (qq{load data local infile '$new' into table $specificT});	$sth->execute();	
	$sth = $dbh->prepare (qq{alter table $specificT add column L12tax varchar(80) default ''});	$sth->execute();	

	$sth = $dbh->prepare (qq{insert into $workingT select * from $specificT});	$sth->execute();
	
	return ($specificT, $new);
}


sub statementPull {
	($statement, $joiner) = @_;

	$sth = $dbh->prepare (qq{$statement});	$sth->execute();
				
	$count++;
				
	while (my @row_items = $sth->fetchrow_array ()) {
		$rowcount++;
		print OUT (join ("$joiner", @row_items), "\n");
		} unless ($rowcount) {
		print OUT ("No data to display\n");
	}

	return ($statement, $joiner);
}	


sub dbConnect {
	$count = 0;
	$rowcount = 0;

	$datasource = "DBI:mysql:database_name:mysql_local_infile=1";	## changed for use ##
	$dbh = DBI->connect($datasource, 'username', 'password');		## changed for use ##
	$querystring = '';
}
