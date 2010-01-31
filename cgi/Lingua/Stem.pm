package Lingua::Stem;

# $RCSfile: Stem.pm,v $ $Revision: 1.2 $ $Date: 1999/06/16 17:45:28 $ $Author: snowhare $

use strict;
require Exporter;
use Lingua::Stem::AutoLoader;

BEGIN {
    $Lingua::Stem::VERSION     = '0.83';
    @Lingua::Stem::ISA         = qw (Exporter);
    @Lingua::Stem::EXPORT      = ();
    @Lingua::Stem::EXPORT_OK   = qw (stem stem_in_place clear_stem_cache stem_caching add_exceptions delete_exceptions get_exceptions set_locale get_locale);
    %Lingua::Stem::EXPORT_TAGS = ( 'all' => [qw (stem stem_in_place stem_caching clear_stem_cache add_exceptions delete_exceptions get_exceptions set_locale get_locale)],
                    'stem' => [qw (stem)],
           'stem_in_place' => [qw (stem_in_place)],
                 'caching' => [qw (stem_caching clear_stem_cache)],
                  'locale' => [qw (set_locale get_locale)],
              'exceptions' => [qw (add_exceptions delete_exceptions get_exceptions)],
                 );
}

my $defaults = {
            -locale       => 'en',
           -stemmer       => \&Lingua::Stem::En::stem,
           -stem_in_place => \&Lingua::Stem::En::stem,
      -stem_caching       => \&Lingua::Stem::En::stem_caching,
  -clear_stem_cache       => \&Lingua::Stem::En::clear_stem_cache,
        -exceptions       => {},
      -known_locales => {
                          'da' => { -stemmer => \&Lingua::Stem::Da::stem,
                               -stem_caching => \&Lingua::Stem::Da::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::Da::clear_stem_cache,
                           -stem_in_place    => sub { require Carp; Carp::croak("'stem_in_place' not available for 'da' locale"); },
                           },
                          'de' => { -stemmer => \&Lingua::Stem::De::stem,
                               -stem_caching => \&Lingua::Stem::De::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::De::clear_stem_cache,
                           -stem_in_place    => sub { require Carp; Carp::croak("'stem_in_place' not available for 'de' locale"); },
                           },
                          'en' => { -stemmer => \&Lingua::Stem::En::stem,
                               -stem_caching => \&Lingua::Stem::En::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::En::clear_stem_cache,
                           -stem_in_place    => \&Lingua::Stem::En::stem,
                           },
                       'en_us' => { -stemmer => \&Lingua::Stem::En::stem,
                               -stem_caching => \&Lingua::Stem::En::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::En::clear_stem_cache,
                           -stem_in_place    => \&Lingua::Stem::En::stem,
                           },
                       'en-us' => { -stemmer => \&Lingua::Stem::En::stem,
                               -stem_caching => \&Lingua::Stem::En::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::En::clear_stem_cache,
                           -stem_in_place    => \&Lingua::Stem::En::stem,
                           },
                       'en_uk' => { -stemmer => \&Lingua::Stem::En::stem,
                               -stem_caching => \&Lingua::Stem::En::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::En::clear_stem_cache,
                           -stem_in_place    => \&Lingua::Stem::En::stem,
                           },
                       'en-uk' => { -stemmer => \&Lingua::Stem::En::stem,
                               -stem_caching => \&Lingua::Stem::En::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::En::clear_stem_cache,
                           -stem_in_place    => \&Lingua::Stem::En::stem,
                           },
                   'en-broken' => { -stemmer => \&Lingua::Stem::En_Broken::stem,
                               -stem_caching => \&Lingua::Stem::En_Broken::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::En_Broken::clear_stem_cache,
                           -stem_in_place    => sub { require Carp; Carp::croak("'stem_in_place' not available for 'en-broken' locale"); },
                           },
                          'fr' => { -stemmer => \&Lingua::Stem::Fr::stem,
                               -stem_caching => \&Lingua::Stem::Fr::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::Fr::clear_stem_cache,
                           -stem_in_place    => sub { require Carp; Carp::croak("'stem_in_place' not available for 'fr' locale"); },
                           },
                          'gl' => { -stemmer => \&Lingua::Stem::Gl::stem,
                               -stem_caching => \&Lingua::Stem::Gl::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::Gl::clear_stem_cache,
                           -stem_in_place    => sub { require Carp; Carp::croak("'stem_in_place' not available for 'gl' locale"); },
                           },
                          'it' => { -stemmer => \&Lingua::Stem::It::stem,
                               -stem_caching => \&Lingua::Stem::It::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::It::clear_stem_cache,
                           -stem_in_place    => sub { require Carp; Carp::croak("'stem_in_place' not available for 'it' locale"); },
                           },
                          'no' => { -stemmer => \&Lingua::Stem::No::stem,
                               -stem_caching => \&Lingua::Stem::No::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::No::clear_stem_cache,
                           -stem_in_place    => sub { require Carp; Carp::croak("'stem_in_place' not available for 'no' locale"); },
                           },
                          'pt' => { -stemmer => \&Lingua::Stem::Pt::stem,
                               -stem_caching => \&Lingua::Stem::Pt::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::Pt::clear_stem_cache,
                           -stem_in_place    => sub { require Carp; Carp::croak("'stem_in_place' not available for 'pt' locale"); },
                           },
                          'sv' => { -stemmer => \&Lingua::Stem::Sv::stem,
                               -stem_caching => \&Lingua::Stem::Sv::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::Sv::clear_stem_cache,
                           -stem_in_place    => sub { require Carp; Carp::croak("'stem_in_place' not available for 'sv' locale"); },
                           },
                          'ru' => { -stemmer => \&Lingua::Stem::Ru::stem,
                               -stem_caching => \&Lingua::Stem::Ru::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::Ru::clear_stem_cache,
                           -stem_in_place    => sub { require Carp; Carp::croak("'stem_in_place' not available for 'ru' locale"); },
                           },
                          'ru_ru' => {
                                    -stemmer => \&Lingua::Stem::Ru::stem,
                               -stem_caching => \&Lingua::Stem::Ru::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::Ru::clear_stem_cache,
                           -stem_in_place    => sub { require Carp; Carp::croak("'stem_in_place' not available for 'ru_ru' locale"); },
                           },
                          'ru-ru' => {
                                    -stemmer => \&Lingua::Stem::Ru::stem,
                               -stem_caching => \&Lingua::Stem::Ru::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::Ru::clear_stem_cache,
                           -stem_in_place    => sub { require Carp; Carp::croak("'stem_in_place' not available for 'ru-ru' locale"); },
                           },
                          'ru-ru.koi8-r' => {
                                    -stemmer => \&Lingua::Stem::Ru::stem,
                               -stem_caching => \&Lingua::Stem::Ru::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::Ru::clear_stem_cache,
                           -stem_in_place    => sub { require Carp; Carp::croak("'stem_in_place' not available for 'ru-ru.koi8-r' locale"); },
                           },
                          'ru_ru.koi8-r' => {
                                    -stemmer => \&Lingua::Stem::Ru::stem,
                               -stem_caching => \&Lingua::Stem::Ru::stem_caching,
                           -clear_stem_cache => \&Lingua::Stem::Ru::clear_stem_cache,
                           -stem_in_place    => sub { require Carp; Carp::croak("'stem_in_place' not available for 'ru_ru.koi8-r' locale"); },
                           },
                   },
};

###

sub new {
    my $proto = shift;
    my $package = __PACKAGE__;
    my $proto_ref = ref($proto);
    my $class;
    if ($proto_ref) {
        $class = $proto_ref;
    } elsif ($proto) {
        $class = $proto;
    } else {
        $class = $package;
    }
    my $self = bless {},$class;

    # Set the defaults
    %{$self->{'Lingua::Stem'}->{-exceptions}}     = %{$defaults->{-exceptions}};
    $self->{'Lingua::Stem'}->{-locale}            = $defaults->{-locale};
    $self->{'Lingua::Stem'}->{-stemmer}           = $defaults->{-stemmer};
    $self->{'Lingua::Stem'}->{-stem_in_place}     = $defaults->{-stem_in_place};
    $self->{'Lingua::Stem'}->{-stem_caching}      = $defaults->{-stem_caching};
    $self->{'Lingua::Stem'}->{-clear_stem_cache}  = $defaults->{-clear_stem_cache};

    # Handle any passed parms
    my @errors = ();
    if ($#_ > -1) {
        my $parm_ref = $_[0];
        if (not ref $parm_ref) {
            $parm_ref = {@_};
        }
        foreach my $key (keys %$parm_ref) {
            my $lc_key = lc ($key);
            if    ($lc_key eq '-locale')         { $self->set_locale($parm_ref->{$key});            }
            elsif ($lc_key eq '-default_locale') { set_locale($parm_ref->{$key});                   }
            else                                 { push (@errors," '$key' => '$parm_ref->{$key}'"); }
        }
    }
    if ($#errors > -1) {
        require Carp;
        Carp::croak ($package . "::new() - unrecognized parameters passed:" . join(', ',@errors));
    }

    return $self;
}

###

sub set_locale {
    my ($self)   = shift;

    my ($locale);
    if (ref $self) {
        ($locale) = @_;
        $locale   = lc $locale;
        if (not exists $defaults->{-known_locales}->{$locale}) {
            require Carp;
            Carp::croak (__PACKAGE__ . "::set_locale() - Unknown locale '$locale'");
        }
        $self->{'Lingua::Stem'}->{-locale}           = $locale;
        $self->{'Lingua::Stem'}->{-stemmer}          = $defaults->{-known_locales}->{$locale}->{-stemmer};
        $self->{'Lingua::Stem'}->{-stem_in_place}    = $defaults->{-known_locales}->{$locale}->{-stem_in_place};
        $self->{'Lingua::Stem'}->{-stem_caching}     = $defaults->{-known_locales}->{$locale}->{-stem_caching};
        $self->{'Lingua::Stem'}->{-clear_stem_cache} = $defaults->{-known_locales}->{$locale}->{-clear_stem_cache};
    } else {
        $locale = lc $self;
        if (not exists $defaults->{-known_locales}->{$locale}) {
            require Carp;
            Carp::croak (__PACKAGE__ . "::set_locale() - Unknown locale '$locale'");
        }
        $defaults->{-locale}           = $locale;
        $defaults->{-stemmer}          = $defaults->{-known_locales}->{$locale}->{-stemmer};
        $defaults->{-stem_in_place}    = $defaults->{-known_locales}->{$locale}->{-stem_in_place};
        $defaults->{-stem_caching}     = $defaults->{-known_locales}->{$locale}->{-stem_caching};
        $defaults->{-clear_stem_cache} = $defaults->{-known_locales}->{$locale}->{-clear_stem_cache};
    }
    return;
}

###

sub get_locale {
    my $self = shift;

    if (ref $self) {
        return $self->{'Lingua::Stem'}->{-locale};
    } else {
        return $defaults->{-locale};
    }
}

###

sub add_exceptions {
    my $self;

    my ($exceptions, $exception_list);
    my $reference = ref $_[0];
    if ($reference eq 'HASH') {
        ($exceptions) =  @_;
        $exception_list = $defaults->{-exceptions};
    } elsif (not $reference) {
        $exceptions = { @_ };
        $exception_list = $defaults->{-exceptions};
    } else {
        $self = shift;
        ($exceptions) = @_;
        $exception_list = $self->{'Lingua::Stem'}->{-exceptions};
    }
    while (my ($exception,$replace_with) = each %$exceptions) {
            $exception_list->{$exception} = $replace_with;
    }
    return;
}

###

sub delete_exceptions {
    my $self;

    my ($exception_list,$exceptions);
    if ($#_ == -1) {
        $defaults->{-exceptions} = {};
        return;
    }
    my $reference =ref $_[0];
    if ($reference eq 'ARRAY') {
        ($exceptions) =  @_;
        $exception_list = $defaults->{-exceptions};
    } elsif (not $reference) {
        $exceptions = [@_];
        $exception_list = $defaults->{-exceptions};
    } else {
        $self = shift;
        if ($#_ == -1) {
            $self->{'Lingua::Stem'}->{-exceptions} = {};
        } else {
            $reference = ref $_[0];
            if ($reference eq 'ARRAY') {
                ($exceptions) =  @_;
                $exception_list = $self->{'Lingua::Stem'}->{-exceptions};
            } else {
                ($exceptions) = [@_];
                $exception_list = $self->{'Lingua::Stem'}->{-exceptions};
            }
        }
    }

    foreach (@$exceptions) { delete $exception_list->{$_}; }
    return;
}

###

sub get_exceptions {

    my $exception_list = {};
    if ($#_ == -1) {
        %$exception_list = %{$defaults->{-exceptions}};
        return $exception_list;
    }
    my $reference = ref $_[0];
    if ($reference eq 'ARRAY') {
        %$exception_list = %{$defaults->{-exceptions}};
    } elsif ($reference) {
        my $self = shift;
        if ($#_ > -1) {
            foreach (@_) {
                $exception_list->{$_} = $self->{'Lingua::Stem'}->{-exceptions}->{$_};
            }
        } else {
            %$exception_list = %{$self->{'Lingua::Stem'}->{-exceptions}};
        }
    } else {
        foreach (@_) {
            $exception_list->{$_} = $_;
        }
    }
    return $exception_list;
}

####

sub stem {
    my $self;
    return [] if ($#_ == -1);
    my ($exceptions,$locale,$stemmer);
    if (ref $_[0]) {
        my $self = shift;
        $exceptions = $self->{'Lingua::Stem'}->{-exceptions};
        $stemmer    = $self->{'Lingua::Stem'}->{-stemmer};
        $locale     = $self->{'Lingua::Stem'}->{-locale};
    } else {
        $exceptions = $defaults->{-exceptions};
        $stemmer    = $defaults->{-stemmer};
        $locale     = $defaults->{-locale};
    }
    &$stemmer({ -words => \@_,
               -locale => $locale,
           -exceptions => $exceptions });
}

###

sub stem_in_place {
    my $self;
    return [] if ($#_ == -1);
    my ($exceptions,$locale,$stemmer);
    if (ref $_[0]) {
        my $self = shift;
        $exceptions = $self->{'Lingua::Stem'}->{-exceptions};
        $stemmer    = $self->{'Lingua::Stem'}->{-stem_in_place};
        $locale     = $self->{'Lingua::Stem'}->{-locale};
    } else {
        $exceptions = $defaults->{-exceptions};
        $stemmer    = $defaults->{-stem_in_place};
        $locale     = $defaults->{-locale};
    }
    &$stemmer({ -words => [\@_],
               -locale => $locale,
           -exceptions => $exceptions });
}

###

sub clear_stem_cache {
    my $clear_stem_cache_sub;
    if (ref $_[0]) {
        my $self = shift;
        $clear_stem_cache_sub = $self->{'Lingua::Stem'}->{-clear_stem_cache};
    } else {
        $clear_stem_cache_sub = $defaults->{-clear_stem_cache};
    }
    &$clear_stem_cache_sub;
}

###

sub stem_caching {
    my $stem_caching_sub;
    my $first_parm_ref = ref $_[0];
    if ($first_parm_ref && ($first_parm_ref ne 'HASH')) {
        my $self = shift;
        $stem_caching_sub = $self->{'Lingua::Stem'}->{-stem_caching};
    } else {
        $stem_caching_sub = $defaults->{-stem_caching};
    }
    &$stem_caching_sub(@_);
}

1;
