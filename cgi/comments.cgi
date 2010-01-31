#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use File::Path;
use Cwd 'abs_path';
use IO::String;
use CGI;

my $cgi = CGI::new();

print "Content-type: text/html\n\n";

print "<div class = \"comments\">
<h2>Comments</h2>
";

(my $filepath = $ENV{DOCUMENT_ROOT} . $ENV{DOCUMENT_URI}) =~ s/(\.html)?$/.comments/;

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
	<script type="text/javascript">
		writeCommenterGreeting();
	</script>
</div>

</div>
};