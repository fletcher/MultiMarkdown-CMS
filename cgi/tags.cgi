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

use File::Basename;
use File::Path;
use Cwd 'abs_path';
use CGI;
use File::Find;

# TODO: If no tag given, should give list of available tags as links

my $cgi = CGI::new();

my @tag_query = ();
my $content = "";

# Web root folder
my $search_path = "";

if ($ENV{DOCUMENT_ROOT}) {
	$search_path = $ENV{DOCUMENT_ROOT};
} else {
	my $me = $0;		# Where is this script located?
	$me = dirname($me);
	$me = abs_path($me);
	($search_path = $me) =~ s/\/cgi$//;
}

print "Content-type: text/html\n\n";

if ($ENV{DOCUMENT_URI} eq "/tags/index.html") {
	# We are looking for pages that match given tag(s)
	
	# Convert path into list of tags to match
#	my $path = $cgi->path_info;
	my $path = $cgi->param('query');
	
	# Clean up tag names
	$path =~ s/_/ /g;
	
	# Allow multiple tags separated by '/'
	@tag_query = split('\s*/\s*',$path);	

	# Index all documents
	find(\&find_pages, $search_path);

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
	my $file_path = $ENV{DOCUMENT_ROOT} . $ENV{DOCUMENT_URI};

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
				$filepath =~ s/(\A$search_path|(\/index)?\.html$)//g;
				$data =~ /<title>(.*?)<\/title>/;
				$content .= "<li><a href=\"$filepath\">$1</a></li>\n" if $match;
			}
		}
		
	}
}
