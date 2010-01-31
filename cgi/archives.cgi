#!/usr/bin/env perl

use File::Basename;
use File::Path;
use Cwd 'abs_path';

print "Content-type: text/html\n\n";

exit if ($ENV{DOCUMENT_URI} eq "/index.html");

my @months = qw(January February March April May June July August
	September October November December);

# Where am I called from and get directory
(my $req = $ENV{REQUEST_URI}) =~ s/\/*$/\//;

my $search_path = dirname($ENV{DOCUMENT_ROOT} . $req . "fake");

# Look for other directories that exist

local $/;

if ($req =~ /(\d\d\d\d).*\d\d/) {
	# Print entries in the current month
	my %pages = ();
	(my $uri = $req) =~ s/[^\/]*\.html//;
	foreach my $filepath (glob("$search_path/*.html")) {
		if ($filepath !~ /index.html$/) {
			open (FILE, "<$filepath");
			my $data = <FILE>;
			if ($data =~ /<h1 class="page-title">(.*)<\/h1>/) {
				my ($title, $date) = ($1,"");
				if ($data =~ /<meta name="Date" content="(.*?)"\/>/i) {
					$date = $1;
					$date =~ s/(\d?\d)\/(\d\d)\/(\d\d\d\d).*/$3.$1.$2/;
				}
				$filepath =~ /$search_path\/(.*).html/;
				$pages{$date}{$title} = "$uri$1";
			}
		}
	}

	if ( scalar keys %pages > 0 ) {
		print "<ul class=\"archives\">\n";
		foreach my $date (sort { $b cmp $a} keys(%pages)) {
			foreach my $title (sort keys %{$pages{$date}}) {
				print "<li>$date: <a href=\"$pages{$date}{$title}\">$title</a></li>\n";""
			}
		}
		print "</ul>\n";	
	}	
} elsif ($req =~ /(\d\d\d\d)/) {
	# Print months in current year that have entries
	my $year = $1;
	local $/;

	my $content = "";

	my %months_with_entries = ();
	
	foreach my $filepath (glob("$search_path/*/*.html")) {
		$filepath =~ /\d\d\d\d\/(\d\d)/;
		
		$months_with_entries{$1} = 1;
	}

	foreach (sort keys %months_with_entries) {
		my $month = $months[$_-1];
		$content .= "<li><a href=\"$req$_/\">$month $year Archives</a></li>\n";
	}


	if ($content ne "") {
		print qq{<ul>
$content
</ul>
};
	}
} elsif ($req =~ /\/archives/) {
	my %pages = ();
	my $content = "";
	
	foreach my $filepath (glob("$ENV{DOCUMENT_ROOT}/*/*/*.html")) {
		if ($filepath =~ /(\d\d\d\d)\/(\d\d)/){
			$pages{$1}{$2} = 1;
		}

	}

	foreach my $year (sort { $b cmp $a} keys(%pages)) {
		foreach my $month (sort { $b cmp $a}keys %{$pages{$year}}) {
			$content .= "<li><a href=\"/$year/$month/\">$months[$month-1] $year</a></li>\n";
		}
	}
	if ($content ne "") {
		print qq{<ul>
$content
</ul>
};

}

}
