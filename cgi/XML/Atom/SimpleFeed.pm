#!/usr/bin/perl
require 5.008001; # no good Unicode support? you lose

package XML::Atom::SimpleFeed;

$VERSION = "0.86";

use warnings FATAL => 'all';
use strict;

use Carp;
use Encode ();
use POSIX ();

sub ATOM_NS           () { 'http://www.w3.org/2005/Atom' }
sub XHTML_NS          () { 'http://www.w3.org/1999/xhtml' }
sub PREAMBLE          () { qq(<?xml version="1.0" encoding="us-ascii"?>\n) }
sub W3C_DATETIME      () { '%Y-%m-%dT%H:%M:%SZ' }
sub DEFAULT_GENERATOR () { {
	uri     => 'http://search.cpan.org/dist/' . join( '-', split /::/, __PACKAGE__ ) . '/',
	version => __PACKAGE__->VERSION,
	name    => __PACKAGE__,
} }

####################################################################
# superminimal XML writer
# 

my %XML_ESC = (
	"\xA" => '&#10;',
	"\xD" => '&#13;',
	'"'   => '&#34;',
	'&'   => '&#38;',
	"'"   => '&#39;',
	'<'   => '&lt;',
	'>'   => '&gt;',
);

sub xml_cref { Encode::encode 'us-ascii', $_[ 0 ], Encode::HTMLCREF }

sub xml_escape {
	$_[ 0 ] =~ s{ ( [<>&'"] ) }{ $XML_ESC{ $1 } }gex;
	goto &xml_cref;
}

sub xml_attr_escape {
	$_[ 0 ] =~ s{ ( [\x0A\x0D<>&'"] ) }{ $XML_ESC{ $1 } }gex;
	goto &xml_cref;
}

sub xml_cdata_flatten {
	for ( $_[0] ) {
		my $cdata_content;
		s{<!\[CDATA\[(.*?)]]>}{ xml_escape $cdata_content = $1 }ge;
		croak 'Incomplete CDATA section' if -1 < index $_, '<![CDATA[';
		return $_;
	}
}

sub xml_string { xml_cref xml_cdata_flatten $_[ 0 ] }

sub xml_tag {
	my $name = shift;
	my $attr = '';
	if( ref $name eq 'ARRAY' ) {
		my $i = 1;
		while( $i < @$name ) {
			$attr .= ' ' . $name->[ $i ] . '="' . xml_attr_escape( $name->[ $i + 1 ] ) . '"';
			$i += 2;
		}
		$name = $name->[ 0 ];
	}
	@_ ? join( '', "<$name$attr>", @_, "</$name>" ) : "<$name$attr/>";
}

####################################################################
# misc utility functions
#

sub natural_enum {
	my @and;
	unshift @and, pop @_ if @_;
	unshift @and, join ', ', @_ if @_;
	join ' and ', @and;
}

sub permalink {
	my ( $link_arg ) = ( @_ );
	if( ref $link_arg ne 'HASH' ) {
		return $link_arg;
	}
	elsif( not exists $link_arg->{ rel } or $link_arg->{ rel } eq 'alternate' ) {
		return $link_arg->{ href };
	}
	return;
}

####################################################################
# actual implementation of RFC 4287
#

sub simple_construct {
	my ( $name, $content ) = @_;
	xml_tag $name, xml_escape $content;
}

sub person_construct {
	my ( $name, $arg ) = @_;

	my $prop = 'HASH' ne ref $arg ? { name => $arg } : $arg;

	croak "name required for $name element" if not exists $prop->{ name };

	return xml_tag $name => (
		map { xml_tag $_ => xml_escape $prop->{ $_ } }
		grep { exists $prop->{ $_ } }
		qw( name email uri )
	);
}

sub text_construct {
	my ( $name, $arg ) = @_;

	my ( $type, $content );

	if( ref $arg eq 'HASH' ) {
		# FIXME doesn't support @src attribute for $name eq 'content' yet

		$type = exists $arg->{ type } ? $arg->{ type } : 'html';

		croak "content required for $name element" unless exists $arg->{ content };

		# a lof of the effort that follows is to omit the type attribute whenever possible
		# 
		if( $type eq 'xhtml' ) {
			$content = xml_string $arg->{ content };

			if( $content !~ /</ ) { # FIXME does this cover all cases correctly?
				$type = 'text';
				$content =~ s/[\n\t]+/ /g;
			}
			else {
				$content = xml_tag [ div => xmlns => XHTML_NS ], $content;
			}
		}
		elsif( $type eq 'html' or $type eq 'text' ) {
			$content = xml_escape $arg->{ content };
		}
		else {
			croak "type '$type' not allowed in $name element"
				if $name ne 'content';

			# FIXME non-XML/text media types must be base64 encoded!
			$content = xml_string $arg->{ content };
		}
	}
	else {
		$type = 'html';
		$content = xml_escape $arg;
	}

	if( $type eq 'html' and $content !~ /&/ ) {
		$type = 'text';
		$content =~ s/[\n\t]+/ /g;
	}

	return xml_tag [ $name => $type ne 'text' ? ( type => $type ) : () ], $content;
}

sub empty_tag_maker {
	my ( $required_attr, @optional_attr ) = @_;

	sub {
		my ( $name, $arg ) = @_;

		if ( $name eq 'link' ) {
			# HACK: no other simple tag needs similar features so it's easiest
			# to hack them in here instead of providing an indirection

			# croak "link '$arg->{ href }' is not a valid URI"
			# 	if $arg->{ href } XXX TODO

			# omit atom:link/@rel value when possible
			delete $arg->{ rel }
				if ref $arg eq 'HASH'
				and exists $arg->{ rel }
				and $arg->{ rel } eq 'alternate';
		}

		if( ref $arg eq 'HASH' ) {
			croak "$required_attr required for $name element" if not exists $arg->{ $required_attr };
			my @attr = map { $_ => $arg->{ $_ } } grep exists $arg->{ $_ }, $required_attr, @optional_attr;
			xml_tag [ $name => @attr ];
		}
		else {
			xml_tag [ $name => $required_attr => $arg ];
		}
	}
}

# tag makers are called with the name of the tag they're supposed to handle as the first parameter
my %make_tag = (
	icon        => \&simple_construct,
	id          => \&simple_construct,
	logo        => \&simple_construct,
	published   => \&simple_construct,
	updated     => \&simple_construct,
	author      => \&person_construct,
	contributor => \&person_construct,
	title       => \&text_construct,
	subtitle    => \&text_construct,
	rights      => \&text_construct,
	summary     => \&text_construct,
	content     => \&text_construct,
	link        => empty_tag_maker( qw( href rel type title hreflang length ) ),
	category    => empty_tag_maker( qw( term scheme label ) ),
	generator => sub {
		my ( $name, $arg ) = @_;
		if( ref $arg eq 'HASH' ) {
			croak 'name required for generator element' if not exists $arg->{ name };
			my $content = delete $arg->{ name };
			xml_tag [ generator => map +( $_ => $arg->{ $_ } ), grep exists $arg->{ $_ }, qw( uri version ) ], xml_escape( $content );
		}
		else {
			xml_tag generator => xml_escape( $arg );
		}
	},
);

sub container_content {
	my ( $name, %arg ) = @_;

	my ( $elements, $required, $optional, $singular, $deprecation, $callback ) =
		@arg{ qw( elements required optional singular deprecate callback ) };

	my ( $content, %permission, %count, $permalink );

	undef @permission{ @$required, @$optional }; # populate

	while( my ( $elem, $arg ) = splice @$elements, 0, 2 ) {
		if( exists $permission{ $elem } ) {
			$content .= $make_tag{ $elem }->( $elem, $arg );
			++$count{ $elem };
		}
		else {
			croak "Unknown element $elem";
		}

		if( $elem eq 'link' and defined ( my $alt = permalink $arg ) ) {
			$permalink = $alt unless $count{ 'alternate link' }++;
		}

		if( exists $callback->{ $elem } ) { $callback->{ $elem }->( $arg ) }

		if( not @$elements ) { # end of input?
			# we would normally fall off the bottom of the loop now;
			# before that happens, it's time to defaultify stuff and
			# put it in the input so we will keep going for a little longer
			if( not $count{ id } and defined $permalink ) {
				carp 'Falling back to alternate link as id';
				push @$elements, id => $permalink;
			}
			if( not $count{ updated } ) {
				push @$elements, updated => $arg{ default_upd };
			}
		}
	}

	my @error;

	my @missing = grep { not exists $count{ $_ } } @$required;
	my @toomany = grep { ( $count{ $_ } || 0 ) > 1 } 'alternate link', @$singular;

	push @error, 'requires at least one ' . natural_enum( @missing ) . ' element' if @missing;
	push @error, 'must have no more than one ' . natural_enum( @toomany ) . ' element' if @toomany;

	croak $name, ' ', join ' and ', @error if @error;

	return $content;
}

####################################################################
# implementation of published interface and rest of RFC 4287
#

sub XML::Atom::SimpleFeed::new {
	my $self = bless {}, shift;
	my $arg = ( @_ and 'HASH' eq ref $_[0] ) ? shift : {};

	$self->{ do_add_generator } = 1;

	$self->feed( @_ ) if @_; # support old-style invocation

	return $self;
}

sub XML::Atom::SimpleFeed::feed {
	my $self = shift;

	$self->{ meta } = container_content feed => (
		elements    => \@_,
		required    => [ qw( id title updated ) ],
		optional    => [ qw( author category contributor generator icon logo link rights subtitle ) ],
		singular    => [ qw( generator icon logo id rights subtitle title updated ) ],
		callback    => {
			author    => sub { $self->{ have_default_author } = 1 },
			updated   => sub { $self->{ global_updated } = $_[ 0 ] },
			generator => sub { $self->{ do_add_generator } = 0 },
		},
		default_upd => POSIX::strftime( W3C_DATETIME, gmtime ),
	);

	return $self;
}

sub XML::Atom::SimpleFeed::add_entry  {
	my $self = shift;

	my @required = qw( id title updated );
	my @optional = qw( category content contributor link published rights summary );

	push @{ $self->{ have_default_author } ? \@optional : \@required }, 'author';

	# FIXME
	# 
	# o  atom:entry elements that contain no child atom:content element
	#    MUST contain at least one atom:link element with a rel attribute
	#    value of "alternate".
	# 
	# o  atom:entry elements MUST contain an atom:summary element in either
	#    of the following cases:
	#    *  the atom:entry contains an atom:content that has a "src"
	#       attribute (and is thus empty).
	#    *  the atom:entry contains content that is encoded in Base64;
	#       i.e., the "type" attribute of atom:content is a MIME media type
	#       [MIMEREG], but is not an XML media type [RFC3023], does not
	#       begin with "text/", and does not end with "/xml" or "+xml".

	push @{ $self->{ entries } }, xml_tag entry => container_content entry => (
		elements    => \@_,
		required    => \@required,
		optional    => \@optional,
		singular    => [ qw( content id published rights summary ) ],
		default_upd => $self->{ global_updated },
	);

	return $self;
}

sub XML::Atom::SimpleFeed::no_generator {
	my $self = shift;
	$self->{ do_add_generator } = 0;
	return $self;
}

sub XML::Atom::SimpleFeed::as_string {
	my $self = shift;
	if( $self->{ do_add_generator } ) {
		$self->{ meta } .= $make_tag{ generator }->( generator => DEFAULT_GENERATOR );
		$self->{ do_add_generator } = 0;
	}
	PREAMBLE . xml_tag [ feed => xmlns => ATOM_NS ], $self->{ meta }, @{ $self->{ entries } };
}

sub XML::Atom::SimpleFeed::print {
	my $self = shift;
	my ( $handle ) = @_;
	local $, = local $\ = '';
	defined $handle ? print $handle $self->as_string : print $self->as_string;
}

sub XML::Atom::SimpleFeed::save_file { croak q{no longer supported, use 'print' instead and pass in a filehandle} }

! ! 'Funky and proud of it.';

__END__

=head1 NAME

XML::Atom::SimpleFeed - No-fuss generation of Atom syndication feeds

=head1 VERSION

This document describes XML::Atom::SimpleFeed version 0.84

=head1 SYNOPSIS

 use XML::Atom::SimpleFeed;
 
 my $feed = XML::Atom::SimpleFeed->new(
     title   => 'Example Feed',
     link    => 'http://example.org/',
     link    => { rel => 'self', href => 'http://example.org/atom', },
     updated => '2003-12-13T18:30:02Z',
     author  => 'John Doe',
     id      => 'urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6',
 );
 
 $feed->add_entry(
     title     => 'Atom-Powered Robots Run Amok',
     link      => 'http://example.org/2003/12/13/atom03',
     id        => 'urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a',
     summary   => 'Some text.',
     updated   => '2003-12-13T18:30:02Z',
     category  => 'Atom',
     category  => 'Miscellaneous',
 );
 
 $feed->print;

=head1 DESCRIPTION

This module provides a minimal API for generating Atom syndication feeds quickly and easily. It supports all aspects of the Atom format, but has no provisions for generating feeds with extension elements.

You can supply strings for most things, and the module will provide useful defaults. When you want more control, you can provide data structures, as documented, to specify more particulars.

=head1 INTERFACE

=head2 C<new>

XML::Atom::SimpleFeed instances are created by the C<new> constructor, which takes a list of key-value pairs as parameters. The keys are used to create the corresponding L<"Atom elements"|/ATOM ELEMENTS>. The following elements are available:

=over

=item * L</C<id>> (I<omissible>)

=item * L</C<link>> (I<omissible>, multiple)

=item * L</C<title>> (B<required>)

=item * L</C<author>> (optional, multiple)

=item * L</C<category>> (optional, multiple)

=item * L</C<contributor>> (optional, multiple)

=item * L</C<generator>> (optional)

=item * L</C<icon>> (optional)

=item * L</C<logo>> (optional)

=item * L</C<rights>> (optional)

=item * L</C<subtitle>> (optional)

=item * L</C<updated>> (optional)

=back

To specify multiple instances of an element that may be given multiple times, simply list multiple key-value pairs with the same key.

=head2 C<add_entry>

This method adds an entry into the Atom feed. It takes a list of key-value pairs as parameters. The keys are used to create the corresponding L<"Atom Elements"|/ATOM ELEMENTS>. The following elements are available:

=over

=item * L</C<author>> (B<required> unless there is a feed-level author, multiple)

=item * L</C<id>> (I<omissible>)

=item * L</C<link>> (B<required>, multiple)

=item * L</C<title>> (B<required>)

=item * L</C<category>> (optional, multiple)

=item * L</C<content>> (optional)

=item * L</C<contributor>> (optional, multiple)

=item * L</C<published>> (optional)

=item * L</C<rights>> (optional)

=item * L</C<summary>> (optional)

=item * L</C<updated>> (optional)

=back

To specify multiple instances of an element that may be given multiple times, simply list multiple key-value pairs with the same key.

=head2 C<no_generator>

Suppresses the output of a default C<generator> element. It is not necessary to call this method if you supply a custom C<generator> element.

=head2 C<as_string>

Returns the XML representation of the feed as a string.

=head2 C<print>

Outputs the XML representation of the feed to a handle which should be passed as a parameter. Defaults to C<STDOUT> if you do not pass a handle.

=head1 ATOM ELEMENTS

=head2 C<author>

A L</Person Construct> denoting the author of the feed or entry.

If you supply at least one author for the feed, you can omit this information from entries; the feed's author(s) will be assumed as the author(s) for those entries. If you do not supply any author for the feed, you B<must> supply one for each entry.


=head2 C<category>

One or more categories that apply to the feed or entry. You can supply a string which will be used as the category term. The full range of details that can be provided by passing a hash instead of a string is as follows:

=over

=item C<term> (B<required>)

The category term.

=item C<scheme> (optional)

A URI that identifies a categorization scheme.

It is common to provide the base of some kind of by-category URL here. F.ex., if the weblog C<http://www.example.com/blog/> can be browsed by category using URLs such as C<http://www.example.com/blog/category/personal>, you would supply C<http://www.example.com/blog/category/> as the scheme and, in that case, C<personal> as the term.

=item C<label> (optional)

A human-readable version of the term.

=back


=head2 C<content>

The actual, honest-to-goodness, body of the entry. This is like a L</Text Construct>, with a couple of extras.

In addition to the C<type> values of a L</Text Construct>, you can also supply any MIME Type (except multipart types, which the Atom format specification forbids). If you specify a C<text/*> type, the same rules apply as for C<text>. If you pass a C<*/xml> or C<*/*+xml> type, the same rules apply as for C<xhtml> (except in that case there is no wrapper C<< <div> >> element). Any other type will be transported as Base64-encoded binary.

XXX Furthermore, you can supply a C<src> key in place of the C<content> key. In that case, the value of the C<src> key should be a URL denoting the actual location of the content. FIXME This is not currently supported. XXX


=head2 C<contributor>

A L</Person Construct> denoting a contributor to the feed or entry.


=head2 C<generator>

The software used to generate the feed. Can be supplied as a string, or a hash with C<uri>, C<version> and C<name> keys. Defaults to reporting XML::Atom::SimpleFeed as the generator, which can be calling C<no_generator>.


=head2 C<icon>

The URI of a small image that should have the same height and width.


=head2 C<id>

A URI that is a permanent, globally unique identifier for the feed or entry that B<MUST NEVER CHANGE>.

You are encouraged to generate a UUID using L<Data::UUID> for the purpose of identifying entries/feeds. It should be stored alongside the resource corresponding to the entry/feed, f.ex. in a column of the article table of your weblog database. To use it as an identifier in the entry/feed, use the C<urn:uuid:########-####-####-####-############> URI form.

If you do not specify an ID, the permalink will be used instead. This is unwise, as permalinks do unfortunately occasionally change. B<It is your responsibility to ensure that the permalink NEVER CHANGES.>


=head2 C<link>

A link element. You can either supply a bare string as the parameter, which will be used as the permalink URI, or a hash. The permalink for a feed is generally a browser-viewable weblog, upload browser, search engine results page or similar web page; for an entry, it is generally a browser-viewable article, upload details page, search result or similar web page. This URI I<should> be unique. If you supply a hash, you can provide the following range of details in the given hash keys:

=over

=item C<rel> (optional)

The link relationship. If omitted, defaults to C<alternate> (note that you can only have one alternate link per feed/entry). Other permissible values are C<related>, C<self>, C<enclosure> and C<via>, as well as any URI.

=item C<href> (B<required> URL)

Where the link points to.

=item C<type> (optional)

An advisory media type that provides a hint about the type of the resource pointed to by the link.

=item C<hreflang> (optional)

The language of the resource pointed to by the link, an an RFC3066 language tag.

=item C<title> (optional)

Human-readable information about the link.

=item C<length> (optional)

A hint about the content length in bytes of the resource pointed to by the link.

=back


=head2 C<logo>

The URI of an image that should be twice as wide as it is high.


=head2 C<published>

A L</Date Construct> denoting the moment in time when the entry was first published. This should never change.


=head2 C<rights>

A L</Text Construct> containing a human-readable statement of legal rights for the content of the feed or entry. This is not intended for machine processing.


=head2 C<subtitle>

A L</Text Construct> containing an optional additional description of the feed.


=head2 C<summary>

A L</Text Construct> giving a short summary of the entry.


=head2 C<title>

A L</Text Construct> containing the title of the feed or entry.


=head2 C<updated>

A L</Date Construct> denoting the moment in time when the feed or entry was last updated. Defaults to the current date and time if omitted.

In entries, you can use this element to signal I<significant> changes at your discretion.



=head1 COMMON ATOM CONSTRUCTS

A number of Atom elements share a common structure. The following sections outline the data you can (or must) pass in each case.

=head2 Date Construct

A string denoting a date and time in W3CDTF format. You can generate those using something like

 use POSIX qw( strftime );
 my $now = strftime '%Y-%m-%dT%H:%M:%SZ', gmtime;

=head2 Person Construct

You can supply a string to Person Construct parameters, which will be used as the name of the person. The full range of details that can be provided by passing a hash instead of a string is as follows:

=over

=item C<name> (B<required>)

The name of the person.

=item C<email> (optional)

The person's email address.

=item C<uri> (optional)

A URI to distinguish this person. This would usually be a homepage, but need not actually be a dereferencable URL.

=back

=head2 Text Construct

You can supply a string to Text Construct parameters, which will be used as the HTML content of the element.

FIXME details, text/html/xhtml


=head1 SEE ALSO

=over

=item * Atom Enabled (L<http://www.atomenabled.org/>)

=item * W3CDTF Spec (L<http://www.w3.org/TR/NOTE-datetime>)

=item * RFC 3066 (L<http://rfc.net/rfc3066.html>)

=item * L<XML::Atom::Syndication>

=item * L<XML::Feed>

=item * http://groups.yahoo.com/group/atomic-perl/

=back


=head1 BUGS AND LIMITATIONS

In C<content> elements, the C<src> attribute cannot be used, and non-XML or -text media types do not get Base64-encoded automatically. This is a bug.

There are practically no tests. This is a bug.

Support for C<xml:lang> and C<xml:base> is completely absent. This is a bug and should be partially addressed in a future version. There are however no plans to allow these attributes on arbitrary elements.

There are no plans to ever support generating feeds with arbitrary extensions, although support for specific extensions may or may not be added in the future.

The C<source> element is not and may never be supported.

Nothing is done to ensure that text constructs with type C<xhtml> and entry contents using either that or an XML media type are well-formed. So far, this is by design. You should strongly consider using an XML writer if you want to include content with such types in your feed.

If you find bugs or you have feature requests, please report them to L<mailto:bug-xml-atom-simplefeed@rt.cpan.org>, or through the web interface at L<http://rt.cpan.org>.


=head1 AUTHOR

Aristotle Pagaltzis, L<mailto:pagaltzis@gmx.de>

API designed largely by H. Wade Minter.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005-2006, Aristotle Pagaltzis. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
