#!/usr/bin/env perl
use strict;
use warnings;
use Bio::SeqIO;
use File::Spec;

my $sfetch = `which esl-sfetch`;
chomp($sfetch);
unless ( $sfetch && -x $sfetch ) {
    die("make sure you have loaded hmmer/3 so that esl-sfetch in path");
}

my $dir = 'virus_search/gene_search';

my $query_col = 1;
my $genomedir = 'genomes';


my $genomeext = 'vecscreen_shovill.fasta';

my $outdir = 'virus_search';
mkdir($outdir) unless -d $outdir;

my $outseq = Bio::SeqIO->new(-format => 'fasta',
			   -file   => ">".File::Spec->catfile($outdir,
							      "Bd_contigs_virus_gene_hits.fasta"));
opendir(my $od => $dir) || die $!;
my %names;
foreach my $subdir ( readdir($od) ) {
	next unless  $subdir =~ /(\S+)_gene/;
	my $gene = $1;
	opendir(my $sd => File::Spec->catfile($dir,$subdir)) || die $!;
	foreach my $file (readdir($sd)) {
		next unless ($file =~ /(\S+)\.vecscreen_shovill.TFASTX_\S+\.tab/);
		my $stem = $1;
		open(my $fh => File::Spec->catfile($dir,$subdir,$file)) || die $!;
		while(<$fh>) {
			next if /^\#/;
			chomp;
			my @row = split(/\t/,$_);
			my ($target,$ctgname) = ($row[0],$row[$query_col]);
			$names{$stem}->{$ctgname}++;
		}
	}
}
for my $stem ( keys %names ) {
	my $genomefile = File::Spec->catfile($genomedir,
										 sprintf("%s.%s",$stem,$genomeext));

	if ( ! -f "$genomefile.ssi") {
		`$sfetch --index '$genomefile'`;
	}
	for my $ctgname ( keys %{$names{$stem}} ) {
		open(my $fasta => "$sfetch '$genomefile' $ctgname |") || die $!;
		my $seqin = Bio::SeqIO->new(-fh => $fasta,
									-format => 'fasta');
	    while ( my $seq = $seqin->next_seq ) {
			my $st = $stem;
			$st =~ s/[\(\)]/_/g;
			$seq->display_id(sprintf("%s_%s",$st,$seq->display_id));
			$outseq->write_seq($seq);
	    }
	}
}
