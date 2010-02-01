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

use warnings;

use File::Find;
use Cwd 'abs_path';

local $/;

my $max_count = 15;

print "Content-type: text/html\n\n";

# Web root folder
my $search_path = $ENV{DOCUMENT_ROOT};

my %pages = ();

find(\&index_file, $search_path);

my $count = 0;
my $output = "";

foreach my $year (sort {$b cmp $a} keys %pages) {
	foreach my $month (sort {$b cmp $a}keys %{$pages{$year}}) {
		foreach my $day (sort {$b cmp $a}keys %{$pages{$year}{$month}}) {
			foreach my $filepath (sort {$b cmp $a}keys %{$pages{$year}{$month}{$day}}) {
				if ($count < $max_count) {
					my $title = $pages{$year}{$month}{$day}{$filepath};
					$filepath =~ s/^$search_path//;
					$filepath =~ s/\.html$//;
					$output .= qq{<li>$year.$month.$day: <a href="$filepath">$title</a></li>\n};
					$count++;
				}
			}
		}
	}
}

if ($output) {
	print qq{<h2>Latest Entries</h2>
<ul>
$output
</ul>
};
}

sub index_file {
	my $filepath = $File::Find::name;

	return if ($filepath =~ /index.html$/);

	if ($filepath =~ /$search_path\/(\d\d\d\d)\/(\d\d)\/.*\.html$/) {
		my $year = $1;
		my $month = $2;
		my $day = "";

		open (FILE, "<$filepath");
		my $data = <FILE>;
		close FILE;
		
		if ($data =~ /<meta name="Date" content="(.*?)"\/>/) {
			$date = $1;
			$date =~ s/(\d\d)\/(\d\d)\/(\d\d\d\d).*/$3.$1.$2/;
			$month = $1;
			$day = $2;
			$year = $3;
		}

		if ($data =~ /<h1 class="page-title">(.*)<\/h1>/) {
			my $title = $1;
			$pages{$year}{$month}{$day}{$filepath} = $title;
		}
	}
	
	
}