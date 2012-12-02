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

### CONSTANTS ###
#
# Paths to search the 'tmux' binary
# Depends   :   On %::ENV main global
# Requires  :   Cwd, File::Basename
my @_DEFAULT_TMUX_PATHS => map { Cwd::realpath($_) }
    File::Basename::dirname( $Config::Config{'perlpath'} ),
    '.';
if ( defined $ENV{'PATH'} ) {
    my @paths = map { Cwd::realpath($_) } split /:/, $ENV{'PATH'};
    unshift @_DEFAULT_TMUX_PATHS, @paths;
}

# Unique and constant
{
    my %seen = ();
    @_DEFAULT_TMUX_PATHS = grep { !$seen{$_}++ } @_DEFAULT_TMUX_PATHS;
}
const @_DEFAULT_TMUX_PATHS => @_DEFAULT_TMUX_PATHS;

# Default 'tmux' binary fqfn
# Depends   :   On @_DEFAULT_TMUX_PATHS
# Requires  :   File::Spec
my $_DEFAULT_TMUX_FQFN;
foreach my $path (@_DEFAULT_TMUX_PATHS) {
    my $fname;

    # Binary without prefix
    foreach my $suffix ( '' => '.exe' ) {
        $fname = File::Spec->catfile( @_DEFAULT_TMUX_PATHS, "tmux$suffix" );
        if ( -x $fname ) {
            $_DEFAULT_TMUX_FQFN = $fname;
            last;    # foreach my $suffix
        }
    }

    last if defined $_DEFAULT_TMUX_FQFN;    # foreach my $path
}

# Fall back if no binary found in the default paths
$_DEFAULT_TMUX_FQFN = 'tmux' unless defined $_DEFAULT_TMUX_FQFN;

# Make unchangeable
const $_DEFAULT_TMUX_FQFN => $_DEFAULT_TMUX_FQFN;

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

# Take config override from %ENV
# Depends   :   On %ENV global of the main::
foreach my $key ( keys %_CONF ) {

    # Key for %ENV
    my $env_key = "DF" . uc $key;

    next unless defined $ENV{$env_key};

    $_CONF{$key} = $ENV{$env_key};
}

# Takes deprecated SPUNGE_* environment variables into the account, too
foreach my $key ( keys %_CONF ) {

    # Key for %ENV
    my $env_key = "SPUNGE_" . uc $key;

    next unless defined $ENV{$env_key};

    warn "$env_key is deprecated and will be unsupported";
    $_CONF{$key} = $ENV{$env_key};
}

const %_CONF => %_CONF;

### ATTRIBUTES ###
#

### SUBS ###
#

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

