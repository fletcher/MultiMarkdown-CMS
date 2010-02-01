#!/usr/bin/env perl

# Copyright (C) 2010  Fletcher T. Penney <fletcher@fletcherpenney.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
#    Free Software Foundation, Inc.
#    59 Temple Place, Suite 330
#    Boston, MA 02111-1307 USA

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
