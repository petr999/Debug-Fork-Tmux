#!/usr/bin/env perl
# Tests tmux-related stuff for Spunge::DB.
#
# Copyright (C) 2012 Peter Vereshagin <peter@vereshagin.org>
# All rights reserved.
#

# Helps you to behave
use strict;
use warnings;

# Throws exceptions on i/o
use autodie;

### MODULES ###
#
# Makes this test a test
use Test::Most qw/bail/;    # BAIL_OUT() on any failure

# Loads main app module
use Spunge::DB;

# Catches exceptions
use Test::Exception;

# Can compare version numbers
use Sort::Versions;

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Match 'tmux -V' to get a version number
const my $TMUX_VERSION_RGX => qr/^(.*[-\s])?((\d+\.\d+)(\.\d+)*)$/;

# Minimum tmux version for Spunge::DB to work with
const my $TMUX_MIN_VERSION => 1.6;

# The what the device name returned from Tmuxs hould look like
const my $TMUX_TTY_RGX =>
    qr/^(([\w\d\/]*[\w\d]\/)?\w+ty[\w\d]+)|((\/dev\/pts\/)?\d+)$/;

### MAIN ###
# Require   :   Test::Most, Test::Exception
#
# Determine if it's not under tmux
# Depends   :   On %ENV global
is( $ENV{'TERM'} => 'screen', 'Appropriate environment for tmux' );
lives_ok { system "tmux -V 2>&1 > /dev/null" } 'tmux is found in the system';

# Reads output of 'tmux' for various situations
lives_and {

    my ( $buf_str => @buf_strings, $fh );

    # Read version number
    open $fh => '-|', 'tmux' => '-V';    # autodie
    $buf_str = do { local $/ = undef; <$fh>; };    # autodie
    close $fh;

    # Read the version
    # Depends   :   On Test::Most->import qw/bail/ );
    @buf_strings = split /\r*\n\r*/, $buf_str;
    is( @buf_strings => 1,
        "The command 'tmux -V' provides a single line of the text"
    );
    $buf_str = shift @buf_strings;
    ok( defined($buf_str) =>
            "The command 'tmux -V' provides a defined value" );
    chomp $buf_str;
    isnt(
        length($buf_str) => 0,
        "The command 'tmux -V' outputs a non-empty string"
    );
    like(
        $buf_str => $TMUX_VERSION_RGX,
        "The command 'tmux -V' matches a version regex"
    );

    # Ensure the minimum Tmux version requirement
    # $2 is defined according to regex
    # Requires  :   Sort::Versions
    $buf_str =~ $TMUX_VERSION_RGX;    # tested with like() already
    my $version = $2;
    isnt(
        Sort::Versions::versioncmp( $version => $TMUX_MIN_VERSION ) => -1,
        "Tmux version '$version' is not less than the minimum"
            . " '$TMUX_MIN_VERSION'"
    );

    # Read session info
    open $fh => '-|', 'tmux' => 'info';    # autodie
    $buf_str = do { local $/ = undef; <$fh>; };    # autodie
    close $fh;

    @buf_strings = split /\r*\n\r*/, $buf_str;
    cmp_ok( @buf_strings, '>', 1,
        "The command 'tmux info' provides several lines of the text" );
}
'Tmux commands execution';

lives_and {
    my ( $window_id => $window_tty );

    # Create window and kill it
    ok( $window_id
            = Spunge::DB::_read_from_cmd( qw/tmux neww -P/,
            'sleep 1000000' ) => "Created window: $window_id" );
    ok( length($window_id) => 'window id is not empty' );
    ok( $window_tty = Spunge::DB::_read_from_cmd(
            qw/tmux lsp -F/ => '#{pane_tty}',
            '-t'            => $window_id,
        ) => "Found a tty $window_tty for a Tmux window: $window_id"
    );

    system( qw/tmux killw -t/, $window_id );
    is( ${^CHILD_ERROR_NATIVE} => 0, "killed window: $window_id" );

    # Create window with Spounge::DB and kill it
    ok( $window_id = Spunge::DB::_tmux_new_window(),
        "Spunge::DB created a Tmux window: $window_id",
    );
    ok( $window_tty = Spunge::DB::_tmux_window_tty($window_id),
        "Spunge::DB found a tty $window_tty for a Tmux window: $window_id",
    );
    ok( length($window_id)  => 'window id is not empty' );
    ok( length($window_tty) => 'window tty is not empty' );
    like(
        $window_tty => $TMUX_TTY_RGX,
        "window tty '$window_tty' looks like a pseudo-terminal device"
    );

    system( qw/tmux killw -t/, $window_id );
    is( ${^CHILD_ERROR_NATIVE} => 0, "killed window: $window_id" );
}
'Tmux window manipulation';

# Continues till this point
# Requires  :   Test::Most
done_testing();
