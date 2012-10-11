package Graph::Gviz::Edge;
use strict;
use warnings;

use Carp ();

sub new {
    my ($class, %args) = @_;

    my $id    = delete $args{id};
    my $attrs = delete $args{attrs} || {};
    unless (ref $attrs eq 'HASH') {
        Carp::croak("'attrs' paramter should be hash reference");
    }

    my $self = bless { attrs => $attrs }, $class;
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

sub update_attributes {
    my ($self, $attrs) = @_;

    my %old_attrs = %{$self->{attrs}};
    $self->{attrs} = {
        %old_attrs,
        %{$attrs},
    };
}

sub update_id_info {
    my ($self, $new_id) = @_;
    $self->_parse_id($new_id);
}

sub _parse_id {
    my ($self, $id) = @_;

    if ($id =~ m/[^\w:]/) {
        Carp::croak("'id' parameter($id) must not include other than words or colon");
    }

    my ($start, $start_port, $end, $end_port, $seq);
    ($start, $end, $seq) = split /_/, $id;

    ($start, $start_port) = split /:/, $start if $start =~ m{:};
    ($end, $end_port)     = split /:/, $end   if $end   =~ m{:};

    my $id_ref = (defined $seq ? [$start, $end, $seq] : [$start, $end]);
    $id = join '_', @{$id_ref};

    $self->{id}         = $id;
    $self->{start}      = $start;
    $self->{end}        = $end;
    $self->{seq}        = $seq;
    $self->{start_port} = $start_port;
    $self->{end_port}   = $end_port;
}

# accessor
sub id         { $_[0]->{id}    }
sub attrs      { $_[0]->{attrs} }
sub start_node_id { $_[0]->{start} }
sub end_node_id   { $_[0]->{end}   }

1;
