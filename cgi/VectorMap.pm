#!/usr/bin/env perl

# based on Search::VectorSpace
#	<http://www.perl.com/pub/a/2003/02/19/engine.html>
# by Maciej Ceglowski
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

package VectorMap;

use strict;
use warnings;
use File::Find;
use Cwd 'abs_path';
use Lingua::Stem;
use Lingua::Stem::En;


#	For future reference, if needed
#	foreach my $k (sort keys %{%{$self->{'objects'}}->{$object}}) {
#			print "$k\t" . $self->{'objects'}->{$object}->{$k} . "\n";
#		}



# Basic Subroutines

sub new {
	my ( $class ) = @_;
	my $self = {
		stop_list => load_stop_list(),
	};
	
	return bless $self, $class;
}


# Subroutines to access data

sub all_objects {
	my ($self) = @_;
	
	my @objects = ();
	
	foreach my $object (sort keys %{$self->{'objects'}}) {
		push(@objects, $object);
	}
	
	return \@objects;
}

sub list_groups {
	# List all group id's
	my ($self) = @_;
	my @groups = sort (keys %{$self->{'groups'}});
	
	return @groups;
}

sub group_members {
	my ($self, $group) = @_;
	
	my @objects = ();
	
	foreach my $object (sort keys %{$self->{'members'}->{$group}}) {
		push(@objects, $object);
	}
	
	return \@objects;
}

sub group_non_members {
	my ($self, $group) = @_;
	
	my @objects = ();

	foreach my $object (sort keys %{$self->{'objects'}}) {
		push(@objects, $object) if !exists $self->{'members'}->{$group}->{$object};
	}
	
	return \@objects;
}

sub vector {
	# Return the vector for an object
	my ($self, $id) = @_;
	my %result = %{$self->{'objects'}->{$id}};
	
	return %result;
}


# Subroutines to add new objects

sub add_object {
	# Given a label, and the body, add a new object to the map
	my ($self, $id, $data) = @_;

	my %vector = $self->normalize_vector( 
		$self->get_words($data)
	);
	
	$self->{'objects'}->{$id} = \%vector;
}

sub add_file {
	my ($self, $filepath) = @_;
	my $data = "";
	
	$filepath = abs_path($filepath);
	
	local $/;
	if (open (FILE, "<$filepath")) {
		$data = <FILE>;
		close FILE;
		$self->add_object($filepath,$data);
	}
}

sub add_object_to_groups {
	my ($self, $id, @groups) = @_;
	# Given an id, add it's vector to the non-normalized vector for the group
	
	foreach my $group (@groups) {
		# Add vector for $id to previous vector for the group
		my %vector = $self->add_vectors($self->{'objects'}->{$id},$self->{'groups'}->{'$group'});
		$self->{'groups'}->{$group} = \%vector;
		
		# Keep list of objects added to each group
		$self->{'members'}->{$group}->{$id} = 1;
	}
}


# Subroutines to calculate vectors

sub get_words {	
	# Splits on whitespace and strips some punctuation
	my ( $self, $text ) = @_;
	my %doc_words;  
	my @words = map { stem($_) }
				grep { !( exists $self->{'stop_list'}->{$_} ) }
				map { lc($_) } 
				map {  $_ =~/([a-z\-']+)/i} 
				split /\s+/, $text;
	do { $_++ } for @doc_words{@words};

	return %doc_words;
}

sub stem {
	my ( $word ) = @_;
	my $stemref = Lingua::Stem::stem( $word );
	return $stemref->[0];
}

sub load_stop_list {
	my %stop_words;
	while (<DATA>) {
		chomp;
		$stop_words{$_}++;
	}
	return \%stop_words;
}


# Subroutines for vector calculations

sub cosine {
	# Assumes normalized vectors
	my ($self, $a, $b) = (@_);
	my $total = 0;
	my %union = my %isect = ();
	
	foreach my $e ((keys %$a), (keys %$b)) { $union{$e}++ && $isect{$e}++};
	
	foreach my $k (keys %isect) {
		$total += $a->{$k} * $b->{$k};
	}

	return $total;
}

sub add_vectors {
	# Take two arbitrary vectors and add them together
	my ($self, $a, $b) = (@_);
	my %vector = ();
	
	my %union = my %isect = ();
	
	foreach my $e ((keys %$a), (keys %$b)) { $union{$e}++ && $isect{$e}++};
	
	foreach my $k (keys %union) {
		$vector{$k} = $a->{$k} + $b->{$k};
	}

	return %vector;
}

sub normalize_vector {
	# Divide count by overall magnitude of vector to make unit vector
	my ($self, %vector) = @_;
	my $total = 0;

	foreach my $k (keys %vector) {
		$total += $vector{$k} ** 2;
	}

	$total = $total ** (1/2);

	foreach my $k (keys %vector) {
		$vector{$k} = $vector{$k} / $total;
	}
	
	return %vector;
}

sub print_vector {
	my ($self,%vector) = @_;
	
	foreach my $k (keys %vector) {
		print "$k:\t$vector{$k}\n";
	}
}


# Subroutines to use the vector map for comparisons

sub query_map {
	# Given one object, find similarities with other objects in map
	my ($self, $query_object ) = @_;
	my %result = ();

	foreach my $object (sort keys %{$self->{'objects'}}) {
		next if $object eq $query_object;	# Matching ourself is not helpful
		$result{$object} = $self->cosine($self->{'objects'}->{$object}, $self->{'objects'}->{$query_object});
	}
	
	return %result;	
}

sub map_relationships {
	# Return a matrix of similarities between all objects in the map
	my ($self) = @_;
	my %results = ();
	my $index = $self->all_objects();
	my $total = scalar @$index -1;
	
	foreach my $a (0..$total) {
		foreach my $b ($a+1..$total) {
			$results{@$index[$a]}{@$index[$b]} = $self->cosine($self->{'objects'}->{@$index[$a]},$self->{'objects'}->{@$index[$b]})
		}
	}

	return %results;
}

sub map_group {
	# Return a list of similarities with all objects and a specified group
	my ($self, $group) = @_;
	my %results = ();
	my $index = $self->all_objects();
	my $total = scalar @$index -1;


	my %vector = $self->normalize_vector(%{$self->{'groups'}->{$group}});
	
	foreach my $a (0..$total) {
		$results{@$index[$a]} = $self->cosine(\%vector,$self->{'objects'}->{@$index[$a]});
	}

	return %results;
}

sub map_group_members {
	# Return a list of similarities with a specified group and its members
	my ($self, $group) = @_;
	my %results = ();
	my $index = $self->group_members($group);
	my $total = scalar @$index -1;


	my %vector = $self->normalize_vector(%{$self->{'groups'}->{$group}});

	foreach my $a (0..$total) {
		$results{@$index[$a]} = $self->cosine(\%vector,$self->{'objects'}->{@$index[$a]});
	}

	return %results;
}

sub map_group_non_members {
	# Return a list of similarities with a specified group and
	#	objects not in the group
	my ($self, $group) = @_;
	my %results = ();
	my $index = $self->group_non_members($group);
	my $total = scalar @$index -1;

	my %vector = $self->normalize_vector(%{$self->{'groups'}->{$group}});

	foreach my $a (0..$total) {
		$results{@$index[$a]} = $self->cosine(\%vector,$self->{'objects'}->{@$index[$a]});
	}

	return %results;
}

sub suggested_group_members {
	# Not sure of best algorithm here --- this is a first-pass
	# Given a group, suggest items that might belong in group
	my ($self, $group) = @_;
	my %results = ();
	my $floor = 0.1;		# Minimum threshold to use
	
	# Find worst member match
	my %members = $self->map_group_members($group);
	my $threshold = 1;
	foreach my $member (keys %members) {
		$threshold = $members{$member} if ($members{$member} < $threshold);
	}
	
#	$threshold -= .03;		# buffer amount around the threshold
	
	# Have a floor
	$threshold = $floor if ($threshold < $floor);

	# Find non-members that are better matches than adjusted threshold
	my %nonmembers = $self->map_group_non_members($group);
	foreach my $member (keys %nonmembers) {
		$results{$member} = $nonmembers{$member} if ($nonmembers{$member} > $threshold);
	}
	
	print "Threshold is $threshold\n";
	return %results;
}

sub compare_object_to_group {
	my ($self, $id, $group) = @_;
	
	my %vector = $self->normalize_vector(%{$self->{'groups'}->{$group}});

	my $result = $self->cosine(\%vector,$self->{'objects'}->{$id});

	return $result;
}

sub group_suggestions {
	my ($self, $id) = @_;
	
	my %results = ();
	
	foreach my $group ($self->list_groups()) {
		$results{$group} = $self->compare_object_to_group($id, $group);
	}
	
	return %results;
}


1;

__DATA__

i'm
web
don't
i've
we've
they've
she's
he's
it's
great
old
can't
tell
tells
busy
doesn't
you're
your's
didn't
they're
night
nights
anyone
isn't
i'll
actual
actually
presents
presenting
presenter
present
presented
presentation
we're
wouldn't
example
examples
i'd
haven't
etc
won't
myself
we've
they've
aren't
we'd
it'd
ain't
i'll
who've
-year-old
kind
kinds
builds
build
built
com
make
makes
making
made
you'll
couldn't
use
uses
used
using
take
takes
taking
taken
exactly
we'll
it'll
certainly
he'd
shown
they'd
wasn't
yeah
to-day
lya
a
ability
able
aboard
about
above
absolute
absolutely
across
act
acts
add
additional
additionally
after
afterwards
again
against
ago
ahead
aimless
aimlessly
al
albeit
align
all
allow
almost
along
alongside
already
also
alternate
alternately
although
always
am
amid
amidst
among
amongst
an
and
announce
announced
announcement
announces
another
anti
any
anything
appaling
appalingly
appear
appeared
appears
are
around
as
ask
asked
asking
asks
at
await
awaited
awaits
awaken
awakened
awakens
aware
away
b
back
backed
backing
backs
be
became
because
become
becomes
becoming
been
before
began
begin
begins
behind
being
believe
believed
between
both
brang
bring
brings
brought
but
by
c
call
called
calling
calls
can
cannot
carried
carries
carry
carrying
change
changed
changes
choose
chooses
chose
clearly
close
closed
closes
closing
come
comes
coming
consider
considerable
considering
could
couldn
d
dare
daren
day
days
despite
did
didn
do
does
doesn
doing
done
down
downward
downwards
e
each
eight
either
else
elsewhere
especially
even
eventually
ever
every
everybody
everyone
f
far
feel
felt
few
final
finally
find
five
for
found
four
fourth
from
get
gets
getting
gave
give
gives
go
goes
going
gone
good
got
h
had
has
have
he
held
her
here
heretofore
hereby
herewith
hers
herself
high
him
himself
his
hitherto
happen
happened
happens
hour
hours
how
however
i
ii
iii
iv
if
in
include
included
includes
including
inside
into
is
isn
it
its
itself
j
just
k
l
la
larger
largest
last
later
latest
le
least
leave
leaves
leaving
les
let
less
like
ll
m
made
main
mainly
make
makes
man
many
may
me
means
meant
meanwhile
men
might
missed
more
moreover
most
mostly
move
moved
moving
mr
mrs
much
must
mustn
my
need
needs
neither
never
new
newer
news
nine
no
non
none
nor
not
now
o
of
off
often
on
once
one
only
or
other
our
out
over
own
owns
p
particularly
per
percent
primarily
put
q
quickly
r
remain
remaining
respond
responded
responding
responds
return
ran
rather
run
running
runs
s
said
say
says
same
see
seek
seeking
seeks
seen
send
sent
set
sets
seven
several
she
should
shouldn
side
since
six
sixes
slow
slowed
slows
small
smaller
so
some
someone
something
somewhat
somewhere
soon
sought
spread
stay
stayed
still
substantially
such
suppose
t
take
takes
taken
th
than
that
the
their
them
themselves
then
there
thereby
therefore
these
they
thing
things
thi
this
those
though
thus
three
through
throughout
to
together
too
took
toward
towards
tried
tries
try
trying
two
u
unable
under
underneath
undid
undo
undoes
undone
undue
undoubtedly
unfortunately
unless
unnecessarily
unofficially
until
unusually
unsure
up
upon
upward
us
use
used
uses
using
usual
usually
v
ve
very
via
view
viewed
w
wait
waited
waits
want
wanted
wants
was
wasn
watched
watching
way
ways
we
went
were
what
whatever
when
whenever
where
whereever
whether
which
whichever
while
who
whoever
whom
whomsoever
whose
whosever
why
wide
wider
will
with
without
won
would
wouldn
wow
wows
www
x
xii
xiii
xiv
xv
xvi
xvii
xviii
xix
xx
y
year
you
your
yours
yourself
yourselves