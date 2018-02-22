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

use FindBin qw( $RealBin );
use lib $RealBin;

use File::Find;
use CGI;
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

# Determine local directory of "root" of web site and generate a 
# "relative" URL request to that root
#
# $ENV{Base_URL} is set by apache's .htaccess configuration file on a 
#	per host basis

#(my $request = $ENV{REQUEST_URI}) =~ s/$ENV{Base_URL}//;
#
#(my $site_root = $ENV{SCRIPT_FILENAME} . $request ) =~ s/\/cgi\/.*?\//\//;
#$site_root =~ s/\/?sitemap.xml//;
#$site_root  =~ s/\/*$//;



my $root_folder = $site_root;
my $root_url = "http://$ENV{HTTP_HOST}$ENV{Base_URL}";


# Print sitemap header
print qq{<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9
         http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd"
         xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">

};

find(\&index_file, $root_folder);


print "</urlset>\n";


sub index_file {
	my $filepath = $File::Find::name;
	
	if ($filepath =~ s/^$root_folder(.*?)(index)?\.html$/$1/i) {
		# Ignore certain files
		return if ($filepath =~ /^\/(cgi\/|templates\/|google......|notfound|mt\/|mt-static)/);
		
		my $priority = "0.8";
	#	my @d = gmtime ((stat("$File::Find::name"))[9]);	# get file's modification time
		my @d = gmtime();
		
		my $lastmod = sprintf "%4d-%02d-%02dT%02d:%02d:%02d-04:00", $d[5]+1900,$d[4]+1,$d[3],$d[2],$d[1],$d[0];
		
		my $change = "<changefreq>daily</changefreq>\n";
		
		if ($filepath =~ /^$/) {
			# Site root
			$priority = "1.0";
		}
		print qq{<url>
<loc>$root_url$filepath</loc>
$change<lastmod>$lastmod</lastmod>
<priority>$priority</priority>
</url>

}

	}
	
}