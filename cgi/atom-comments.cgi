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
	title	=> "$host comments",
	link	=> "http://$host/",
	link    => { rel => 'self', href => "http://$host/atom-comments.xml", },
	author	=> 'Fletcher T. Penney',
);

local $/;

my $max_count = 25;

print "Content-type: text/html\n\n";

# Web root folder
my $search_path = "";

if ($ENV{DOCUMENT_ROOT}) {
	$search_path = $ENV{DOCUMENT_ROOT};
} else {
	$search_path = "/home/public";
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

	if ($filepath =~ /$search_path\/(\d\d\d\d)\/(\d\d)\/.*\.comments$/) {
		my $date = "";
		
		open (FILE, "<$filepath");
		my $data = <FILE>;
		close FILE;

		$filepath =~ s/\.comments$//;
		
		my $counter = 0;
		$data =~ s{
			AUTHOR:
			(.*?)
			(\n\n\n|\Z)
		}{
			my $comment = $1;
			$counter++;

			$comment =~ /^\s*(.*?)\n/m;		# First line is author
			my $author = $1;

			$comment =~ /URL:\s*(.*?)$/m;
			my $url = $1;

			$comment =~ /DATE:\s*(.*?)$/m;
			my $date = $1;
			$date =~ s/(\d\d)\/(\d\d)\/(\d\d\d\d).*?(\d\d:\d\d:\d\d).*/$3-$1-$2T$4-04:00/;

			$comment =~ /COMMENT:\s*(.*)$/s;
			my $body = $1;

			my $clean_path = $filepath;
			$clean_path =~ s/$search_path//;
			
			$pages{$date}{$filepath . "#comment-" . $counter} = "comment $counter on $clean_path";
			$pages{$date}{$filepath . "#comment-" . $counter}{'body'} = $body;
			
			"";
		}egsx;
		
	}
	
	
}