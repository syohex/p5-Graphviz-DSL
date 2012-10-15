package Graph::Gviz::Node;
use strict;
use warnings;

use Carp ();
use parent qw/Graph::Gviz::Component/;

sub new {
    my ($class, %args) = @_;

    unless (exists $args{id}) {
        Carp::croak("missing mandatory parameter 'id'");
    }

    my $id = delete $args{id};
    if ($id =~ m{_}) {
        Carp::croak("'id' paramter must not include underscores");
    }

    my $attrs = delete $args{attributes} || [];
    unless (ref $attrs eq 'ARRAY') {
        Carp::croak("'attributes' parameter should be ArrayRef");
    }

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

 OUTER:
    for my $attr (@{$attrs}) {
        my ($key, $val) = @{$attr};
        for my $old_attr (@{$self->{attributes}}) {
            my ($old_key, $old_val) = @{$old_attr};

            if ($key eq $old_key) {
                $old_attr->[1] = $val;
                next OUTER;
            }
        }

        push @{$self->{attributes}}, $attr;
    }
}

# accessor
sub id         { $_[0]->{id};    }
sub attributes { $_[0]->{attributes}; }

1;
