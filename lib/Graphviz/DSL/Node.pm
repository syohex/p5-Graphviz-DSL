package Graphviz::DSL::Node;
use strict;
use warnings;

use parent qw/Graphviz::DSL::Component/;

use Carp ();

sub new {
    my ($class, %args) = @_;

    unless (exists $args{id}) {
        Carp::croak("missing mandatory parameter 'id'");
    }

    my $id    = delete $args{id};
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

sub equal_to {
    my ($self, $id) = @_;

    if (ref $id eq 'Regexp') {
        return 0 unless $self->{id} =~ m{$id};
    } else {
        return 0 unless $self->{id} eq $id;
    }

    return 1;
}

# accessor
sub id         { $_[0]->{id};    }
sub attributes { $_[0]->{attributes}; }

1;
