# ABSTRACT: Makes fork() in debugger to open a new Tmux window
package Spunge::DB;

# VERSION

# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Glues up path components
use File::Spec;

# Resolves up symlinks
use Cwd;

# Dioes in a nicer way
use Carp;

# Makes constants possible
use Const::Fast;

### CONSTANTS ###
#
# Path to the 'tmux' binary
# Requires  :   Cwd
const my $TMUX_PATH => Cwd::realpath('/usr/local/bin');

# 'tmux' binary itself
# Depends   :   On $TMUX_PATH
# Requires  :   File::Spec
const my $TMUX_BIN => File::Spec->catfile( $TMUX_PATH => 'tmux' );

# 'tmux' command for a new window returning the 'tmux id' for the window
const my @TMUX_CMD_NEWW =>
    ( $TMUX_BIN => ( 'new-window' => '-P', 'sleep 1000000' ), );

# 'tmux' command for output of a tty name of the window supplied.
const my @TMUX_CMD_TTY =>
    ( $TMUX_BIN => ( qw/lsp -F/, '#{pane_tty}', '-t' ) );

### SUBS ###
#
# Function
# Gets the tty name, sets the $DB::fork_TTY to it and returns it.
# Takes     :   n/a
# Requires  :   DB, Spunge::DB
# Overrides :   DB::get_fork_TTY()
# Changes   :   $DB::fork_TTY
# Returns   :   Str tty name $DB::fork_TTY
sub DB::get_fork_TTY {

    # Create a TTY
    my $tty_name = Spunge::DB::spawn_tty();

    # Output the name both to a variable and to the caller
    no warnings qw/once/;
    $DB::fork_TTY = $tty_name;
    return $tty_name;
}

# Function
# Spawns a TTY and returns its name
# Takes     :   n/a
# Returns   :   Str tty name
sub spawn_tty {

    # Create window and get its tty name
    my $window_id = tmux_new_window();
    my $tty_name  = tmux_window_tty($window_id);

    return $tty_name;
}

# Function
# Creates new 'tmux' window  and returns its id/number
# Takes     :   n/a
# Depends   :   On @TMUX_CMD_NEWW package lexical
# Returns   :   Str id/number of the created 'tmux' window
sub tmux_new_window {
    my $window_id = read_from_cmd(@TMUX_CMD_NEWW);

    return $window_id;
}

# Function
# Gets a 'tty' name from 'tmux's window id/number
# Takes     :   Str 'tmux' window id/number
# Depends   :   On @TMUX_CMD_TTY package lexical
# Returns   :   Str 'tty' device name of the 'tmux' window
sub tmux_window_tty {
    my $window_id = shift;

    # Concatenate the 'tmux' command and read its output
    my @tmux_cmd = ( @TMUX_CMD_TTY, $window_id );
    my $tty_name = read_from_cmd(@tmux_cmd);

    return $tty_name;
}

# Function
# Reads the output of a command supplied with parameters as the argument(s)
# and returns its output.
# Takes     :   Array[Str] command and its parameters
# Throws    :   If command failed or the output is not the non-empty Str
#               single line
# Returns   :   Output of the command supplied with parameters as arguments
sub read_from_cmd {
    my @cmd_and_args = @_;

    # Open the pipe to read
    croak_on_cmd( @cmd_and_args, "failed opening command: $!" )
        unless open my $cmd_output_fh => '-|',
        @cmd_and_args;

    # Read a line from the command
    croak_on_cmd( @cmd_and_args, "didn't write a line" )
        unless defined($cmd_output_fh)
        and ( 0 != $cmd_output_fh )
        and my $cmd_out = <$cmd_output_fh>;

    # If still a byte is readable then die as the file handle should be
    # closed already
    my $read_rv = read $cmd_output_fh => my $buf, 1;
    croak_on_cmd( @cmd_and_args, "failed reading command: $!" )
        unless defined $read_rv;
    croak_on_cmd( @cmd_and_args, "did not finish" ) unless 0 == $read_rv;

    # Die on empty output
    chomp $cmd_out;
    croak_on_cmd( @cmd_and_args, "provided empty string" )
        unless length $cmd_out;

    return $cmd_out;
}

# Function
# Croaks nicely on the command with an explanation based on arguments and $?
# Takes     :   Array[Str] system command, its arguments, and an explanation
#               on the situation when the command failed
# Requires  :   Carp
# Depends   :   On $? global variable set by system command failure
# Throws    :   Always
# Returns   :   n/a
sub croak_on_cmd {
    my @cmd_args_msg = @_;

    if ( defined $? ) {
        my $msg = '';

        # Depending on $?, add it to the death note
        # Command may be a not-executable
        if ( $? == -1 ) {
            $msg = "failed to execute: $!";
        }

        # Command can be killed
        elsif ( $? & 127 ) {
            $msg = sprintf "child died with signal %d, %s coredump",
                ( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
        }

        # Command may return the exit code for clearance
        else {
            $msg = sprintf "child exited with value %d", $? >> 8;
        }

        # And the message can be returned as an appendix to the original
        # arguments
        push @cmd_args_msg, $msg;
    }

    # Report the datails via the Carp
    my $croak_msg = "The command " . join ' ' => @cmd_args_msg;
    croak($croak_msg);
}

# Returns true to require()
1;

__END__

=pod

=head1 SYNOPSIS

As a helper for the debugger, the module should be used this way:

    perl -MSpunge::DB -d your_script.pl

You should run it from inside the C<tmux> window manager.

=head1 DESCRIPTION

The Perl's standard debugger requires additional stuff when the debugged
Perl program use the L<fork()|perlfunc/fork> built-in.

This module is about to solve the trouble which visible like this:

  ######### Forked, but do not know how to create a new TTY. #########
  Since two debuggers fight for the same TTY, input is severely entangled.

  I know how to switch the output to a different window in xterms, OS/2
  consoles, and Mac OS X Terminal.app only.  For a manual switch, put the
  name of the created TTY in $DB::fork_TTY, or define a function
  DB::get_fork_TTY() returning this.

  On UNIX-like systems one can get the name of a TTY for the given window
  by typing tty, and disconnect the shell from TTY by sleep 1000000.

C<OS/2> is a fun for me but in the past. C<Mac OS X> is a more chance but
still isn't real. And for C<xterm> ... who wants to keep it on your server?
Gimme some stones to throw on that one.

But the pseudo-terminal device isn't much about C<GUI>s by its nature so the
problem behind the bars of the L<perl5db.pl> report ( see more detailed
problem description at the L<PerlMonks
thread|http://perlmonks.org/?node_id=128283> ) is the consoles management.
It's a kind of a tricky, for example, to start the next C<ssh> session
initiated from the machine serving as an C<sshd> server for the existing
session.

Thus we kind of have to give a chance to the consoles management with
a software capable to run on a server machine without as much dependencies
as an C<xterm>. This module is a try to pick the L<Tmux|http://tmux.sf.net>
windows manager for such a task.

=head1 CONSTANTS

=const C<$TMUX_PATH>

C<Str> path to the C<tmux> binary.

=const C<$TMUX_BIN>

C<Str> the C<tmux> binary fully qualified file name.

=const C<@TMUX_CMD_NEWW>

C<Array[Str]> the L<system()|perlfunc/system> arguments for a C<tmux>
command for opening a new window and with output of a window address in
C<tmux>.

=const C<@TMUX_CMD_TTY>

C<Array[Str]> the L<system()|perlfunc/system> arguments for a  C<tmux>
command for finding a C<tty> name in the output.  Expects C<tmux>'s window
address as the very last argument.

=head1 SUBROUTINES/METHODS

All of the following are functions:

=pubsub C<DB::get_fork_TTY()>

Finds new C<TTY> for the C<fork()>ed process.

Takes no arguments. Returns C<Str> name of the C<tty> device of the <tmux>'s
new window created for the debugger's new process.

Sets the C<$DB::fork_TTY> to the same C<Str> value.

=sub C<spawn_tty()>

Creates a C<TTY> device and returns C<Str> its name.

=sub C<tmux_new_window()>

Creates a given C<tmux> window and returns C<Str> its id/number.

=sub C<tmux_window_tty( $window_id )>

Checks for a given C<tmux> window's tty name and returns its C<Str> name.

=sub C<read_from_cmd( $cmd =E<gt> @args )>

Takes the list containing the C<Str> L<system()|perlfunc/system> command and
C<Array> its arguments and executes it. Reads Str the output and returns it.
Throws if no output or if the command failed.

=sub C<croak_on_cmd( $cmd =E<gt> @args, $happen )>

Takes the C<Str> command, C<Array> its arguments and C<Str> the reason of
its failure, examines the C<$?> and dies with explanation on the
L<system()|perlfunc/system> command failure.

=head1 DIAGNOSTICS

=over

=item The command ...

Typically the error message starts with the command the L<Spunge::DB> tried
to execute, including the command's arguments.

=item failed opening command: ...

The command was not taken by the system as an executable binary file.

=item ... didn't write a line

=item failed reading command: ...

Command did not output exactly one line of the text.

=item ... did not finish

Command outputs more than one line of the text.

=item provided empty string

Command outputs exactly one line of the text and the line is empty.

=item failed to execute: ...

There was failure executing the command

=item child died with(out) signal X, Y coredump

Command was killed by the signal X and the coredump is (not) located in Y.

=item child exited with value X

Command was not failed but there are reasons to throw an error like the
wrong command's output.

=back


=head1 DEPENDENCIES

* L<Config>
is available in core C<Perl> distribution since version 5.3.7

* L<Module::Build>
is available in core C<Perl> distribution since version 5.9.4

* L<Scalar::Util>
is available in core C<Perl> distribution since version 5.7.3

* L<Sort::Versions>
is available from C<CPAN>

* L<Test::Exception>
is available from C<CPAN>

* L<Test::More>
is available in core C<Perl> distribution since version 5.6.2

* L<Test::Most>
is available from C<CPAN>

* L<Test::Strict>
is available from C<CPAN>

* L<autodie>
is available in core C<Perl> distribution since version 5.10.1

* L<ExtUtils::MakeMaker>
is available in core C<Perl> distribution since version 5

* L<Module::Build>
is available in core C<Perl> distribution since version 5.9.4

* L<File::Spec>
is available in core C<Perl> distribution since version 5.4.5

* L<Cwd>
is available in core C<Perl> distribution since version 5

* L<Const::Fast>
is available from C<CPAN>

=head1 CONFIGURATION AND ENVIRONMENT

The module requires the L<Tmux|http://tmux.sf.net> window manager for the
console to be present in the system.

For some while, the configuration is made via the package lexical
L<constants|/CONSTANTS>.

=cut
