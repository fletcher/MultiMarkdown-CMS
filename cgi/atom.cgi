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

use XML::Atom::SimpleFeed;
use File::Find;
use File::Basename;
use Cwd 'abs_path';
use CGI;

my $host;
if ($ENV{HTTP_HOST}) {
	$host = $ENV{HTTP_HOST};
} else {
	$host = "fake.local";
}

my $feed = XML::Atom::SimpleFeed->new(
	title	=> "$host",
	link	=> "http://$host/",
	link    => { rel => 'self', href => "http://$host/atom.xml", },
	author	=> 'MultiMarkdown CMS',
);

local $/;

my $max_count = 25;

print "Content-type: text/html\n\n";

# Web root folder
my $search_path = "";

if ($ENV{DOCUMENT_ROOT}) {
	$search_path = $ENV{DOCUMENT_ROOT};
} else {
	my $me = $0;		# Where is this script located?
	$me = dirname($me);
	$me = abs_path($me);
	($search_path = $me) =~ s/\/cgi$//;
}

my %pages = ();

find(\&index_file, $search_path);

my $count = 0;


foreach my $date (sort {$b cmp $a} keys %pages) {
	foreach my $filepath (sort {$b cmp $a}keys %{$pages{$date}}) {
		if ($count < $max_count) {
			my $title = $pages{$date}{$filepath};
			my $content = $pages{$date}{$filepath}{body};
			$filepath =~ s/^$search_path//;

			$feed->add_entry(
				title	=> $title,
				link	=> "http://$host$filepath",
				updated => $date,
				content	=> $content,
			);

			$count++;
		}
	}
}

$feed->print;

sub index_file {
	my $filepath = $File::Find::name;

	return if ($filepath =~ /index.html$/);

	if ($filepath =~ /$search_path\/(\d\d\d\d)\/(\d\d)\/.*\.html$/) {
		my $date = "";
		
		open (FILE, "<$filepath");
		my $data = <FILE>;
		close FILE;

		if ($data =~ /<meta name="Date" content="(.*?)"\/>/) {
			$date = $1;
			$date =~ s/(\d\d)\/(\d\d)\/(\d\d\d\d).*?(\d\d:\d\d:\d\d).*/$3-$1-$2T$4-04:00/;
		}
		if ($data =~ /<h1 class="page-title">(.*)<\/h1>/) {
			my $title = $1;
			$pages{$date}{$filepath} = $title;
		}
		if ($data =~ /<body>(.*)<\/body>/s) {
			my $body = $1;
			$pages{$date}{$filepath}{'body'} = $body;
		}
		
	}
	
	
}