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

### CONSTANTS ###
#

# Default path to the 'tmux' binary
# Requires  :   Cwd
const my $_DEFAULT_TMUX_PATH => Cwd::realpath('/usr/local/bin');

# Default 'tmux' binary fqdn
# Depends   :   On $_DEFAULT_TMUX_PATH
# Requires  :   File::Spec
const my $_DEFAULT_TMUX_FQDN =>
    File::Spec->catfile( $_DEFAULT_TMUX_PATH => 'tmux' );

# Keep the configuration variables
my %_CONF;

# Tmux file name with full path
$_CONF{'tmux_fqdn'} = $_DEFAULT_TMUX_FQDN;

# Tmux 'neww' parameter for a system/shell command
$_CONF{'tmux_cmd_neww_exec'} = 'sleep 1000000';

# Tmux  'neww' command paraneters to be sprintf()'d with 'tmux_fqdn' and
# pushed after split by spaces the 'tmux_cmd_neww_exec' into list of
# parameters
$_CONF{'tmux_cmd_neww'} = "neww -P";

# Tmux command parameters to get a tty name
$_CONF{'tmux_cmd_tty'} = 'lsp -F #{pane_tty} -t';

# Take config override from %ENV
# Depends   :   On %ENV global of the main::
foreach my $key ( keys %_CONF ) {

    # Key for %ENV
    my $env_key = "SPUNGE_" . uc $key;

    next unless defined $ENV{$env_key};

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

    my $tmux_fqdn = Debug::Fork::Tmux->config( 'tmux_fqdn' );

=head1 DESCRIPTION

This module reads description from environment variables and use defaults if
those are not set.

For example C<tmux_fqdn> can be overridden with C<SPUNGE_TMUX_FQDN>
variable, and so on..

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

