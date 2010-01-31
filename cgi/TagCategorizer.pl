#!/usr/bin/env perl
#
# TagCategorizer Version 1.0
#
# Copyright (C) 2005  Fletcher T. Penney <http://fletcher.freeshell.org/>
# 
# Given a list of objects and their associated tags, use this information
# to develop a graph of the relationships between tags
#
# Inspired by an idea by Kaspar Schiess
#		http://eule.isa-geek.com/
#
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
#
# Input format:
#
# <taglist>
#	<object>
#		<id>unique id</id>
#		<tag>tag1</tag>
#		<tag>long tag</tag>
#	</object>
# </taglist>
#
# Output format:
#
# <tagHierarchy>
# 	<tag title="###">
#		<tag title="####">
#			<object>object identifier</object>
#		</tag>
#		<object>another object</object>
#	</tag>
# </tagHierarchy>
#

package TagCategorizer;

# Globals

my %g_processedSets = ();
my %g_synonyms = ();
my %g_hierarchy = ();
my %g_supersets = ();
my %g_subsets = ();
my %g_tagSets = ();

# Command-line version - import xml data as above
# Import stdin (xml format)
undef $/;
$data = <>;

if ($data ne "") {
	ProcessXML($data);
}

# Need a module version that allows direct access to
# the hash


sub ProcessXML{
	($xml) = @_;
	while ($xml =~ /\<object\>(.*?)\<\/object\>/gsi ) {
		$object = $1;
		
		if ($object =~ /\<id\>(.*?)\<\/id\>/s) {
			$id = $1;
			$id =~ s/^[ \t\n\r]*(.*?)[ \n\r]*$/$1/;
			$id =~ s/[ \t\n\r]/ /gs;
		} {
			while ($object =~ /\<tag\>(.*?)\<\/tag\>/gsi ) {
				$tag = $1;
				$tag =~ s/^[ \t\n\r]*(.*?)[ \n\r]*$/$1/;
				$tag =~ s/[ \t\n\r]/ /gs;
				$tag =~ s/"//g;		#"
				
				# Populate hash
				$g_tagSets{$tag}{$id} = 1;
			}
		}
	}
	
	# Now, process the parsed data
	ProcessSets(%g_tagSets);
}

sub PrintHash{
	(%theSets) = @_;
	foreach $tag ( sort keys %theSets ) {
		print "$tag\n";
		foreach $id (sort keys %{$theSets{$tag}} ) {
			print "\t$id\n";
		}
		print "\n";
	}
}

sub ProcessSets{
	(%rawSets) = @_;
		
	# Iterate through each set
	foreach $raw ( sort keys %rawSets ) {
		$isSynonym = 0;
		# Compare to processed sets
		foreach $processed (sort keys %g_processedSets) {
			next if $isSynonym;
			$subset = 
				IsSubset(\%{$rawSets{$raw}}, %{$g_processedSets{$processed}});
			$superset = 
				IsSubset(\%{$g_processedSets{$processed}}, %{$rawSets{$raw}});
			
			if ($superset && $subset) {
				# This is a synonym to another set
				$g_synonyms{$processed}{$raw} = 1;
				$isSynonym = 1;
			} else {
				# Only p
				if ( $subset ) {
					$g_supersets{$raw}{$processed} = 1;
					$g_subsets{$processed}{$raw} = 1;
				} 
				
				if ($superset) {
					$g_subsets{$raw}{$processed} = 1;
					$g_supersets{$processed}{$raw} = 1;
				}
			}
		}
		
		if (! $isSynonym) {
			# Add set to the processed hash
			%{$g_processedSets{$raw}} = %{$rawSets{$raw}};
		}
	}
	
	# Now, take the processed sets and compose a hierarchy
	
	# First, strip any synonyms that made it through
	PruneSynonyms();
	
	foreach $tag (sort keys %g_processedSets) {

		# Find all top-level items (e.g. no supersets)
		my $count = (keys %{$g_supersets{$tag}});
		if ($count == 0) {
			# This is a top-level item

			# Clean it up			
			PruneNode($tag);
		}
		
	}
	
	print "<?xml version=\"1.0\"?>\n";
	print PrintHierarchy();
}

sub IsSubset {
	# Is %$a a subset of %b?
	($a, %b) = @_;
		
	foreach $member (sort keys %$a) {
		return 0 if $b{$member} != 1;
	}
	return 1;
}

sub SynonymName {
	($tag) = @_;
	my $result = $tag;
	
	foreach (sort keys %{$g_synonyms{$tag}}) {
		$result .= "/" . $_;
	}
	
	return $result;	
}


sub PruneNode {
	# children/grandchildren should not be on same level
	# similarly, parents/grandparents should not be on same level
	($self) = @_;
	
	@descendants = (sort keys %{$g_subsets{$self}});
	
	foreach $a (@descendants) {
		foreach $b (@descendants) {
			next if ($a eq $b);
			if ($g_subsets{$a}{$b} == 1) {
				# $b is a subset of $a
				delete $g_subsets{$self}{$b}
			}
		}
	}
	
	# Now, tags of children should not be in parent

	foreach $child (sort keys %{$g_subsets{$self}}) {
		foreach (sort keys %{$g_tagSets{$child}}) {
			delete $g_tagSets{$self}{$_};
		}
	}
	
	# Now, do the same things for descendants
	
	foreach (sort keys %{$g_subsets{$self}}) {
		PruneNode($_);
	}
}

sub PrintHierarchy{
	my $result;
	my $tabs = "\t";	

	$result = "<tagHierarchy>\n";
	
	foreach $tag (sort {lc $a cmp lc $b} keys %g_processedSets) {

		# Find all top-level items (e.g. no supersets)
		my $count = (keys %{$g_supersets{$tag}});
		if ($count == 0) {
			$result.= PrintNode($tag,$tabs);
		}
	}

	$result .= "</tagHierarchy>\n";
	
	return $result;
}

sub PrintNode{
	my ($self, $tabs) = @_;
	my $result;
	
	$result .=  $tabs . "<tag title=\"" . SynonymName($self) . "\">\n";
	$tabs .= "\t";
	
	foreach (sort keys %{$g_subsets{$self}}) {
		$result .= PrintNode($_,$tabs);
	}
	
	foreach (sort keys %{$g_tagSets{$self}}) {
		$result .=  $tabs . "<object>" .$_ . "</object>\n";
	}

	$tabs =~ s/\t$//;
	
	$result .= $tabs . "</tag>\n";
	
	return $result;
}

sub PruneSynonyms{
	
	foreach (sort keys %g_synonyms) {
		foreach $synonym (sort keys %{$g_synonyms{$_}}) {
			foreach (sort keys %g_subsets) {
				delete $g_subsets{$_}{$synonym};
			}
		}
	}
}