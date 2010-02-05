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


my $debug = 0;			# Enables extra output for debugging


my $cgi = CGI::new();

my $content = "";


#(my $request = $ENV{REQUEST_URI}) =~ s/$ENV{Base_URL}//;

#(my $site_root = $ENV{SCRIPT_FILENAME} . $request ) =~ s/\/cgi\/.*?\//\//;
#$site_root =~ s/\/?tags//;
#$site_root  =~ s/\/*$//;

#my $search_path;
##if ($ENV{Base_URL}) {
#	# We're called from Apache#
#	$search_path = $site_root;
#} else {#
#	# We're called from the command line
#	my $me = $0;
#	$me = dirname($me);
##	($search_path = $me) =~ s/\/cgi$//;
#}


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


my $content = "<taglist>\n";

# Index all documents
find(\&find_pages, $site_root);
$content .= "</taglist>\n";



open (TagCat, "| ./TagCategorizer.pl | xsltproc -nonet -novalid tagmap.xslt -");
print TagCat $content;
close TagCat;



sub find_pages {
	# We're looking for .html files
	my $filepath = $File::Find::name;
	
	if ($filepath =~ /\.html$/) {
		local $/;
		if (open (FILE, "<$filepath")) {
			my $data = <FILE>;
			close FILE;
			$content .= "<object><id>$filepath</id>\n";
			if ($data =~ /<meta name="Tags" content="(.*)"/mi) {
				my @tags = split(/\s*,\s*/, $1);
				foreach my $tag (@tags) {
					$content .= "<tag>$tag</tag>\n";
				}
			}
			$content .=  "</object>\n";
		}
		
	}
}
