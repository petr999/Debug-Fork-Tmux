#!/usr/bin/env perl
# Tests if all perl files are ok and use strict

use strict;
use warnings;

### MODULES ###
#
# Makes this test a test
use Test::Strict;

# Can walk through directory finding the files
use File::Find;

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Directories for full check of the sources
const my @CHECK_ALL_OK => qw/lib t/;

# Directories for full check of the sources
const my @CHECK_SYNTAX_ONLY => grep { -d $_ } qw/xt/;

### MAIN ###
#
# Check syntax, strict and warnings, too
# Requires  :   Test::Strict
# Depends   :   On @CHECK_ALL_OK lexical
all_perl_files_ok(@CHECK_ALL_OK);

# Walk through every directory for a syntax check
# Requires  :   File::Find, Test::Strict
# Depends   :   On @CHECK_SYNTAX_ONLY lexical
if ( 0 + @CHECK_SYNTAX_ONLY ) {
    File::Find::find(
        sub {
            if ( -f $File::Find::name ) {
                syntax_ok($File::Find::name);
            }
        } => @CHECK_SYNTAX_ONLY,
    );
}
