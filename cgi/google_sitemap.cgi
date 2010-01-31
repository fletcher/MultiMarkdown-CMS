#!/usr/bin/env perl

use strict;
use warnings;

use File::Find;
use Cwd 'abs_path';
use CGI;

my $root_folder = "$ENV{DOCUMENT_ROOT}/";
my $root_url = "http://$ENV{HTTP_HOST}/";

print "Content-type: text/html\n\n";


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
		return if ($filepath =~ /^(cgi\/|templates\/|google......|notfound|mt\/|mt-static)/);
		return if ($filepath =~ /^test$/);
		
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