package Lingua::Stem::Gl;

# $RCSfile: De.pm,v $ $Revision: 1.4 $ $Date: 1999/06/24 23:33:37 $ $Author: snowhare $

=head1 NAME

Lingua::Stem::Gl - Stemming algorithm for Galacian

=head1 SYNOPSIS

    use Lingua::Stem::Gl;
    my $stems   = Lingua::Stem::Gl::stem({ -words => $word_list_reference,
                                          -locale => 'gl',
                                      -exceptions => $exceptions_hash,
                                     });

=head1 DESCRIPTION

This routine applies a stemming algorithm to a passed anon array of Galician words,
returning the stemmed words as an anon array.

It is a 'convienence' wrapper for 'Lingua::Stemmer::GL' that provides
a standardized interface and caching.

=head1 CHANGES

1.02 2004.04.26 - Documenation fix

1.01 2003.09.28 - Documentation fix

1.00 2003.04.05 - Initial release

=cut

#######################################################################
# Initialization
#######################################################################

use strict;

use Lingua::GL::Stemmer;

use Exporter;
use Carp;
use vars qw (@ISA @EXPORT_OK @EXPORT %EXPORT_TAGS $VERSION);
BEGIN {
    @ISA         = qw (Exporter);
    @EXPORT      = ();
    @EXPORT_OK   = qw (stem clear_stem_cache stem_caching);
    %EXPORT_TAGS = ();
}
$VERSION = "1.02";

my $Stem_Caching  = 0;
my $Stem_Cache    = {};

=head1 METHODS

=cut

#######################################################################

=over 4

=item stem({ -words => \@words, -locale => 'gl', -exceptions => \%exceptions });

Stems a list of passed words using the rules of Galican. Returns
an anonymous list reference to the stemmed words.

Example:

  my $stemmed_words = Lingua::Stem::Gl::stem({ -words => \@words,
                                              -locale => 'gl',
                                          -exceptions => \%exceptions,
                          });

=back

=cut

sub stem {
    return [] if ($#_ == -1);
    my $parm_ref;
    if (ref $_[0]) {
        $parm_ref = shift;
    } else {
        $parm_ref = { @_ };
    }
    
    my $words      = [];
    my $locale     = 'gl';
    my $exceptions = {};
    foreach (keys %$parm_ref) {
        my $key = lc ($_);
        if ($key eq '-words') {
            @$words = @{$parm_ref->{$key}};
        } elsif ($key eq '-exceptions') {
            $exceptions = $parm_ref->{$key};
        } elsif ($key eq '-locale') {
            $locale = $parm_ref->{$key};
        } else {
            croak (__PACKAGE__ . "::stem() - Unknown parameter '$key' with value '$parm_ref->{$key}'\n");
        }
    }
  
    local $_;
    foreach (@$words) {

        # Check against exceptions list
        if (exists $exceptions->{$_}) {
			$_ = $exceptions->{$_};
			next;
		}

        # Check against cache of stemmed words
        my $original_word = $_;
        if ($Stem_Caching && exists $Stem_Cache->{$original_word}) {
            $_ = $Stem_Cache->{$original_word}; 
            next;
        }

        ($_) = Lingua::GL::Stemmer::stem("$_");
        $Stem_Cache->{$original_word} = $_ if $Stem_Caching;
    }
    $Stem_Cache = {} if ($Stem_Caching < 2);
    
    return $words;
}

##############################################################

=over 4

=item stem_caching({ -level => 0|1|2 });

Sets the level of stem caching.

'0' means 'no caching'. This is the default level.

'1' means 'cache per run'. This caches stemming results during a single
    call to 'stem'.

'2' means 'cache indefinitely'. This caches stemming results until
    either the process exits or the 'clear_stem_cache' method is called.

=back

=cut

sub stem_caching {
    my $parm_ref;
    if (ref $_[0]) {
        $parm_ref = shift;
    } else {
        $parm_ref = { @_ };
    }
    my $caching_level = $parm_ref->{-level};
    if (defined $caching_level) {
        if ($caching_level !~ m/^[012]$/) {
            croak(__PACKAGE__ . "::stem_caching() - Legal values are '0','1' or '2'. '$caching_level' is not a legal value");
        }
        $Stem_Caching = $caching_level;
    }
    return $Stem_Caching;
}    
        
##############################################################

=over 4

=item clear_stem_cache;

Clears the cache of stemmed words

=back

=cut

sub clear_stem_cache {
    $Stem_Cache = {};
}

##############################################################

=head1 NOTES

This code is a wrapper around Lingua::Stemmer::GL written by 
xern <xern@cpan.org> 

=head1 SEE ALSO

 Lingua::Stem Lingua::Stemmer::GL;

=head1 AUTHOR

  Integration in Lingua::Stem by 
  Benjamin Franz, FreeRun Technologies,
  snowhare@nihongo.org or http://www.nihongo.org/snowhare/

=head1 COPYRIGHT

Benjamin Franz, FreeRun Technologies

This code is freely available under the same terms as Perl.

=head1 BUGS

=head1 TODO

=cut

1;
