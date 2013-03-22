#!/usr/bin/env perl
# Tests if all perl files are ok and use strict
#
# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Makes this test a test
use Test::Strict;

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Directories for full check of the sources
const my @CHECK_ALL_OK => qw/lib t/;

# Directories for full check of the sources
const my @CHECK_SYNTAX_ONLY => grep { -d $_ } qw/xt/;

### MAIN ###
# Requires  :   Test::Strict
#
# Check syntax, strict and warnings, too
# Depends   :   On @CHECK_ALL_OK lexical
{
    local $Test::Strict::TEST_WARNINGS = 1;
    all_perl_files_ok(@CHECK_ALL_OK);
}

# Check syntax of other perl files
# Depends   :   On @CHECK_SYNTAX_ONLY lexical
if (@CHECK_SYNTAX_ONLY) {
    local $Test::Strict::TEST_STRICT = '';
    all_perl_files_ok(@CHECK_SYNTAX_ONLY);
}
