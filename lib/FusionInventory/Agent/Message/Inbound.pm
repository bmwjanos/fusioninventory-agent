package FusionInventory::Agent::Message::Inbound;

use strict;
use warnings;

use XML::TreePP;

sub new {
    my ($class, %params) = @_;

    die "no content parameter" unless $params{content};

    my $tpp = XML::TreePP->new(
        force_array   => [ qw/
            OPTION PARAM MODEL AUTHENTICATION RANGEIP DEVICE GET WALK
            / ],
        attr_prefix   => '',
        text_node_key => 'content'
    );
    my $content = $tpp->parse($params{content});

    die "content is not an XML message" unless ref $content eq 'HASH';
    die "content is an invalid XML message" unless defined($content->{REPLY});

    my $self = {
        content => $content->{REPLY}
    };

    bless $self, $class;

    return $self;
}

sub getContent {
     my ($self) = @_;

    return $self->{content};
}

1;

__END__

=head1 NAME

FusionInventory::Agent::Message::Inbound - Message from server to agent

=head1 DESCRIPTION

This is an XML message sent by the server to the agent.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<content>

the raw XML content

=back

=head2 getContent

Get content, as a perl data structure.
