#!/usr/bin/env perl

use File::Basename;
use File::Path;
use Cwd 'abs_path';

print "Content-type: text/html\n\n";

if ($ENV{DOCUMENT_URI} eq "/index.html") {
	exit;
}

(my $uri = $ENV{REQUEST_URI}) =~ s/\/*(index.html)$/\//;

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
