package Lingua::Stem::EnBroken;

# $RCSfile: En.pm,v $ $Revision: 1.4 $ $Date: 1999/06/24 23:33:37 $ $Author: snowhare $

=head1 NAME

Lingua::Stem::EnBroken - Porter's stemming algorithm for 'generic' English

=head1 SYNOPSIS

    use Lingua::Stem::EnBroken;
    my $stems   = Lingua::Stem::EnBroken::stem({ -words => $word_list_reference,
                                        -locale => 'en',
                                    -exceptions => $exceptions_hash,
                                     });

=head1 DESCRIPTION

This routine MIS-applies the Porter Stemming Algorithm to its parameters,
returning the stemmed words. It is an intentionally broken version
of Lingua::Stem::En for people needing backwards compatibility with
Lingua::Stem 0.30 and Lingua::Stem 0.40. Do not use it if you aren't
one of those people.

It is derived from the C program "stemmer.c"
as found in freewais and elsewhere, which contains these notes:

   Purpose:    Implementation of the Porter stemming algorithm documented
               in: Porter, M.F., "An Algorithm For Suffix Stripping,"
               Program 14 (3), July 1980, pp. 130-137.
   Provenance: Written by B. Frakes and C. Cox, 1986.

I have re-interpreted areas that use Frakes and Cox's "WordSize"
function. My version may misbehave on short words starting with "y",
but I can't think of any examples.

The step numbers correspond to Frakes and Cox, and are probably in
Porter's article (which I've not seen).
Porter's algorithm still has rough spots (e.g current/currency, -ings words),
which I've not attempted to cure, although I have added
support for the British -ise suffix.

=head1 CHANGES


 2003.09.28 -  Documentation fix

 2000.09.14 -  Forked from the Lingua::Stem::En.pm module to provide
               a backward compatibly broken version for people needing
               consistent behavior with 0.30 and 0.40 more than accurate
               stemming.

=cut

#######################################################################
# Initialization
#######################################################################

use strict;
use Exporter;
use Carp;
use vars qw (@ISA @EXPORT_OK @EXPORT %EXPORT_TAGS $VERSION);
BEGIN {
    @ISA         = qw (Exporter);
    @EXPORT      = ();
    @EXPORT_OK   = qw (stem clear_stem_cache stem_caching);
    %EXPORT_TAGS = ();
}
$VERSION = "2.13";

my $Stem_Caching  = 0;
my $Stem_Cache    = {};

#
#V  Porter.pm V2.11 25 Aug 2000 stemming cache
#   Porter.pm V2.1  21 Jun 1999 with '&$sub if defined' not 'eval ""'
#   Porter.pm V2.0  25 Nov 1994 (for Perl 5.000)
#   porter.pl V1.0  10 Aug 1994 (for Perl 4.036)
#   Jim Richardson, University of Sydney
#   jimr@maths.usyd.edu.au or http://www.maths.usyd.edu.au:8000/jimr.html

#   Find a canonical stem for a word, assumed to consist entirely of
#   lower-case letters.  The approach is from
#
#	M. F. Porter, An algorithm for suffix stripping, Program (Automated
#	Library and Information Systems) 14 (3) 130-7, July 1980.
#
#   This algorithm is used by WAIS: for example, see freeWAIS-0.3 at
#
#	http://kudzu.cnidr.org/cnidr_projects/cnidr_projects.html

#   Some additional rules are used here, mainly to allow for British spellings
#   like -ise.  They are marked ** in the code.

#  Initialization required before using subroutine stem:

#  We count syllables slightly differently from Porter: we say the syllable
#  count increases on each occurrence in the word of an adjacent pair
#
#	[aeiouy][^aeiou]
#
#  This avoids any need to define vowels and consonants, or confusion over
#  'y'.  It also works slightly better: our definition gives two syllables
#  in 'yttrium', while Porter's gives only one because the initial 'y' is
#  taken to be a consonant.  But it is not quite obvious: for example,
#  consider 'mayfly' where, when working backwards (see below), the 'yf'
#  matches the above pattern, even though it is the 'ay' which in Porter's
#  terms increments the syllable count.
#
#  We wish to match the above in context, working backwards from the end of
#  the word: the appropriate regular expression is

my $syl = '[aeiou]*[^aeiou][^aeiouy]*[aeiouy]';

#  (This works because [^aeiouy] is a subset of [^aeiou].)  If we want two
#  syllables ("m>1" in Porter's terminology) we can just match $syl$syl.

#  For step 1b we need to be able to detect the presence of a vowel: here
#  we revert to Porter's definition that a vowel is [aeiou], or y preceded
#  by a consonant.  (If the . below is a vowel, then the . is the desired
#  vowel; if the . is a consonant the y is the desired vowel.)

my $hasvow = '[^aeiouy]*([aeiou]|y.)';

=head1 METHODS

=cut

#######################################################################

=over 4

=item stem({ -words => \@words, -locale => 'en', -exceptions => \%exceptions });

Stems a list of passed words using the rules of US English. Returns
an anonymous array reference to the stemmed words.

Example:

  my $stemmed_words = Lingua::Stem::EnBroken::stem({ -words => \@words,
                                              -locale => 'en',
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
    my $locale     = 'en';
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

    local( $_ );
    foreach (@$words) {

        # Flatten case
        $_ = lc $_;

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

        # Step 0 - remove punctuation
        s/'s$//; s/^[^a-z]+//; s/[^a-z]+$//;
        next unless /^[a-z]+$/;

        #  Reverse the word so we can easily apply pattern matching to the end:
        $_ = reverse $_;

        #  Step 1a: plurals -- sses->ss, ies->i, ss->ss, s->0

        m!^s! && ( s!^se(ss|i)!$1! || s!^s([^s])!$1! );

        #  Step 1b: participles -- SYLeed->SYLee, VOWed->VOW, VOWing->VOW;
        #  but ated->ate etc

        s!^dee($syl)!ee$1!o ||
        (
    	s!^(de|gni)($hasvow)!$2!o &&
    	(
    	    #  at->ate, bl->ble, iz->ize, is->ise
    	    s!^(ta|lb|[sz]i)!e$1! ||			# ** ise as well as ize
    	    #  CC->C (C consonant other than l, s, z)
    	    s!^([^aeioulsz])\1!$1! ||
    	    #  (m=1) CVD->CVDe (C consonant, V vowel, D consonant not w, x, y)
    	    s!^([^aeiouwxy][aeiouy][^aeiou]+)$!e$1!
    	)
        );

        #  Step 1c: change y to i: happy->happi, sky->sky

        s!^y($hasvow)!i$1!o;

        #  Step 2: double and triple suffices (part 1)

        #  Switch on last three letters (fails harmlessly if subroutine undefined) --
        #  thanks to Ian Phillipps <ian@dial.pipex.com> who wrote
        #    CPAN authors/id/IANPX/Stem-0.1.tar.gz
        #  for suggesting the replacement of
        #    eval( '&S2' . unpack( 'a3', $_ ) );
        #  (where the eval ignores undefined subroutines) by the much faster
        #    eval { &{ 'S2' . substr( $_, 0, 3 ) } };
        #  But the following is slightly faster still:

        my $sub;

        &$sub if defined &{ $sub = 'S2' . substr( $_, 0, 3 ) };

        #  Step 3: double and triple suffices, etc (part 2)

        &$sub if defined &{ $sub = 'S3' . substr( $_, 0, 3 ) };

        #  Step 4: single suffices on polysyllables

        &$sub if defined &{ $sub = 'S4' . substr( $_, 0, 2 ) };

        #  Step 5a: tidy up final e -- probate->probat, rate->rate; cease->ceas

        m!^e! && ( s!^e($syl$syl)!$1!o ||

    	# Porter's ( m=1 and not *o ) E where o = cvd with d a consonant
    	# not w, x or y:

    	! m!^e[^aeiouwxy][aeiouy][^aeiou]! &&	# not *o E
    	s!^e($syl[aeiouy]*[^aeiou]*)$!$1!o	# m=1
        );

        #  Step 5b: double l -- controll->control, roll->roll
        #  ** Note correction: Porter has m>1 here ($syl$syl), but it seems m>0
        #  ($syl) is wanted to strip an l off controll.

        s!^ll($syl)!l$1!o;

        $_ = scalar( reverse $_ );

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

This code is almost entirely derived from the Porter 2.1 module
written by Jim Richardson.

=head1 SEE ALSO

 Lingua::Stem

=head1 AUTHOR

  Jim Richardson, University of Sydney
  jimr@maths.usyd.edu.au or http://www.maths.usyd.edu.au:8000/jimr.html

  Integration in Lingua::Stem by
  Benjamin Franz, FreeRun Technologies,
  snowhare@nihongo.org or http://www.nihongo.org/snowhare/

=head1 COPYRIGHT

Jim Richardson, University of Sydney
Benjamin Franz, FreeRun Technologies

This code is freely available under the same terms as Perl.

=head1 BUGS

=head1 TODO

=cut

1;
