#!/usr/bin/perl

use Lingua::Stem qw (stem);
my @words = qw(a list of words to be stemmed for testing purposes);
my $stemmed_words = stem(@words);
print join("\n",@$stemmed_words);

