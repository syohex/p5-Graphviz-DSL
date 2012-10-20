package Graphviz::DSL::Graph;
use strict;
use warnings;

use parent qw/Graphviz::DSL::Component/;

use Carp ();
use Scalar::Util qw/blessed/;

use overload (
    '""'     => sub { $_[0]->as_string },
    fallback => 1,
);

sub new {
    my ($class, %args) = @_;

    my $name = delete $args{name} || 'G';
    my $type = delete $args{type} || 'digraph';

    bless {
        name        => $name,
        type        => $type,
        edges       => [],
        nodes       => [],
        gnode_attrs => [],
        gedge_attrs => [],
        graph_attrs => [],
        subgraphs   => [],
        ranks       => [],
        objects     => [],
    }, $class;
}

sub _add {
    my ($self, @nodes_or_routes) = @_;

    if (scalar @nodes_or_routes == 1) {
        $self->_add_one_node($nodes_or_routes[0]);
        return;
    }

    while (my ($start, $end) = splice @nodes_or_routes, 0, 2) {
        unless (defined $end) {
            $self->_add_one_node($start);
            return;
        }

        ($start, $end) = map {
            ref($_) eq 'ARRAY' ? $_ : [$_];
        } ($start, $end);

        for my $edge ( _product($start, $end) ) {
            my $edge_id = join '_', @{$edge};
            $self->_edge($edge_id);
        }
    }
}

sub _find_node {
    my ($self, $id) = @_;

    for my $node (@{$self->{nodes}}) {
        return $node if $node->id eq $id;
    }

    return;
}

sub _add_one_node {
    my ($self, $node) = @_;

    if (!ref($node)) {
        $self->_node($node);
    } elsif (ref $node eq 'ARRAY') {
        $self->_node($_) for @{$node};
    } else {
        Carp::croak("First parameter should be Scalar or ArrayRef");
    }
    return;
}

sub _product {
    my ($array_ref1, $array_ref2) = @_;

    my @products;
    for my $a (@{$array_ref1}) {
        for my $b (@{$array_ref2}) {
            push @products, [$a, $b];
        }
    }

    return @products;
}

sub _node {
    my ($self, $id, @args) = @_;

    my @attrs = _to_key_value_pair(@args);

    if (my $node = $self->_find_node($id)) {
        $node->update_attributes(\@attrs);
    } else {
        my $node = Graphviz::DSL::Node->new(
            id         => $id,
            attributes => \@attrs,
        );
        push @{$self->{nodes}}, $node;
        push @{$self->{objects}}, $node;
    }
}

sub _to_key_value_pair {
    my @args = @_;

    my @pairs;
    while (my ($k, $v) = splice @args, 0, 2) {
        push @pairs, [$k, $v];
    }

    return @pairs;
}

sub _find_edge {
    my ($self, $id) = @_;

    for my $edge (@{$self->{edges}}) {
        return $edge if $edge->id eq $id;
    }

    return;
}

sub _create_nodes {
    my $self = shift;

    for my $edge (@{$self->{edges}}) {
        for my $id ($edge->start_node_id, $edge->end_node_id) {
            unless ($self->_find_node($id)) {
                $self->_node($id);
            }
        }
    }
}

sub _edge {
    my ($self, $id, @args) = @_;

    my @attrs = _to_key_value_pair(@args);

    unless ($id =~ m{._.}) {
        Carp::croak("'id' should be joined with '_'");
    }

    my $dummy = Graphviz::DSL::Edge->new(
        id         => $id,
        attributes => \@attrs,
    );

    if (my $edge = $self->_find_edge($dummy->id)) {
        $edge->update_attributes(\@attrs);
        $edge->update_id_info($id) if $edge->id ne $id;
    } else {
        push @{$self->{edges}}, $dummy;
        $self->_create_nodes;
        push @{$self->{objects}}, $dummy;
    }
}

sub _name {
    my ($self, $name) = @_;
    $self->{name} = $name;
    return $self->{name};
}

sub _type {
    my ($self, $type) = @_;
    $self->{type} = $type;
    return $self->{type};
}

sub save {
    my ($self, %args) = @_;

    my $path     = delete $args{path};
    my $type     = delete $args{type};
    my $encoding = delete $args{encoding} || 'utf-8';

    my $dotfile = "${path}.dot";
    open my $fh, '>', $dotfile or Carp::croak("Can't open $dotfile: $!");
    print {$fh} Encode::encode($encoding, $self->as_string);
    close $fh;

    if ($type) {
        my $dot = File::Which::which('dot');
        unless (defined $dot) {
            Carp::carp("Cannot generate image. Please install Graphviz(dot command).");
            return;
        }

        my $output = "${path}.${type}";
        my $cmd_str = sprintf "%s -T%s %s -o %s", $dot, $type, $dotfile, $output;
        my @cmd = split /\s/, $cmd_str;

        system(@cmd) == 0 or Carp::croak("Failed command: '@cmd'");
    }
}

sub _rank {
    my ($self, $type, @nodes) = @_;

    unless (@nodes) {
        Carp::croak("not specified nodes");
    }

    my @types = qw/same min max source sink/;
    unless ( grep { $type eq $_} @types) {
        Carp::croak("type must match any of '@types'");
    }

    push @{$self->{ranks}}, [$type, \@nodes];
}

sub _build_attrs {
    my ($attrs, $is_join) = @_;

    return '' unless @{$attrs};

    unless (defined $is_join) {
        $is_join = 1;
    }

    my @strs;
    for my $attr (@{$attrs}) {
        my ($k, $v) = @{$attr};
        my $str = qq{$k="$v"};
        $str =~ s{\n}{\\n}g;
        push @strs, $str;
    }

    if ($is_join) {
        my $joined = join q{,}, @strs;
        return "[${joined}]";
    } else {
        return \@strs;
    }
}

sub _update_attrs {
    my ($self, $attr_key, @args) = @_;

 OUTER:
    while (my ($key, $val) = splice @args, 0, 2) {
        for my $old_attr (@{$self->{$attr_key}}) {
            my ($old_key, $old_val) = @{$old_attr};

            if ($key eq $old_key) {
                $old_attr->[1] = $val;
                next OUTER;
            }
        }

        push @{$self->{$attr_key}}, [$key, $val];
    }
}

my %print_func = (
    'Graphviz::DSL::Graph' => sub {
        my $graph = shift;
        my @lines = split /\n/, $graph->as_string;

        my @results;
        for my $line (@lines) {
            chomp $line;
            push @results, "  ${line}";
        }
        return @results;
    },
    'Graphviz::DSL::Edge' => sub {
        my $edge = shift;
        sprintf "  %s%s;", $edge->as_string, _build_attrs($edge->attributes);
    },
    'Graphviz::DSL::Node' => sub {
        my $node = shift;
        sprintf "  %s%s;", $node->as_string, _build_attrs($node->attributes);
    },
);

sub as_string {
    my $self = shift;

    my @result;
    my $indent = '  ';

    push @result, sprintf "%s %s {", $self->{type}, $self->{name};

    if (@{$self->{graph_attrs}}) {
        my $graph_attrs_str = join ";\n$indent", @{_build_attrs($self->{graph_attrs}, 0)};
        push @result, sprintf "%s%s;", $indent, $graph_attrs_str;
    }

    if (@{$self->{gnode_attrs}}) {
        my $gnode_attr_str = _build_attrs($self->{gnode_attrs});
        push @result, sprintf "%snode%s;", $indent, $gnode_attr_str;
    }

    if (@{$self->{gedge_attrs}}) {
        my $gedge_attr_str = _build_attrs($self->{gedge_attrs});
        push @result, sprintf "%sedge%s;", $indent, $gedge_attr_str;
    }

    for my $object (@{$self->{objects}}) {
        my $class = blessed $object;
        Carp::croak("Invalid object") unless defined $class;
        push @result, $print_func{$class}->($object);
    }

    for my $rank ( @{$self->{ranks}} ) {
        my ($type, $nodes) = @{$rank};

        my $node_str = join '; ', @{$nodes};
        push @result, sprintf "%s{ rank=%s; %s; }", $indent, $type, $node_str;
    }

    push @result, "}\n";
    return join "\n", @result;
}

1;
