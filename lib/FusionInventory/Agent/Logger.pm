package FusionInventory::Agent::Logger;

use strict;
use warnings;
use base qw/Exporter/;

use constant {
    LOG_DEBUG3  => 6,
    LOG_DEBUG2  => 5,
    LOG_DEBUG   => 4,
    LOG_INFO    => 3,
    LOG_WARNING => 1,
    LOG_ERROR   => 1,
    LOG_NONE    => 0,
};

use English qw(-no_match_vars);
use UNIVERSAL::require;

our @EXPORT = qw/LOG_DEBUG2 LOG_DEBUG LOG_INFO LOG_WARNING LOG_ERROR LOG_NONE/;

my %levels = (
    none    => LOG_NONE,
    error   => LOG_ERROR,
    warning => LOG_WARNING,
    info    => LOG_INFO,
    debug   => LOG_DEBUG,
    debug2  => LOG_DEBUG2,
    debug3  => LOG_DEBUG3,
);

sub create {
    my ($class, %params) = @_;

    my $backend = $params{backend} ? lc($params{backend}) : 'stderr';

    if ($backend eq 'syslog') {
        FusionInventory::Agent::Logger::Syslog->require();
        return FusionInventory::Agent::Logger::Syslog->new(
            facility  => $params{facility},
            verbosity => $params{verbosity}
        );
    }

    if ($backend eq 'file') {
        FusionInventory::Agent::Logger::File->require();
        return FusionInventory::Agent::Logger::File->new(
            file      => $params{file},
            maxsize   => $params{maxsize},
            verbosity => $params{verbosity}
        );
    }

    if ($backend eq 'stderr') {
        FusionInventory::Agent::Logger::Stderr->require();
        return FusionInventory::Agent::Logger::Stderr->new(
            verbosity => $params{verbosity}
        );
    }

    die "Unknown logger backend '$backend'\n";
}

sub new {
    my ($class, %params) = @_;
    
    die "invalid log verbosity '$params{verbosity}'"
        if $params{verbosity} && !exists $levels{$params{verbosity}};

    my $self = {
        verbosity => $params{verbosity} ? $levels{$params{verbosity}} :
                                          LOG_INFO
    };
    bless $self, $class;

    return $self;
}

sub debug2 {
    my ($self, $message, @args) = @_;

    return unless $message;
    return unless $self->{verbosity} >= LOG_DEBUG2;
    $self->_log(level => 'debug2', message => sprintf($message, @args));
}

sub debug {
    my ($self, $message, @args) = @_;

    return unless $message;
    return unless $self->{verbosity} >= LOG_DEBUG;
    $self->_log(level => 'debug', message => sprintf($message, @args));
}

sub debug_result {
    my ($self, %params) = @_;

    return unless $self->{verbosity} >= LOG_DEBUG;

    my $status = $params{status} || ($params{data} ? 'success' : 'no result');

    $self->_log(
        level   => 'debug',
        message => sprintf('- %s: %s', $params{action}, $status)
    );
}

sub info {
    my ($self, $message, @args) = @_;

    return unless $message;
    return unless $self->{verbosity} >= LOG_INFO;
    $self->_log(level => 'info', message => sprintf($message, @args));
}

sub warning {
    my ($self, $message, @args) = @_;

    return unless $message;
    return unless $self->{verbosity} >= LOG_WARNING;
    $self->_log(level => 'warning', message => sprintf($message, @args));
}

sub error {
    my ($self, $message, @args) = @_;

    return unless $message;
    return unless $self->{verbosity} >= LOG_ERROR;
    $self->_log(level => 'error', message => sprintf($message, @args));
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Logger - Fusion Inventory logger

=head1 DESCRIPTION

This is the logger object.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<config>

the agent configuration object, to be passed to backends

=item I<backends>

a list of backends to use (default: Stderr)

=item I<verbosity>

the verbosity level (default: LOG_INFO)

=back

=head2 debug2($message)

Add a log message with debug2 level.

=head2 debug($message)

Add a log message with debug level.

=head2 info($message)

Add a log message with info level.

=head2 warning($message)

Add a log message with warning level.

=head2 error($message)

Add a log message with error level.

=head2 debug_result(%params)

Add a log message with debug level related to an action result.
