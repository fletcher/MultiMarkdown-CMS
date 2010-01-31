package Lingua::Stem::AutoLoader;

# $RCSfile: AutoLoader.pm,v $ $Revision: 1.2 $ $Date: 1999/06/17 21:59:24 $ $Author: snowhare $

=head1 NAME

Lingua::Stem::AutoLoader - A manager for autoloading Lingua::Stem modules

=head1 SYNOPSIS

use Lingua::Stem::AutoLoader;

=head1 DESCRIPTION

Sets up the autoloader to load the modules in the Lingua::Stem system on demand.

 Lingua::Stem::Da - Danish
 Lingua::Stem::De - German
 Lingua::Stem::En - English
 Lingua::Stem::Fr - French 
 Lingua::Stem::Gl - Galician
 Lingua::Stem::It - Italian
 Lingua::Stem::No - Norwegian
 Lingua::Stem::Ru - Rusian 
 Lingua::Stem::Pt - Portuguese
 Lingua::Stem::Sv - Swedish

=head1 CHANGES

 1.03 2004.07.25 - Added 'Lingua::Stem::Ru'

 1.02 2004.04.26 - Added 'Lingua::Stem::Fr'

 1.01 2003.04.05 - Added 'Lingua::Stem::De',   'Lingua::Stem::Da',
                         'Lingua::Stem::Gl',   'Lingua::Stem::It',
                         'Lingua::Stem::No',   'Lingua::Stem::Pt',
                         'Lingua::Stem::Sv',

                   to the list of autoloaded modules.

=cut

use strict;
use vars qw($VERSION $AUTOLOAD);

$VERSION = "1.02";

my $_autoloaded_functions = {};

my @packageslist = (
	'Lingua::Stem::De',
	'Lingua::Stem::En',
	'Lingua::Stem::Fr',
	'Lingua::Stem::Da',
	'Lingua::Stem::Gl',
	'Lingua::Stem::It',
	'Lingua::Stem::No',
	'Lingua::Stem::Pt',
	'Lingua::Stem::Sv',
	'Lingua::Stem::EnBroken',
);

my $autoloader =<<'EOF';
package ----packagename----;
use vars qw($AUTOLOAD);
sub AUTOLOAD {
	return if ($AUTOLOAD =~ m/::(END|DESTROY)$/o);
    if (exists $_autoloaded_functions->{$AUTOLOAD}) {
        die("Attempted to autoload function '$AUTOLOAD' more than once - does it exist?\n");
    }
    $_autoloaded_functions->{$AUTOLOAD} = 1;
    my ($packagename) = $AUTOLOAD =~ m/^(.*)::[A-Z_][A-Z0-9_]*$/ois;
    eval ("use $packagename;");
    if ($@ ne '') {
        die ("Unable to use packagename: $@\n");
    }
    goto &$AUTOLOAD;
}

EOF

my $fullload = '';
foreach my $packagename (@packageslist) {
	my ($loader) = $autoloader;
	$loader =~ s/(----packagename----)/$packagename/;
	$fullload .= $loader;
}
eval $fullload;
if ($@ ne '') {
   die ("Failed to initialize AUTOLOAD: $@\n");
}

=head1 COPYRIGHT

Copyright 1999, Benjamin Franz (<URL:http://www.nihongo.org/snowhare/>) and
FreeRun Technologies, Inc. (<URL:http://www.freeruntech.com/>). All Rights Reserved.
This software may be copied or redistributed under the same terms as Perl itelf.

=head1 AUTHOR

Benjamin Franz

=head1 TODO

Nothing.

=cut

1;
