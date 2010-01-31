#!/usr/bin/env perl

use File::Basename;
use File::Path;
use Cwd 'abs_path';
use CGI;
use File::Find;

my $cgi = CGI::new();

my $content = "";

# Web root folder
my $search_path = $ENV{DOCUMENT_ROOT} || "/Users/fletcher/Sites/mmd_static";

print "Content-type: text/html\n\n";

my $content = "<taglist>\n";

# Index all documents
find(\&find_pages, $search_path);
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
