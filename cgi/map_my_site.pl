#!/usr/bin/env perl

use strict;
use warnings;
use VectorMap;
use File::Find;
use File::Basename;
use Cwd 'abs_path';

my $map = VectorMap->new();

# Determine web root folder
my $me = $0;		# Where is this script located?
$me = dirname($me);
$me = abs_path($me);
(my $search_path = $me) =~ s/\/cgi$//;


# Index all documents
find(\&find_pages, $search_path);

# Iterate through objects and calculate similarites
my %matrix = $map->map_relationships();

# Display results
foreach my $a (sort keys %matrix) {
	foreach my $b (sort keys %{$matrix{$a}}) {
		my ($a1,$b1);
		for (($a1,$b1) = ($a,$b)) {s/(\A$search_path|\.txt$)//g; $_.=".html"};
		print "$a1\t$b1\t" . $matrix{$a}{$b} . "\n";
	}
}

sub find_pages {
	# We're looking for .txt files
	my $filepath = $File::Find::name;
	if ($filepath !~ /^\/cgi\/|robots\.txt/) {
		$map->add_file($filepath) if ($filepath =~ /\.txt$/);		
	}
}
