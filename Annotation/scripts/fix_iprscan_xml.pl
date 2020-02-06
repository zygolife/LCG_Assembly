#!/usr/bin/env perl
use strict;
use warnings;

my $last = "";
while(<>) {
	if(/^\s+<sequence/ && $last !~ /^(\s+)<protein/){
			print "  <protein>\n";
	}
	print $_;
	$last = $_;
}
