#!/usr/bin/env perl

use strict;
use warnings;
use VectorMap;
use File::Find;
use CGI;

my $map = VectorMap->new();
my $cgi = CGI::new();
my $query = $cgi->param("query") || "test query multimarkdown";
#$query = $cgi->path_info;

print $cgi->header();
my $content = "";

# Web root folder
my $search_path = $ENV{DOCUMENT_ROOT} || "/Users/fletcher/Sites/mmd_static";

# Index all documents
find(\&find_pages, $search_path);

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
	(my $a1 = $a) =~ s/(\A$search_path|(\/index)?\.txt$)//g;
	$content .= "<li><a href=\"$a1\">$title</a>: $matrix{$a}</li>\n";
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
