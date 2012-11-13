# ABSTRACT: Makes fork() in debugger to open a new Tmux window
package Debug::Fork::Tmux;

# Helps you to behave
use strict;
use warnings;

# VERSION
#
### MODULES ###
#
# Glues up path components
use File::Spec;

# Resolves up symlinks
use Cwd;

# Dioes in a nicer way
use Carp;

# Reads configuration
use Debug::Fork::Tmux::Config;

# Makes constants possible
use Const::Fast;

### CONSTANTS ###
#

### SUBS ###
#
# Function
# Gets the tty name, sets the $DB::fork_TTY to it and returns it.
# Takes     :   n/a
# Requires  :   DB, Debug::Fork::Tmux
# Overrides :   DB::get_fork_TTY()
# Changes   :   $DB::fork_TTY
# Returns   :   Str tty name $DB::fork_TTY
sub DB::get_fork_TTY {

    # Create a TTY
    my $tty_name = Debug::Fork::Tmux::_spawn_tty();

    # Output the name both to a variable and to the caller
    no warnings qw/once/;
    $DB::fork_TTY = $tty_name;
    return $tty_name;
}

# Function
# Spawns a TTY and returns its name
# Takes     :   n/a
# Returns   :   Str tty name
sub _spawn_tty {

    # Create window and get its tty name
    my $window_id = _tmux_new_window();
    my $tty_name  = _tmux_window_tty($window_id);

    return $tty_name;
}

# Function
# Creates new 'tmux' window  and returns its id/number
# Takes     :   n/a
# Depends   :   On 'tmux_fqdn', 'tmux_neww', 'tmux_neww_exec' configuration
#               parameters
# Returns   :   Str id/number of the created 'tmux' window
sub _tmux_new_window {
    my @cmd_to_read = (
        Debug::Fork::Tmux::Config->get_config('tmux_fqdn'),
        split(
            /\s+/, Debug::Fork::Tmux::Config->get_config('tmux_cmd_neww')
        ),
        Debug::Fork::Tmux::Config->get_config('tmux_cmd_neww_exec'),
    );

    my $window_id = _read_from_cmd(@cmd_to_read);

    return $window_id;
}

# Function
# Gets a 'tty' name from 'tmux's window id/number
# Takes     :   Str 'tmux' window id/number
# Depends   :   On 'tmux_fqdn', 'tmux_cmd_tty' configuration parameters
# Returns   :   Str 'tty' device name of the 'tmux' window
sub _tmux_window_tty {
    my $window_id = shift;

    # Concatenate the 'tmux' command and read its output
    my @cmd_to_read = (
        Debug::Fork::Tmux::Config->get_config('tmux_fqdn'),
        split( /\s+/, Debug::Fork::Tmux::Config->get_config('tmux_cmd_tty') ),
        $window_id,
    );
    my @tmux_cmd = (@cmd_to_read);
    my $tty_name = _read_from_cmd(@tmux_cmd);

    return $tty_name;
}

# Function
# Reads the output of a command supplied with parameters as the argument(s)
# and returns its output.
# Takes     :   Array[Str] command and its parameters
# Throws    :   If command failed or the output is not the non-empty Str
#               single line
# Returns   :   Output of the command supplied with parameters as arguments
sub _read_from_cmd {
    my @cmd_and_args = @_;

    # Open the pipe to read
    _croak_on_cmd( @cmd_and_args, "failed opening command: $!" )
        unless open my $cmd_output_fh => '-|',
        @cmd_and_args;

    # Read a line from the command
    _croak_on_cmd( @cmd_and_args, "didn't write a line" )
        unless defined($cmd_output_fh)
        and ( 0 != $cmd_output_fh )
        and my $cmd_out = <$cmd_output_fh>;

    # If still a byte is readable then die as the file handle should be
    # closed already
    my $read_rv = read $cmd_output_fh => my $buf, 1;
    _croak_on_cmd( @cmd_and_args, "failed reading command: $!/$buf" )
        unless defined $read_rv;
    _croak_on_cmd( @cmd_and_args, "did not finish: $buf" )
        unless 0 == $read_rv;

    # Die on empty output
    chomp $cmd_out;
    _croak_on_cmd( @cmd_and_args, "provided empty string" )
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
sub _croak_on_cmd {
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

    #!/usr/bin/perl -d
    #
    # ABSTRACT: Debug the fork()-contained code in this file
    #
    # Make fork()s debuggable with Tmux
    use Debug::Fork::Tmux;

    # See what happens in your debugger then...
    fork;

=head1 DESCRIPTION

The real usage example of this module is:

    perl -MDebug::Fork::Tmux -d your_script.pl

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


=head1 SUBROUTINES/METHODS

All of the following are functions:

=pubsub C<DB::get_fork_TTY()>

Finds new C<TTY> for the C<fork()>ed process.

Takes no arguments. Returns C<Str> name of the C<tty> device of the <tmux>'s
new window created for the debugger's new process.

Sets the C<$DB::fork_TTY> to the same C<Str> value.

=sub C<_spawn_tty()>

Creates a C<TTY> device and returns C<Str> its name.

=sub C<_tmux_new_window()>

Creates a given C<tmux> window and returns C<Str> its id/number.

=sub C<_tmux_window_tty( $window_id )>

Finds a given C<tmux> window's tty name and returns its C<Str> name based on
a given window id/number typically from L</_tmux_new_window()>.

=sub C<_read_from_cmd( $cmd =E<gt> @args )>

Takes the list containing the C<Str> L<system()|perlfunc/system> command and
C<Array> its arguments and executes it. Reads C<Str> the output and returns it.
Throws if no output or if the command failed.

=sub C<_croak_on_cmd( $cmd =E<gt> @args, $happen )>

Takes the C<Str> command, C<Array> its arguments and C<Str> the reason of
its failure, examines the C<$?> and dies with explanation on the
L<system()|perlfunc/system> command failure.

=head1 DIAGNOSTICS

=over

=item The command ...

Typically the error message starts with the command the L<Debug::Fork::Tmux> tried
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

* C<Perl 5.6.0+>
is available from L<The Perl website|http://www.perl.org>

* L<Config>, L<Cwd>, L<DB>, L<ExtUtils::MakeMaker>, L<File::Find>,
L<File::Spec> are available in core C<Perl> distribution version 5.6.0 and
later

* L<Const::Fast>
is available from C<CPAN>

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

* C<Tmux> v1.6+
is available from L<The Tmux website|http://tmux.sourceforge.net>

Most of them can easily be found in your operating system
distribution/repository.

=head1 CONFIGURATION AND ENVIRONMENT

The module requires the L<Tmux|http://tmux.sf.net> window manager for the
console to be present in the system.

Configuration is made via environment variables, the default is taken for
each of them with no such variable is set in the environment:

=head2 C<SPUNGE_TMUX_FQDN>

The C<tmux> binary name with the full path.

Default :   C</usr/local/bin/tmux>

=head2 C<SPUNGE_TMUX_CMD_NEWW>

The L<system()|perlfunc/system> arguments for a C<tmux>
command for opening a new window and with output of a window address from
C<tmux>. String is sliced by spaces to be a list of parameters.

Default :  C<neww -P>

=head2 C<SPUNGE_TMUX_CMD_NEWW_EXEC>

The L<system()|perlfunc/system> or a shell command to be given to the
C<SPUNGE_TMUX_CMD_NEWW> command to be executed in a brand new created
window. It should wait unexpectedly and do nothing till the debugger
catches the device and puts in into the proper use.

Default :  C<sleep 1000000>

=head2 C<SPUNGE_TMUX_CMD_TTY>

Command- line  parameter(s) for a  C<tmux> command to find a C<tty> name in
the output. The string is sliced then by spaces. The C<tmux>'s window
address is added then as the very last argument.

Default :  C<lsp -F #{pane_tty} -t>

=head1 WEB SITE

The web site of
L<Debug::Fork::Tmux|http://gitweb.vereshagin.org/Debug-Fork-Tmux/README.html> currently
consists of only one page cause it's a very small module.

=begin stopwords

Tmux LICENCE MERCHANTABILITY PerlMonks Tmux

=end stopwords

=cut
