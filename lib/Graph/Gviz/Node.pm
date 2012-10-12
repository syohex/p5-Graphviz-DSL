package Graph::Gviz::Node;
use strict;
use warnings;

use Carp ();

sub new {
    my ($class, %args) = @_;

    unless (exists $args{id}) {
        Carp::croak("missing mandatory parameter 'id'");
    }

    my $id = delete $args{id};
    if ($id =~ m{_}) {
        Carp::croak("'id' paramter must not include underscores");
    }

    my $attrs = delete $args{attributes} || {};

    bless {
        id         => $id,
        attributes => $attrs,
    }, $class;
}

sub as_string {
    my $self = shift;
    sprintf "%s", $self->{id};
}

sub update_attributes {
    my ($self, $attrs) = @_;

    my %old_attributes = %{$self->{attributes}};
    $self->{attributes} = {
        %old_attributes,
        %{$attrs},
    };
}

# accessor
sub id         { $_[0]->{id};    }
sub attributes { $_[0]->{attributes}; }

1;
