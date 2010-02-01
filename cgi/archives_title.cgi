#!/usr/bin/env perl

# Copyright (C) 2010  Fletcher T. Penney <fletcher@fletcherpenney.net>
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

print "Content-type: text/html\n\n";

# Where am I called from
my $search_path = $ENV{REQUEST_URI};

$search_path =~ /(\d\d\d\d)(?:.*?(\d\d))?/;
my $year = $1;
my $month = $2;

my @months = qw(January February March April May June July August
	September October November December);


my $title = "";

if ($month ne "") {
	$title = "$months[$month-1] ";
}

$title .= "$year Archives";

print $title;