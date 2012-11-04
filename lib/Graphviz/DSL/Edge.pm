package Graphviz::DSL::Edge;
use strict;
use warnings;

use parent qw/Graphviz::DSL::Component/;

use Carp ();

sub new {
    my ($class, %args) = @_;

    unless (exists $args{id}) {
        Carp::croak("missing mandatory parameter 'id'");
    }

    unless (ref $args{id} eq 'ARRAY') {
        Carp::croak("'id' parameter should be ArrayRef");
    }

    my $id    = delete $args{id};
    my $attrs = delete $args{attributes} || {};

    my $self = bless { attributes => $attrs }, $class;
    $self->_parse_id($id);

    return $self;
}

sub as_string {
    my $self = shift;

    my $stp = $self->{start_port} ? ":$self->{start_port}" : "";
    my $edp = $self->{end_port} ? ":$self->{end_port}" : "";

    sprintf "%s%s -> %s%s", $self->{start}, $stp, $self->{end}, $edp;
}

sub nodes {
    my $self = shift;
    return [$self->{start}, $self->{end}];
}

sub update_id_info {
    my ($self, $new_id) = @_;
    $self->_parse_id($new_id);
}

sub _parse_id {
    my ($self, $id) = @_;

    my ($start, $start_port, $start_compass);
    my ($end, $end_port, $end_compass);
    ($start, $end) = @{$id}[0, 1];

    if ($start =~ m{:}) {
        ($start, $start_port, $start_compass) = split /:/, $start, 3;
    }

    if ($end =~ m{:}) {
        ($end, $end_port, $end_compass) = split /:/, $end, 3;
    }

    $self->{id}            = [$start, $end];
    $self->{start}         = $start;
    $self->{end}           = $end;
    $self->{start_port}    = $start_port;
    $self->{end_port}      = $end_port;
    $self->{start_compass} = $start_compass;
    $self->{end_compass}   = $end_compass;
}

sub equal_to {
    my ($self, $id) = @_;
    my ($start, $end) = map { _extract_id($_) } @{$id};

    return $self->_equal_id($start, $end);
}

sub _extract_id {
    my $id = shift;

    if ($id =~ m{^([^:]+)}) {
        $id = $1;
    }

    return $id
}

sub _equal_id {
    my ($self, $start, $end) = @_;
    my ($a, $target) = @_;

     if (ref $start eq 'Regexp') {
         return 0 unless $self->{start} =~ m{$start};
     } else {
         return 0 unless $self->{start} eq $start;
     }

    if (ref $end eq 'Regexp') {
        return 0 unless $self->{end} =~ m{$end};
    } else {
        return 0 unless $self->{end} eq $end;
    }

    return 1;
}

# accessor
sub start_node_id { $_[0]->{start} }
sub end_node_id   { $_[0]->{end}   }

1;
