#!/usr/bin/env perl
use warnings;
use strict;
use Bio::DB::Fasta;
use Bio::Location::Simple;
use Getopt::Long;
use Bio::SeqIO;

my $usage = "Usage: $0 -g glimmer-multiseq-file -f genome-fasta -o output-prefix";

my ($glimmer,$prefix,$dbname);
my $orfprefix = 'orf';
GetOptions(
    'g|glimmer:s'   => \$glimmer,
    'o|out|output:s'=> \$prefix,
    'f|fasta:s'     => \$dbname,
    'p|prefix:s'    => \$orfprefix,
    );

if ( ! defined $dbname ) {
    $dbname = shift @ARGV;
}
if ( ! defined $prefix ) {
    $prefix = shift @ARGV;
}

if ( ! defined $prefix ) {
    $prefix = $dbname;
    $prefix =~ s/\.(fasta|fa|seq|dna)\S*$//;
}


if ( ! defined $dbname || ! defined $prefix ) {
    die $usage;
}
my $db = Bio::DB::Fasta->new($dbname);

open( my $gff => ">$prefix.gff3") || die "cannot open $prefix.gff3";
my $outseq = Bio::SeqIO->new(-format => 'fasta', -file => ">$prefix.cds.fasta");
my $outpep = Bio::SeqIO->new(-format => 'fasta', -file => ">$prefix.aa.fasta");
my $infh;
if ( $glimmer ) {
    open($infh => $glimmer) || die "Cannot open glimmer file $glimmer: $!";
} else {
    $infh = \*STDIN;
}

my $seqname = "";
# we turned off circular assumptions about genomes so no predictions that span the origin.
#my $origin = Bio::Location::Simple->new(-start=>1,-end=>1);
my $len = 0;
my $n = 1;
print $gff "##gff-version 3\n";
while (<$infh>) {
    if( /^>(\S+)/ ) {
	$seqname = $1;
	$len = $db->length($seqname);
#	$origin = Bio::Location::Simple->new(-start => $len, -end => 1);
    } else {
	chomp;
	s/^\s*//;
	
	my ($id, $start, $end, $phase,$rest) = (split /\s+/, $_);
	my $strand;
	my ($ph,$str);
	if ($phase =~ /([+\-])(\d+)/ ) {
	    ($str,$ph) = ($1,$2);
	    $phase = $ph - 1;
	}
	($start, $end, $strand) = $end > $start ? ($start, $end, "+") : ($end, $start, "-");
	if ($str ne $strand ) {
	    warn("phase inferred strand ($str) differs from what is in predicted ($strand) for $seqname.$id");
	}
	
	my $location = Bio::Location::Simple->new(-start => $start, -end => $end, -strand => $str);
 	my $ORF;
	if ( $location->strand < 0 ) {
	    $ORF = $db->subseq($seqname, $end => $start);
	} else{
	    $ORF = $db->subseq($seqname, $start => $end);
	}
	$outseq->write_seq(Bio::Seq->new(-seq => $ORF,
					 -id  => sprintf("%s_%03d",$prefix,$n++),
					 -description => sprintf("%s:%s",$seqname,$location->to_FTstring)));
	$outpep->write_seq(Bio::Seq->new(-seq => $ORF,
					 -id  => sprintf("%s_%03d",$prefix,$n++),
					 -description => sprintf("%s:%s",$seqname,$location->to_FTstring))->translate);
					 
	#if( $start > $end && $str eq '+' ) {
	#    die "$start..$end $phase\n";
	#} 
	
	print $gff join ("\t", $seqname, "glimmer", "gene", 
			 $start, $end, ".", $strand, ".", 
			 sprintf("ID=%s.%s",$seqname,$id)),"\n";
	
	print $gff join ("\t", $seqname, "glimmer", "mRNA", 
			 $start, $end, ".", $strand, $phase, 
			 sprintf("ID=%s.%s.mRNA;Parent=%s.%s",$seqname,$id,$seqname,$id)),"\n";
	
	print $gff join ("\t", $seqname, "glimmer", "CDS", 
			 $start, $end, ".", $strand, $phase, 
			 sprintf("ID=%s.%s.CDS;Parent=%s.%s.mRNA",$seqname,$id,$seqname,$id)),"\n";
    }
}
