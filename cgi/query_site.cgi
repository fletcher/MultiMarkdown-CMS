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
use MultiMarkdownCMS;
use CGI;

my $debug = 0;			# Enables extra output for debugging

my $map = VectorMap->new();
my $cgi = CGI::new();
my $query = $cgi->param("query") || "test query multimarkdown";
#$query = $cgi->path_info;

print $cgi->header();
my $content = "";


# Get commonly needed paths
my ($site_root, $requested_url, $document_url) 
	= MultiMarkdownCMS::getHostingPaths($0);

# Debugging aid
print qq{
	Site root directory: $site_root<br/>
	Request:  $requested_url<br/>
	Document: $document_url<br/>
} if $debug;


# Index all documents
find(\&find_pages, $site_root);

# Iterate through objects and calculate similarites
$map->add_object('query',$query);
my %matrix = $map->query_map('query');

# Display results
foreach my $a (sort { $matrix{$b} <=> $matrix{$a}} keys %matrix) {
	next if ($matrix{$a} == 0);
	my $title ="";
	local $/;
	if (open (FILE, "<$a")) {
		my $data = <FILE>;
		close FILE;
		$data =~ /Title:\s*(.*?)\n/;
		$title = $1;
	}	
	(my $a1 = $a) =~ s/(\A$site_root|(\/index)?\.txt$)//g;
	$content .= "<li><a href=\"$ENV{Base_URL}$a1\">$title</a>: $matrix{$a}</li>\n";
}

print "<h2>Matches for \"$query\"</h2>";

if ($content) {
	print qq{
<ul>
$content
</ul>};
} else {
	print "<p>No matches...</p>";
}


sub find_pages {
	# We're looking for .txt files
	my $filepath = $File::Find::name;
	$map->add_file($filepath) if ($filepath =~ /\.txt$/);
}
