# ABSTRACT: Configuration system for Debug::Fork::Tmux
package Debug::Fork::Tmux::Config;

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

# Makes constants possible
use Const::Fast;

# Withholds the Perl interpreter path
require Config;

# Rips directory name from fully-qualified file name (fqfn)
use File::Basename;

# Reads PATH environment variable into the array
use Env::Path;

### CONSTANTS ###
#
# Paths to search the 'tmux' binary
# Depends   :   On 'PATH' environment variable
const my @_DEFAULT_TMUX_PATHS => _default_tmux_path( Env::Path->PATH->List );

# Default 'tmux' binary fqfn
const my $_DEFAULT_TMUX_FQFN =>
    _default_tmux_fqfn( \@_DEFAULT_TMUX_PATHS => [ '' => '.exe' ], );

# Keep the configuration variables
my %_CONF;

# Tmux file name with full path
$_CONF{'tmux_fqfn'} = $_DEFAULT_TMUX_FQFN;

# Tmux 'neww' parameter for a system/shell command
$_CONF{'tmux_cmd_neww_exec'} = 'sleep 1000000';

# Tmux  'neww' command paraneters to be sprintf()'d with 'tmux_fqfn' and
# pushed after split by spaces the 'tmux_cmd_neww_exec' into list of
# parameters
$_CONF{'tmux_cmd_neww'} = "neww -P";

# Tmux command parameters to get a tty name
$_CONF{'tmux_cmd_tty'} = 'lsp -F #{pane_tty} -t';

# Takes deprecated SPUNGE_* environment variables into the account, too
_env_to_conf(
    \%_CONF => "SPUNGE_",
    sub {
        warn sprintf( "%s is deprecated and will be unsupported" => shift );
    }
);

# Take config override from %ENV
# Depends   :   On %ENV global of the main::
_env_to_conf( \%_CONF => "DF" );

# Make configuration unchangeable
const %_CONF => %_CONF;

### ATTRIBUTES ###
#

### SUBS ###
#
# Function
# Reads environment to config
# Takes     :   HashRef[Str] configuration to read;
#               Str environment variables' prefix to read config from;
#               Optional CodeRef to evaluate with environment variable name
#               as an argument.
# Depends   :   On configuration HashRef's keys and the corresponding
#               environment variables
# Changes   :   Configuration HashRef supplied as an argument
# Outputs   :   From CodeRef if supplied to warn to STDOUT about SPUNGE_*
#               deprecation
# Returns   :   n/a
sub _env_to_conf {
    my $conf   = shift;
    my $prefix = shift;
    my $cref   = shift || undef;

    foreach my $key ( keys %$conf ) {

        # Key for %ENV
        my $env_key = $prefix . uc $key;

        # For no key in environment do nothing
        next unless defined $ENV{$env_key};

        # Sub warns about deprecation
        if ( defined $cref ) { $cref->($env_key); }

        # Real config change
        $conf->{$key} = $ENV{$env_key};
    }
}

# Function
# Finds default 'tmux' binary fully qualified fila name
# Takes     :   ArrayRef[Str] paths to search for 'tmux' binary
#               ArrayRef[Str] suffixes of the binaries to search
# Depends   :   On 'tmux' binaries found in the system
# Requires  :   File::Spec module
# Returns   :   Str fully qualified file name of the 'tmux' binary, or just
#               'tmux' if no such binary was found
sub _default_tmux_fqfn {
    my ( $paths => $suffixes ) = @_;
    my $fqfn;

    foreach my $path (@$paths) {
        my $fname;

        # Binary without prefix
        foreach my $suffix (@$suffixes) {
            $fname = File::Spec->catfile( $path, "tmux$suffix" );
            if ( -x $fname ) {
                $fqfn = $fname;
                last;    # foreach my $suffix
            }
        }

        # Fall back if no binary found in the default paths
        $fqfn = 'tmux' unless defined $fqfn;

        last if defined $fqfn;    # foreach my @$paths
    }

    return $fqfn;
}

# Function
# Paths to search the 'tmux' binary in
# Takes     :   Array[Str] contents of the PATH environment variable
# Depends   :   On the current directory and Perl interpreter path
# Requires  :   Cwd, File::Basename, Config modules
# Returns   :   Array[Str] ordered unique path to search for 'tmux' binary
#               except that was configured with environment variable
sub _default_tmux_path {
    my @paths = @_;

    # Additional paths to search for Tmux
    my @paths_add
        = map { Cwd::realpath($_) }
        File::Basename::dirname( $Config::Config{'perlpath'} ),
        '.';
    push @paths, @paths_add;

    # Filter out dupes
    my %seen = ();
    @paths = grep { !$seen{$_}++ } @paths;

    return @paths;
}

# Static method
# Returns Str argument configured as a key supplied as an argument
# Takes     :   Str argument to read config for
# Depends   :   On %_CONF package lexical
# Requires  :   Carp
# Throws    :   If no configuration found for an argument
# Returns   :   %_CONF element for an argument
sub get_config {
    shift;
    my $key = shift;

    croak("Undefined in a configuration: $key") unless defined $_CONF{$key};

    return $_CONF{$key};
}

# Static method
# Takes     :   n/a
# Depends   :   On %_CONF package lexical
# Returns   :   Array keys of %_CONF package lexical
sub get_all_config_keys { return keys %_CONF }

# Returns true to require()
1;

__END__

=pod

=head1 SYNOPSIS

    use Debug::Fork::Tmux;

    my $tmux_fqfn = Debug::Fork::Tmux->config( 'tmux_fqfn' );

=head1 DESCRIPTION

This module reads description from environment variables and use defaults if
those are not set.

For example C<tmux_fqfn> can be overridden with C<DFTMUX_FQFN>
variable, and so on.

The C<SPUNGE_*> variables are supported yet but deprecated and will be
removed.

=head1 SUBROUTINES/METHODS

All of the following are static methods:

=pubsub C<get_config( Str the name of the option )>

Retrieves configuration stored in an internal C<Debug::Fork::Tmux::Config>
constants.

Returns C<Str> value of the configuration parameter.

=sub C<get_all_config_keys()>

Returns C<Array[Str]> names of all the configuration parameters.

=cut

=head1 DIAGNOSTICS

=over

=item C<Undefined in a configuration: E<lt>keyE<gt>>

Dies if no key asked was found in the configuration.

=back

=head1 CONFIGURATION AND ENVIRONMENT

See L<Debug::Fork::Tmux/CONFIGURATION AND ENVIRONMENT>.

=cut

