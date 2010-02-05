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

use MultiMarkdownCMS;



# Configuration

$threshold = 0.25;		# Minimum relatedness score (0...1)
$max_matches = 5;		# Maximum related pages to show
my $debug = 0;			# Enables extra output for debugging


print "Content-type: text/html\n\n";

# Don't match these pages
if ($ENV{DOCUMENT_URI} =~ /(\/index.html|\/?\d+\/\d+\/index|\/?archives|\/.*tagmap\.html)/) {
	exit;
}


# Get commonly needed paths
my ($site_root, $requested_url, $document_url) 
	= MultiMarkdownCMS::getHostingPaths($0);

# Debugging aid
print qq{
	Site root directory: $site_root<br/>
	Request:  $requested_url<br/>
	Document: $document_url<br/>
} if $debug;


local $/;


open(INDEX, "< $site_root/cgi/vector_index");
my $index = <INDEX>;
close(INDEX);

my %matches = ();
my $query = "$document_url";

my $content = "";


while ($index =~ /^(.*$query.*)$/mig) {
	$1 =~ /^(\S+)\t(\S+)\t([\.\d]+)$/;
	$a = $1;
	$b = $2;
	$score = $3;
	next if ($score < $threshold);
	if ($a eq $query) {
		$matches{$b} = $score;
	} else {
		$matches{$a} = $score;
	}
}


my $count = 0;
foreach my $match (sort {$matches{$b} <=> $matches{$a}} keys %matches) {
	if ($count < $max_matches) {
		open (FILE, "<$site_root$match");
		my $data = <FILE>;
		close(FILE);
		my $title = $match;
		if ($data =~ /<h1.*?>(.*)<\/h1>/) {
			$title = $1;
		}
		my $score = "";
		$score = $matches{$match} if ($debug);
		$match =~ s/^\///;
		$match =~ s/(index)?\.html//;
		$content .= "<li><a href=\"/$match\">$title</a></li>$score\n";
	}
	$count++;
}
if ($content ne "") {
	print qq{<h3>Similar Pages</h3>
<ul>
$content
</ul>
};
}

