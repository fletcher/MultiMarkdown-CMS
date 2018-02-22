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
use strict;

use FindBin qw( $RealBin );
use lib $RealBin;

use Net::OpenID::Consumer;
use LWP::UserAgent;
use CGI;
use POSIX;
use MultiMarkdownCMS;

my $cgi = CGI::new();
my $comment = $cgi->cookie("Comment");
my $user = $cgi->cookie("User");
my $timezone = -4;						# Configure as needed
my $debug = 0;							# Enables extra output for debugging


# Get commonly needed paths
my ($site_root, $requested_url, $document_url) 
	= MultiMarkdownCMS::getHostingPaths($0);

# Debugging aid
print qq{
	Site root directory: $site_root<br/>
	Request:  $requested_url<br/>
	Document: $document_url<br/>
} if $debug;


my $csr = Net::OpenID::Consumer->new (
	# The root of our URL.
	required_root => "http://$ENV{HTTP_HOST}/",
	# Our password.
	consumer_secret => 'enter your password here',
	# Where to get the information from.
	args  => $cgi,
);

# Start of HTML output
my $refer = $cgi->param('referer');

my $message = "";


$csr->handle_server_response (
	not_openid => sub {
		$message =  "That's not an OpenID message. Did you just type in the URL?";
	},
	setup_required => sub {
		my $setup_url = shift;
		$message = "You need to do something <a href='$setup_url'>here</a>.";
	},
	cancelled => sub {
		$message = 'You cancelled your login.';
	},
	verified => sub {
		my $vident = shift;
		my $url = $vident->url;

		# Successful authentication - accept the comment and addend
		
		my $local_root = $site_root;
		my $URI = "/" . $refer;
		$URI =~ s/(\.html)?$/.html/;
		$URI =~ s/$ENV{Base_URL}// if ($ENV{Base_URL} ne "");
		$URI =~ s/^\/?//;
		
		# This doesn't work, but worth a shot to trigger a refresh?
		system("touch $local_root/$URI");
		
		$URI =~ s/(\.html)?$/.comments/;

		my $filepath = "$local_root/$URI";
		
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
		$year = $year + 1900;
		$mon += 1;

		my $date = "";

		if (strftime ("%Z", localtime(time)) eq "UTC") {
			$date = strftime "%m/%d/%Y %H:%M:%S", localtime(time + ($timezone * 60 * 60));
		} else {
			$date = strftime "%m/%d/%Y %H:%M:%S", localtime(time);
		}
		open (FILE, ">> $filepath");
		print FILE "AUTHOR: $user\nURL: $url\nDATE: $date\nCOMMENT:\n";
		close FILE;
		
		# Protect against HTML by encoding "<"
		$comment =~ s/\</&lt;/g;
		
		open (MMD, "| ./MultiMarkdown.pl | ./SmartyPants.pl >> $filepath; echo \"\" >> $filepath; echo \"\" >> $filepath");
		print MMD $comment;
		close MMD;
		
		# Delete comment cookie
		
#		$message = "You are verified as '$url'.<br>";
#		$message .= "Comment: $comment<br>";
#		$message .= "Addend to $filepath<br>";


		print $cgi->redirect (-location => "http://" . $ENV{SERVER_NAME} . "/" . $refer . "#leave-comment");

	},
	error => \&handle_errors,
);

if ($message ne "") {
	print $cgi->header(), $cgi->start_html();
	print "<h1>Comment Submission</h1>\n";
	print $message;
	print $cgi->end_html();
	
}

exit 0;

# Handle errors, suggest possible causes of the error.

sub handle_errors
{
	my ($err) = @_;
	print $cgi->header(), $cgi->start_html();
	print "<h1>OpenID Login</h1>\n";
	print "<b>Error: $err</b>. \n";
	if ($err eq 'server_not_allowed') {
		print <<EOF;
You may have gone to an http: server and come back from an https:
server. This happens with "myopenid.com".
EOF
	} elsif ($err eq 'naive_verify_failed_return') {
		print 'Oops! Did you reload this page?';
	}
	print $cgi->end_html();
}
