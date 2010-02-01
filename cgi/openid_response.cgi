#!/usr/bin/env perl

# Based on code in Net::OpenID::Consumer by Brad Fitzpatrick
#
# My changes Copyright (C) 2010  Fletcher T. Penney
#	<fletcher@fletcherpenney.net>
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
use Net::OpenID::Consumer;
use LWP::UserAgent;
use CGI;

my $cgi = CGI::new();
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

		# Successful authentication
		
		# Create an authentication cookie
		my $cookie = $cgi->cookie(
			-name=>'OpenID',
			-value=>$url,
			-expires=>'+4h',
			-path=>'/');
		
		# Fetch nickname or first name
		my $sreg = $vident->signed_extension_fields(
		        'http://openid.net/extensions/sreg/1.1',
		    );
		
		my $user = "";
		if ($sreg->{nickname}) {
			$user = $sreg->{nickname};
		} elsif ($sreg->{fullname}) {
			$user = $sreg->{fullname};
		}

		my $cookie2 = $cgi->cookie(
			-name=>'User',
			-value=>$user,
			-expires=>'+4h',
			-path=>'/');

		print $cgi->redirect (-cookie=>[$cookie,$cookie2], -location => "http://" . $ENV{SERVER_NAME} . "/" . $refer . "#leave-comment");
	},
	error => \&handle_errors,
);

if ($message ne "") {
	print $cgi->header(), $cgi->start_html();
	print "<h1>OpenID Login</h1>\n";
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
