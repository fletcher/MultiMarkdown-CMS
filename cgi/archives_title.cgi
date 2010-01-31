#!/usr/bin/env perl


print "Content-type: text/html\n\n";

# Where am I called from
my $search_path = $ENV{REQUEST_URI};

$search_path =~ /(\d\d\d\d)(?:.*?(\d\d))?/;
my $year = $1;
my $month = $2;

my @months = qw(January February March April May June July August
	September October November December);


my $title = "";

if ($month ne "") {
	$title = "$months[$month-1] ";
}

$title .= "$year Archives";

print $title;