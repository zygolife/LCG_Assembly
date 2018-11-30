#!/usr/bin/perl
#
use strict;
use warnings;

my %stats;

my $dir = shift || 'genomes';
my %cols;
opendir(DIR,$dir) || die $!;
foreach my $file ( readdir(DIR) ) {
 next unless ( $file =~ /(\S+)\.stats.txt$/);
 my $stem = $1;
 $stem =~ s/\.sorted//;
 open(my $fh => "$dir/$file") || die $!;
 while(<$fh>) {
  next if /^\s+$/;
  s/^\s+//;
  chomp;
  if ( /(.+)\s+=\s+(\d+(\.\d+)?)/ ) {
      $stats{$stem}->{$1} = $2;
#      warn($1," ", $2,"\n");
      $cols{$1}++;
  }
 }
}
my @cols = sort keys %cols;
print join("\t", qw(SampleID), @cols), "\n";
foreach my $sp ( sort keys %stats ) {
	print join("\t", $sp, map { $stats{$sp}->{$_} } @cols), "\n";
}
