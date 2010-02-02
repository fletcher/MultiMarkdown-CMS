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

print "Content-type: text/html\n\n";

if ($ENV{DOCUMENT_URI} eq "/index.html") {
	exit;
}

(my $uri = $ENV{REQUEST_URI}) =~ s/\/*(index.html)?$/\//;

# Where am I called from
my $search_path = $ENV{DOCUMENT_ROOT} . $ENV{DOCUMENT_URI};

# Get just the directory
$search_path = dirname($search_path);
#print "Search $search_path\n<br/><br/>";

# Look for other directories that exist


local $/;

my $content = "";

foreach my $filepath (glob("$search_path/*/index.html")) {
	open (FILE, "<$filepath");
	my $data = <FILE>;
	if ($data =~ /<h1 class="page-title">(.*)<\/h1>/) {
		my $title = $1;
		$filepath =~ /$search_path\/(.*\/)index.html/;
		$content .= "<li><a href=\"$uri$1\">$title</a></li>\n";		
	}
}

if ($content ne "") {
	print qq{<ul>
$content
</ul>
};
}

#foreach $key (sort keys(%ENV)) {
#	print "$key = $ENV{$key}<BR>\n";
#}
