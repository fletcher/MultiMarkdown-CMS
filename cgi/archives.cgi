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


my @months = qw(January February March April May June July August
	September October November December);


local $/;

if ($requested_url =~ /^\/?(\d\d\d\d).*\d\d/) {
	my $year = $1;
	my $month = $2;
	# Print entries in the current month
	my %pages = ();

	foreach my $filepath (glob("$site_root/$year/$month/*.html")) {
		if ($filepath !~ /index.html$/) {
			open (FILE, "<$filepath");
			my $data = <FILE>;
			if ($data =~ /<h1 class="page-title">(.*)<\/h1>/) {
				my ($title, $date) = ($1,"");
				if ($data =~ /<meta name="Date" content="(.*?)"\/>/i) {
					$date = $1;
					$date =~ s/(\d?\d)\/(\d\d)\/(\d\d\d\d).*/$3.$1.$2/;
				}
				$filepath =~ /$site_root\/(.*).html/;
				$pages{$date}{$title} = "$1";
			}
		}
	}

	if ( scalar keys %pages > 0 ) {
		print "<ul class=\"archives\">\n";
		foreach my $date (sort { $b cmp $a} keys(%pages)) {
			foreach my $title (sort keys %{$pages{$date}}) {
				print "<li>$date: <a href=\"/$pages{$date}{$title}\">$title</a></li>\n";""
			}
		}
		print "</ul>\n";	
	}	
} elsif ($requested_url =~ /^\/?(\d\d\d\d)/) {
	# Print months in current year that have entries
	my $year = $1;
	local $/;

	my $content = "";

	my %months_with_entries = ();
	
	foreach my $filepath (glob("$site_root/$year/*/*.html")) {
		$filepath =~ /\d\d\d\d\/(\d\d)/;
		
		$months_with_entries{$1} = 1;
	}

	foreach (sort keys %months_with_entries) {
		my $month = $months[$_-1];
		$content .= "<li><a href=\"/$year/$_/\">$month $year Archives</a></li>\n";
	}


	if ($content ne "") {
		print qq{<ul>
$content
</ul>
};
	}
} elsif ($requested_url =~ /^\/?archives/) {
	my %pages = ();
	my $content = "";
	
	foreach my $filepath (glob("$site_root/*/*/*.html")) {
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
