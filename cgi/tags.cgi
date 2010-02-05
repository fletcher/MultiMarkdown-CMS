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

use CGI;
use File::Find;
use MultiMarkdownCMS;


my $cgi = CGI::new();
my $debug = 0;			# Enables extra output for debugging

my @tag_query = ();
my $content = "";

print "Content-type: text/html\n\n";

# Get commonly needed paths
my ($site_root, $requested_url, $document_url) 
	= MultiMarkdownCMS::getHostingPaths($0);

# Debugging aid
print qq{
	Site root directory: $site_root<br/>
	Request:  $requested_url<br/>
	Document: $document_url<br/>
} if $debug;


if ($document_url eq "/templates/tags.html") {
	# We are looking for pages that match given tag(s)
	
	# Convert path into list of tags to match
	my $path = $cgi->param('query');
	
	# Clean up tag names
	$path =~ s/_/ /g;
	
	# Allow multiple tags separated by '/'
	@tag_query = split('\s*/\s*',$path);	

	# Index all documents
	find(\&find_pages, $site_root);

	$query = join(', ',@tag_query);
	print qq{<div class="content"><h2>Pages tagged $query</h2>
};
	
	if ($content) {print qq{
<ul>
$content
</ul>
};
	};
	
	print "</div>";
} else {
	# We are processing tags on a given page

	# Where am I called from
	my $file_path = $site_root . $document_url;

	local $/;
	my $output = "";

	if (open (FILE, "<$file_path")) {
		my $data = <FILE>;
		close FILE;
		if ($data =~ /<meta name="Tags" content="(.*)"/mi) {
			my @tags = split(/\s*,\s*/, $1);
			my @links;
			for (@links = @tags) {s/\s/_/g; s/(.*)/<a href="\/tags\/$1">$1<\/a>/; s/>(.*)_(.*)</>$1 $2</g;};
			$output .= "tags: " . join(', ',@links);
		}
	}

	print "<div class=\"tags\">$output</div>\n";
}


sub find_pages {
	# We're looking for .html files
	my $filepath = $File::Find::name;
	
	if ($filepath =~ /\.html$/) {
		local $/;
		if (open (FILE, "<$filepath")) {
			my $data = <FILE>;
			close FILE;
			if ($data =~ /<meta name="Tags" content="(.*)"/mi) {
				my $tags = $1;
				my $match = 1;
				foreach (@tag_query) {
					$match = 0 if $tags !~ /(\A|,)\s*$_\s*(,|\Z)/i;
				}
				$filepath =~ s/(\A$site_root|(\/index)?\.html$)//g;
				#$filepath =~ s/^\///;
				$data =~ /<title>(.*?)<\/title>/;
				$content .= "<li><a href=\"$filepath\">$1</a></li>\n" if $match;
			}
		}
		
	}
}
