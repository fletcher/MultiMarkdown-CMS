package Lingua::Stem::En;

# $RCSfile: En.pm,v $ $Revision: 1.4 $ $Date: 1999/06/24 23:33:37 $ $Author: snowhare $

=head1 NAME

Lingua::Stem::En - Porter's stemming algorithm for 'generic' English

=head1 SYNOPSIS

    use Lingua::Stem::En;
    my $stems   = Lingua::Stem::En::stem({ -words => $word_list_reference,
                                        -locale => 'en',
                                    -exceptions => $exceptions_hash,
                                     });

=head1 DESCRIPTION

This routine applies the Porter Stemming Algorithm to its parameters,
returning the stemmed words.

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

 
 1999.06.15 - Changed to '.pm' module, moved into Lingua::Stem namespace,
              optionalized the export of the 'stem' routine
              into the caller's namespace, added named parameters

 1999.06.24 - Switch core implementation of the Porter stemmer to
              the one written by Jim Richardson <jimr@maths.usyd.edu.au>

 2000.08.25 - 2.11 Added stemming cache

 2000.09.14 - 2.12 Fixed *major* :( implementation error of Porter's algorithm
              Error was entirely my fault - I completely forgot to include
              rule sets 2,3, and 4 starting with Lingua::Stem 0.30. 
              -- Benjamin Franz

 2003.09.28 - 2.13 Corrected documentation error pointed out by Simon Cozens.

 2005.11.20 - 2.14 Changed rule declarations to conform to Perl style convention
              for 'private' subroutines. Changed Exporter invokation to more
              portable 'require' vice 'use'.

 2006.02.14 - 2.15 Added ability to pass word list by 'handle' for in-place stemming.

=cut

#######################################################################
# Initialization
#######################################################################

use strict;
require Exporter;
use Carp;
use vars qw (@ISA @EXPORT_OK @EXPORT %EXPORT_TAGS $VERSION);
BEGIN {
    $VERSION     = "2.14";
    @ISA         = qw (Exporter);
    @EXPORT      = ();
    @EXPORT_OK   = qw (stem clear_stem_cache stem_caching);
    %EXPORT_TAGS = ();
}

my $Stem_Caching  = 0;
my $Stem_Cache    = {};
my %Stem_Cache2   = ();

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

  my @words         = ( 'wordy', 'another' );
  my $stemmed_words = Lingua::Stem::En::stem({ -words => \@words,
                                              -locale => 'en',
                                          -exceptions => \%exceptions,
                          });

If the first element of @words is a list reference, then the stemming is performed 'in place'
on that list (modifying the passed list directly instead of copying it to a new array).

This is only useful if you do not need to keep the original list. If you B<do> need to keep
the original list, use the normal semantic of having 'stem' return a new list instead - that
is faster than making your own copy B<and> using the 'in place' semantics since the primary
difference between 'in place' and 'by value' stemming is the creation of a copy of the original
list.  If you B<don't> need the original list, then the 'in place' stemming is about 60% faster.

Example of 'in place' stemming:

  my $words         = [ 'wordy', 'another' ];
  my $stemmed_words = Lingua::Stem::En::stem({ -words => \$words,
                          -locale => 'en',
                      -exceptions => \%exceptions,
                      });

The 'in place' mode returns a reference to the original list with the words stemmed.

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
        my $key   = lc ($_);
        my $value = $parm_ref->{$key};
        if ($key eq '-words') {
            @$words = @$value;
            if (ref($words->[0]) eq 'ARRAY'){
                $words = $words->[0];
            }
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

        # Check against cache of stemmed words
        if (exists $Stem_Cache2{$_}) {
            $_ = $Stem_Cache2{$_}; 
            next;
        }

        # Check against exceptions list
        if (exists $exceptions->{$_}) {
			$_ = $exceptions->{$_};
			next;
		}

        my $original_word = $_;

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

        { 
            no strict 'refs';
            
            my $sub;
    
            #  Step 3: double and triple suffices, etc (part 2)

            &$sub if defined &{ $sub = '_S2' . substr( $_, 0, 3 ) };
    
            #  Step 3: double and triple suffices, etc (part 2)
    
            &$sub if defined &{ $sub = '_S3' . substr( $_, 0, 3 ) };
    
            #  Step 4: single suffices on polysyllables
    
            &$sub if defined &{ $sub = '_S4' . substr( $_, 0, 2 ) };
   
        }
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

        $Stem_Cache2{$original_word} = $_ if $Stem_Caching;
    }
    %Stem_Cache2 = () if ($Stem_Caching < 2);
    
    return $words;
}

##############################################################
# Rule set 4

sub _S4la {
    #  SYLSYLal -> SYLSYL
    s!^la($syl$syl)!$1!o;
}

sub _S4ec {
    #  SYLSYL[ae]nce -> SYLSYL
    s!^ecn[ae]($syl$syl)!$1!o;
}

sub _S4re {
    #  SYLSYLer -> SYLSYL
    s!^re($syl$syl)!$1!o;
}

sub _S4ci {
    #  SYLSYLic -> SYLSYL
    s!^ci($syl$syl)!$1!o;
}

sub _S4el {
    #  SYLSYL[ai]ble -> SYLSYL
    s!^elb[ai]($syl$syl)!$1!o;
}

sub _S4tn {
    #  SYLSYLant -> SYLSYL, SYLSYLe?ment -> SYLSYL, SYLSYLent -> SYLSYL
    s!^tn(a|e(me?)?)($syl$syl)!$3!o;
}
sub _S4no {
    #  SYLSYL[st]ion -> SYLSYL[st]
    s!^noi([st]$syl$syl)!$1!o;
}

sub _S4uo {
    #  SYLSYLou -> SYLSYL e.g. homologou -> homolog
    s!^uo($syl$syl)!$1!o;
}

sub _S4ms {
    #  SYLSYLism -> SYLSYL
    s!^msi($syl$syl)!$1!o;
}

sub _S4et {
    #  SYLSYLate -> SYLSYL
    s!^eta($syl$syl)!$1!o;
}

sub _S4it {
    #  SYLSYLiti -> SYLSYL
    s!^iti($syl$syl)!$1!o;
}

sub _S4su {
    #  SYLSYLous -> SYLSYL
    s!^suo($syl$syl)!$1!o;
}

sub _S4ev { 
    #  SYLSYLive -> SYLSYL
    s!^evi($syl$syl)!$1!o;
}

sub _S4ez {
    #  SYLSYLize -> SYLSYL
    s!^ezi($syl$syl)!$1!o;
}

sub _S4es {
    #  SYLSYLise -> SYLSYL **
    s!^esi($syl$syl)!$1!o;
}

##############################################################
# Rule set 2

sub _S2lan {
    #  SYLational -> SYLate,	SYLtional -> SYLtion
    s!^lanoita($syl)!eta$1!o || s!^lanoit($syl)!noit$1!o;
}

sub _S2icn {
    #  SYLanci -> SYLance, SYLency ->SYLence
    s!^icn([ae]$syl)!ecn$1!o;
}

sub _S2res {
    #  SYLiser -> SYLise **
    &_S2rez;
}

sub _S2rez {
    #  SYLizer -> SYLize
    s!^re(.)i($syl)!e$1i$2!o;
}

sub _S2ilb {
    #  SYLabli -> SYLable, SYLibli -> SYLible ** (e.g. incredibli)
    s!^ilb([ai]$syl)!elb$1!o;
}

sub _S2ill {
    #  SYLalli -> SYLal
    s!^illa($syl)!la$1!o;
}

sub _S2ilt {
    #  SYLentli -> SYLent
    s!^iltne($syl)!tne$1!o
}

sub _S2ile {
    #  SYLeli -> SYLe
    s!^ile($syl)!e$1!o;
}

sub _S2ils {
    #  SYLousli -> SYLous
    s!^ilsuo($syl)!suo$1!o;
}

sub _S2noi {
    #  SYLization -> SYLize, SYLisation -> SYLise**, SYLation -> SYLate
    s!^noita([sz])i($syl)!e$1i$2!o || s!^noita($syl)!eta$1!o;
}

sub _S2rot {
    #  SYLator -> SYLate
    s!^rota($syl)!eta$1!o;
}

sub _S2msi {
    #  SYLalism -> SYLal
    s!^msila($syl)!la$1!o;
}

sub _S2sse {
    #  SYLiveness  -> SYLive, SYLfulness -> SYLful, SYLousness -> SYLous
    s!^ssen(evi|luf|suo)($syl)!$1$2!o;
}

sub _S2iti {
    #  SYLaliti -> SYLal, SYLiviti -> SYLive, SYLbiliti ->SYLble
    s!^iti(la|lib|vi)($syl)! ( $1 eq 'la' ? 'la' : $1 eq 'lib' ? 'elb' : 'evi' )
	. $2 !eo;
}

##############################################################
# Rule set 3

sub _S3eta {
    #  SYLicate -> SYLic
    s!^etaci($syl)!ci$1!o;
}

sub _S3evi {
    #  SYLative -> SYL
    s!^evita($syl)!$1!o;
}

sub _S3ezi
{
    #  SYLalize -> SYLal
    s!^ezila($syl)!la$1!o;
}

sub _S3esi {
    #  SYLalise -> SYLal **
    s!^esila($syl)!la$1!o;
}

sub _S3iti {
    #  SYLiciti -> SYLic
    s!^itici($syl)!ci$1!o;
}

sub _S3lac {
    #  SYLical -> SYLic
    s!^laci($syl)!ci$1!o;
}
sub _S3luf {
    #  SYLful -> SYL
    s!^luf($syl)!$1!o;
}

sub _S3sse {
    #  SYLness -> SYL
    s!^ssen($syl)!$1!o;
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
        if ($caching_level < 2) {
            %Stem_Cache2 = ();
        }
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
    %Stem_Cache2 = ();
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
