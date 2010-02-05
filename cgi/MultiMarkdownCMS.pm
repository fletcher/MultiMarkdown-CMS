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

#
#	This package provides certain utility functions to minimize redundant
#	code, and to ensure consistency when updating.
#

package MultiMarkdownCMS;

use strict;
#use warnings;
use File::Basename;
use Cwd 'abs_path';

sub getHostingPaths {
	# Figure out where the URL's and directories for this request actually are

	# Given path to calling script, find the parent of the "cgi" directory
	# Assumes calling script is located in "root"/cgi/
	my $site_root = shift;
	$site_root = dirname($site_root);
	$site_root = abs_path($site_root);
	$site_root =~ s/\/cgi$//;
	
	# Figure out the requested URI as a relative link
	(my $request = "/" . $ENV{REQUEST_URI});
		$request =~ s/$ENV{Base_URL}// if ($ENV{Base_URL} ne "");
		$request =~ s/\/\//\//g;
		
	# Figure out the implicit filepath with extensions, etc
	(my $document = "/" . $ENV{DOCUMENT_URI}); 
		$document =~ s/$ENV{Base_URL}// if ($ENV{Base_URL} ne "");
		$document =~ s/\/\//\//g;
	
	
	return ($site_root, $request, $document);
}


1;