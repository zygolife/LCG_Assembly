#!/usr/bin/perl
#
use File::Spec;
use strict;
use warnings;

my %stats;

my $dir = shift || 'genomes';
my %cols = map { $_ => 1 }  qw(zz_BUSCO_Complete zz_BUSCO_Single
    zz_BUSCO_Duplicate zz_BUSCO_Fragmented
    zz_BUSCO_Missing zz_BUSCO_NumGenes);

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

 my $busco_file = File::Spec->catfile("BUSCO",sprintf("run_%s",$stem),
				      sprintf("short_summary_%s.txt",$stem));
				      
 if ( -f $busco_file ) {
     
     open(my $fh => $busco_file) || die $!;
     while(<$fh>) {	 
	 if (/^\s+C:(\d+\.\d+)\%\[S:(\d+\.\d+)%,D:(\d+\.\d+)%\],F:(\d+\.\d+)%,M:(\d+\.\d+)%,n:(\d+)/ ) {
	     $stats{$stem}->{"zz_BUSCO_Complete"} = $1;
	     $stats{$stem}->{"zz_BUSCO_Single"} = $2;
	     $stats{$stem}->{"zz_BUSCO_Duplicate"} = $3;
	     $stats{$stem}->{"zz_BUSCO_Fragmented"} = $4;
	     $stats{$stem}->{"zz_BUSCO_Missing"} = $5;
	     $stats{$stem}->{"zz_BUSCO_NumGenes"} = $6;
	 }
     }

 } else {
     #warn("Cannot find $busco_file");
 }
}


my @cols = sort keys %cols;

print join("\t", qw(SampleID), @cols), "\n";
foreach my $sp ( sort keys %stats ) {    
	print join("\t", $sp, map { $stats{$sp}->{$_} || '-' } @cols), "\n";
}
