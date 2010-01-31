#!/usr/bin/env perl

#use strict;
use warnings;

use XML::Atom::SimpleFeed;
use File::Find;
use Cwd 'abs_path';
use CGI;

my $host;
if ($ENV{HTTP_HOST}) {
	$host = $ENV{HTTP_HOST};
} else {
	$host = "mmd.local";
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
	$search_path = "/Users/fletcher/Sites/mmd_static";
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