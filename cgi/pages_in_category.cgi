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

use FindBin qw( $RealBin );
use lib $RealBin;

use MultiMarkdownCMS;
my $debug = 0;			# Enables extra output for debugging

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


# Don't do this on the home page
if ($requested_url =~ /^\/?$/) {
	exit;
}


# We want to search only in the current directory

$search_path = $site_root . $requested_url;


local $/;

my $content = "";

foreach my $filepath (glob("$search_path*/index.html")) {
	open (FILE, "<$filepath");
	my $data = <FILE>;
	if ($data =~ /<h1 (?:xmlns="" )?class="page-title">(.*)<\/h1>/) {
		my $title = $1;
		$filepath =~ /$site_root\/(.*\/)index.html/;
		$content .= "<li><a href=\"/$1\">$title</a></li>\n";		
	}
}

if ($content ne "") {
	print qq{<ul>
$content
</ul>
};
}
