#!/usr/bin/env perl
use warnings;
use strict;
use Net::OpenID::Consumer;
use LWP::UserAgent;
use CGI;
use CGI::Carp 'fatalsToBrowser';
my $cgi = CGI::new();
my $openid = $cgi->cookie("OpenID");
my $comment = $cgi->param("text");
my $user = $cgi->param("user");

# Do a quickie check of the input
fail ('No OpenID')  if ! $openid;
fail ('Bad OpenID') if $openid =~ /[^a-z0-9\._:\/-]/i;

# Workaround for a known problem with myopenid. Change "http" to "https".
$openid =~ s@(^http://|^(?!https))@https://@ if $openid =~ /myopenid/;

my $csr = Net::OpenID::Consumer->new (
	# The user agent which sends the openid off to the server.
	ua    => LWP::UserAgent->new,
	# Who we are.
	required_root => "http://$ENV{HTTP_HOST}/",
	# Our password.
	consumer_secret => 'enter your password here',
);

my $claimed_id = $csr->claimed_identity($openid);

if ($claimed_id) {
	my $prior_page = "$ENV{HTTP_REFERER}";
	$prior_page =~ s/^https?:\/\/.*?\///;
	
	$claimed_id->set_extension_args(
		'http://openid.net/extensions/sreg/1.1',
		{
			optional => 'email,fullname,nickname',
			policy_url => 'http://example.com/privacypolicy.html',
		},
	);
	
	my $check_url = $claimed_id->check_url (
		# The place we go back to.
		return_to  => "http://$ENV{HTTP_HOST}/cgi/accept_comment.cgi?referer=$prior_page;",
		# Having this simplifies the login process.
		trust_root => "http://$ENV{HTTP_HOST}/",
		delayed_return  => 1,
	);
	
	# Automatically redirect the user to the endpoint.
	my $cookie1 = $cgi->cookie(
		-name=>'Comment',
		-value=>$comment,
		-expires=>'+1h',
		-path=>'/');

	my $cookie2 = $cgi->cookie(
		-name=>'User',
		-value=>$user,
		-path=>'/');

	print $cgi->redirect (-cookie=>[$cookie1,$cookie2], -location => $check_url);
} else {
	fail ("claimed_identity for '$openid' failed: ".$csr->errcode());
}

exit 0;

# Simple error handler

sub fail
{
    my ($message) = @_;
    print $cgi->header, $cgi->start_html, $message, $cgi->end_html;
    exit 0;
}
