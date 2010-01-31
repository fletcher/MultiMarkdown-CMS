package Net::OpenID::Consumer::Lite;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.02';
use LWP::UserAgent;
use Carp ();

my $TIMEOUT = 4;
our $IGNORE_SSL_ERROR = 0;

sub _ua {
    my $agent = "Net::OpenID::Consumer::Lite/$Net::OpenID::Consumer::Lite::VERSION";
    LWP::UserAgent->new(
        agent        => $agent,
        timeout      => $TIMEOUT,
        max_redirect => 0,
    );
}

sub _get {
    my $url = shift;
    my $ua = _ua();
    my $res = $ua->get($url);
    unless ($IGNORE_SSL_ERROR) {
        if ( my $warnings = $res->header('Client-SSL-Warning') ) {
            Carp::croak("invalid ssl? ${url}, ${warnings}");
        }
    }
    unless ($res->is_success) {
        Carp::croak("cannot get $url : @{[ $res->status_line ]}");
    }
    $res;
}

sub check_url {
    my ($class, $server_url, $return_to, $extensions) = (shift, shift, shift, shift);
    Carp::croak("missing params")      unless $return_to;
    Carp::croak("this module supports only https: $server_url") unless $server_url =~ /^https/;

    my $url = URI->new($server_url);
    my %args = (
        'openid.mode' => 'checkid_immediate',
        'openid.return_to' => $return_to,
    );
    if ($extensions) {
        my $i = 1;
        while (my ($ns, $args) = each %$extensions) {
            my $ext_alias = "e$i";
            $args{"openid.ns.$ext_alias"} = $ns;
            while (my ($key, $val) = each %$args) {
                $args{"openid.${ext_alias}.${key}"} = $val;
            }
            $i++;
        }
    }
    $url->query_form(%args);
    return $url->as_string;
}

sub _check_authentication {
    my ($class, $request) = @_;
    my $url = do {
        $request->{'openid.mode'} = 'check_authentication';
        my $request_url = URI->new($request->{'openid.op_endpoint'});
        $request_url->query_form(%$request);
        $request_url;
    };
    my $res = _get($url);
    $res->is_success() or die "cannot load $url";
    my $content = $res->content;
    return _parse_keyvalue($content)->{is_valid} ? 1 : 0;
}

sub handle_server_response {
    my $class = shift;
    my $request = shift;
    my %callbacks_in = @_;
    my %callbacks = ();

    for my $cb (qw(not_openid setup_required cancelled verified error)) {
        $callbacks{$cb} = delete( $callbacks_in{$cb} )
            || sub { Carp::croak( "No " . $cb . " callback" ) };
    }

    my $mode = $request->{'openid.mode'};
    unless ($mode) {
        return $callbacks{not_openid}->();
    }

    if ($mode eq 'cancel') {
        return $callbacks{cancelled}->();
    }

    if (my $url = $request->{'openid.user_setup_url'}) {
        return $callbacks{'setup_required'}->($url);
    }

    if ($class->_check_authentication($request)) {
        my $vident;
        for my $key (split /,/, $request->{'openid.signed'}) {
            $vident->{$key} = $request->{"openid.$key"};
        }
        return $callbacks{'verified'}->($vident);
    } else {
        return $callbacks{'error'}->();
    }
}

sub _parse_keyvalue {
    my $reply = shift;
    my %ret;
    $reply =~ s/\r//g;
    foreach ( split /\n/, $reply ) {
        next unless /^(\S+?):(.*)/;
        $ret{$1} = $2;
    }
    return \%ret;
}


1;
__END__

=encoding utf8

=head1 NAME

Net::OpenID::Consumer::Lite - OpenID consumer library for minimalist

=head1 SYNOPSIS

    use Net::OpenID::Consumer::Lite;
    my $csr = Net::OpenID::Consumer::Lite->new();

    # get check url
    my $check_url = Net::OpenID::Consumer::Lite->check_url(
        'https://mixi.jp/openid_server.pl',   # OpenID server url
        'http://example.com/back_to_here',    # return url
        {
            "http://openid.net/extensions/sreg/1.1" => { required => join( ",", qw/email nickname/ ) }
        }, # extensions(optional)
    );

    # handle response of OP
    Net::OpenID::Consumer::Lite->handle_server_response(
        $request => (
            not_openid => sub {
                die "Not an OpenID message";
            },
            setup_required => sub {
                my $setup_url = shift;
                # Redirect the user to $setup_url
            },
            cancelled => sub {
                # Do something appropriate when the user hits "cancel" at the OP
            },
            verified => sub {
                my $vident = shift;
                # Do something with the VerifiedIdentity object $vident
            },
            error => sub {
                my $err = shift;
                die($err);
            },
        )
    );

=head1 DESCRIPTION

Net::OpenID::Consumer::Lite is limited version of OpenID consumer library.
This module works fast.This module works well on rental server/CGI.

This module depend to L<LWP::UserAgent>, (L<Net::SSL>|L<IO::Socket::SSL>) and L<URI>.
This module doesn't depend to L<Crypt::DH>!!

=head1 LIMITATION

    This module supports OpenID 2.0 only.
    This module supports SSL OPs only.
    This module doesn't care the XRDS Location. Please pass me the real OpenID server path.

=head1 How to solve SSL Certifications Error

If L<Crypt::SSLeay> or L<Net::SSLeay> says "Peer certificate not verified" or other error messages,
please see the manual of your SSL libraries =) This is SSL library's problem.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

L<Net::OpenID::Consumer>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
