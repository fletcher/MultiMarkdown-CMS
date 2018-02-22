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

use strict;
use warnings;

use FindBin qw( $RealBin );
use lib $RealBin;

use IO::String;
use CGI;
use MultiMarkdownCMS;


my $cgi = CGI::new();
my $debug = 0;			# Enables extra output for debugging


print "Content-type: text/html\n\n";

print "<div class = \"comments\">
<h2>Comments</h2>
";


# Get commonly needed paths
my ($site_root, $requested_url, $document_url) 
	= MultiMarkdownCMS::getHostingPaths($0);

# Debugging aid
print qq{
	Site root directory: $site_root<br/>
	Request:  $requested_url<br/>
	Document: $document_url<br/>
} if $debug;


(my $filepath = $site_root . $document_url) =~ s/(\.html)?$/.comments/;


my @months = qw(January February March April May June July August
	September October November December);

if (-f $filepath) {
	local $/;
	open(FILE, "<$filepath");
	my $data = <FILE>;
	close FILE;
	my $count = 0;
	
	$data =~ s{
		AUTHOR:
		(.*?)
		(\n\n\n|\Z)
	}{
		my $comment = $1;
		$count++;
		
		$comment =~ /^\s*(.*?)\n/m;		# First line is author
		my $author = $1;
		
		$comment =~ /URL:\s*(.*?)$/m;
		my $url = $1;

		$comment =~ /DATE:\s*(.*?)$/m;
		my $date = $1;

		$comment =~ /COMMENT:\s*(.*)$/s;
		my $body = $1;
		
		$date =~ s/(\d\d)\/0?(\d+)\//$months[$1-1] $2,/;

		qq{<div class="comment" id="comment-$count">
<div class="comment-byline">By <a href="$url">$author</a>
on <a class="comment-permalink" href="http://$ENV{HTTP_HOST}$ENV{DOCUMENT_URI}#comment-$count">$date</a>
</div>
<div class="comment-content">
$body
</div></div>

};
	}egsx;

	print $data;
}

print qq{
<h2 id="leave-comment">Leave a comment</h2>
<div id="commenter-greeting">
	<script>
		writeCommenterGreeting();
	</script>
</div>

</div>
};