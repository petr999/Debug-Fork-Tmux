#!/usr/bin/env perl
# Tests configuration variables and their correspondence to environment.
#
# Copyright (C) 2012 Peter Vereshagin <peter@vereshagin.org>
# All rights reserved.
#

# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Makes this test a test
use Test::Most qw/bail/;    # BAIL_OUT() on any failure

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Keys to get configuration for
# Should be sync'ed with Spunge::DB::Config->get_all_config_keys
const my @CONF_KEYS =>
    qw/tmux_fqdn tmux_cmd_neww_exec tmux_cmd_neww tmux_cmd_tty/;

# Keys to put environment into
const my %CONF_PAIRS => map { $_ => $_ . "_value" } @CONF_KEYS;

# Environment variables those influence configuration settings
# Depends   :   On @CONF_KEYS, @CONF_VALUES package lexicals
my %ENV_VARS;

# %ENV_VARS are based on %CONF_PAIRS but keys are uppercase and with the
# 'SPUNGE_' prefix
while ( my ( $key => $value ) = each %CONF_PAIRS ) {
    $key = "SPUNGE_" . uc $key;
    $ENV_VARS{$key} = $value;
}

const %ENV_VARS => %ENV_VARS;

### MAIN ###
# Require   :   Test::Most, Spunge::DB::Config
#
# Set up environment, localize it first
# Depends   :   On %ENV global of main::, %ENV_VARS package lexical
# Changes   :   %ENV localized global of main::
local %ENV = %ENV_VARS;
# keep from change the system environment

# Loads main app module
use_ok('Spunge::DB::Config');    # Environment variables set up clean

# Check if config keys are in sync
my @all_config_keys = Spunge::DB::Config->get_all_config_keys;
cmp_bag( \@all_config_keys => \@CONF_KEYS,
    'This test keeps config keys in sync' );

while ( my ( $key => $value ) = each %CONF_PAIRS ) {
    ok( $value = Spunge::DB::Config->get_config($key) =>
            "Get config for '$key'" );
    is( ref($value) => '', "Value for '$key' is a scalar" );
    ok( length($value) => "Value for '$key' is non-empty" );
    is( ref($value) => '', "Value for '$key' is a scalar" );

    # Compare ->get_config() result with %ENV element
    is( $value => $CONF_PAIRS{ $key },
        "Value for '$key' from config is as expected from %ENV",
    );
}

# Continues till this point
done_testing();
