#!/usr/bin/env perl

use File::Basename;
use File::Path;
use Cwd 'abs_path';

print "Content-type: text/html\n\n";

# Don't match these pages
if ($ENV{DOCUMENT_URI} =~ /^(\/index.html|\/?\d+\/\d+\/index|\/?archives)/) {
	exit;
}

# Configuration

$threshold = 0.25;		# Minimum relatedness score (0...1)
$max_matches = 5;		# Maximum related pages to show
$debug = 0;				# Show scores

# Read index file

local $/;
open(INDEX, "< $ENV{DOCUMENT_ROOT}/cgi/vector_index");
my $index = <INDEX>;
close(INDEX);

my %matches = ();
my $query = "$ENV{DOCUMENT_URI}";

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
		open (FILE, "<$ENV{DOCUMENT_ROOT}$match");
		my $data = <FILE>;
		close(FILE);
		my $title = $match;
		if ($data =~ /<h1.*?>(.*)<\/h1>/) {
			$title = $1;
		}
		my $score = "";
		$score = $matches{$match} if ($debug);
		$content .= "<li><a href=\"$match\">$title</a></li>$score\n";
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

