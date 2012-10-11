package Graph::Gviz::Node;
use strict;
use warnings;

use Carp ();

sub new {
    my ($class, %args) = @_;

    for my $key (qw/id attrs/) {
        unless (exists $args{$key}) {
            Carp::croak("missing mandatory parameter '$key'");
        }
    }

    my $id = delete $args{id};
    if ($id =~ m{_}) {
        Carp::croak("'id' paramter must not include underscores");
    }

    my $attrs = delete $args{attrs} || {};

    bless {
        id    => $id,
        attrs => $attrs,
    }, $class;
}

sub as_string {
    my $self = shift;
    sprintf "%s", $self->{id};
}

sub update_attributes {
    my ($self, $attrs) = @_;

    my %old_attrs = %{$self->{attrs}};
    $self->{attrs} = {
        %old_attrs,
        %{$attrs},
    };
}

# accessor
sub id    { $_[0]->{id};    }
sub attrs { $_[0]->{attrs}; }

1;
