package Graphviz::DSL::Graph;
use strict;
use warnings;

use parent qw/Graphviz::DSL::Component/;

use Carp ();
use Scalar::Util qw/blessed/;

use Graphviz::DSL::Util qw/parse_id/;

use overload (
    '""'     => sub { $_[0]->as_string },
    fallback => 1,
);

sub new {
    my ($class, %args) = @_;

    my $id   = delete $args{id}   || 'G';
    my $type = delete $args{type} || 'digraph';
    my $is_subgraph = delete $args{subgraph} || 0;

    bless {
        id          => $id,
        type        => $type,
        edges       => [],
        nodes       => [],
        gnode_attrs => [],
        gedge_attrs => [],
        graph_attrs => [],
        subgraphs   => [],
        ranks       => [],
        objects     => [],
        is_subgraph => $is_subgraph,
        delayed     => 0,
    }, $class;
}

sub add {
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
            $self->edge($edge);
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
        $self->node($node);
    } elsif (ref $node eq 'ARRAY') {
        $self->node($_) for @{$node};
    } else {
        Carp::croak("First parameter should be Scalar or ArrayRef");
    }
    return;
}

sub multi_route {
    my ($self, $stuff) = @_;

    unless (ref $stuff eq 'HASH') {
        Carp::croak("multi_route should take 'HashRef'");
    }

    my @edges = _apply(undef, $stuff);
    $self->add(@{$_}[0, 1]) for @edges;
}

sub _apply {
    my ($parent, $data) = @_;

    my @edges;
    my $ref = ref $data;
    if ($ref eq 'ARRAY') {
        for my $child (@{$data}) {
            push @edges, [$parent, $child];
        }
    } elsif ($ref eq 'HASH') {
        while (my ($key, $value) = each %{$data}) {
            push @edges, [$parent, $key] if defined $parent;
            push @edges, _apply($key, $value);
        }
    } else {
        push @edges, [$parent, $data];
    }

    return @edges;
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

sub node {
    my ($self, $node_id, @args) = @_;

    my @attrs = _to_key_value_pair(@args);

    my @nodes;
    if (ref $node_id eq 'Regexp') {
        for my $node (@{$self->{nodes}}) {
            $node->update_attributes(\@attrs) if $node->id =~ m{$node_id};
        }
    } else {
        if (my $node = $self->_find_node($node_id)) {
            $node->update_attributes(\@attrs);
        } else {
            my ($id, $port, $compass) = parse_id($node_id);
            my $node = Graphviz::DSL::Node->new(
                id         => $id,
                port       => $port,
                compass    => $compass,
                attributes => \@attrs,
            );
            push @{$self->{nodes}}, $node;
            push @{$self->{objects}}, $node;

            return $node;
        }
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

sub _create_node {
    my ($self, $id) = @_;

    my $node = $self->node($id);
    return $node;
}

sub _equal_only_id {
    my ($self, $node_id) = @_;

    my ($id) = parse_id($node_id);
    for my $obj (@{$self->{nodes}}) {
        if ($id eq $obj->id && $node_id ne $obj->id) {
            return $obj;
        }
    }

    return;
}

sub _find_obj {
    my ($self, $id) = @_;

    for my $obj (@{$self->{nodes}}, @{$self->{subgraphs}}) {
        if ($obj->id eq $id) {
            return $obj;
        }
    }

    return;
}

sub edge {
    my ($self, $id, @args) = @_;

    my @attrs = _to_key_value_pair(@args);

    unless (ref $id eq 'ARRAY') {
        Carp::croak("First parameter of 'edge' should be ArrayRef");
    }

    my @start_objs = $self->_match_objs($id->[0]);
    my @end_objs   = $self->_match_objs($id->[1]);

    my @edge_objs;
    for my $start_obj (@start_objs) {
        for my $end_obj (@end_objs) {
            push @edge_objs, [$start_obj, $end_obj];
        }
    }

    my @update_edges;
    for my $edge (@{$self->{edges}}) {
        for my $edge_obj (@edge_objs) {
            my $test_edge = Graphviz::DSL::Edge->new(
                start => $edge_obj->[0],
                end   => $edge_obj->[1],
            );
            push @update_edges, $edge if $edge->equal_to($test_edge);
        }
    }

    if (@update_edges) {
        for my $edge (@update_edges) {
            $edge->update_attributes(\@attrs);

            unless (grep { ref $_ eq 'Regexp'} @{$id}) {
                my $start = $self->_equal_only_id($id->[0]);
                my $end   = $self->_equal_only_id($id->[1]);

                $start->update($id->[0]) if $start;
                $end->update($id->[1])   if $end;
            }
        }
    } else {
        my ($start, $end) = map {
            $self->_find_obj($_) || $self->_create_node($_)
        } @{$id};

        my $edge = Graphviz::DSL::Edge->new(
            start      => $start,
            end        => $end,
            attributes => \@attrs,
        );

        push @{$self->{edges}}, $edge;
        push @{$self->{objects}}, $edge;
    }
}

sub _does_update {
    my ($self, $obj, $node_id) = @_;

    if (blessed $obj && blessed $obj eq 'Graphviz::DSL::Node'
            && ref $node_id ne 'Regexp' && $obj->id ne $node_id) {
        return 1;
    }
    return 0;
}

sub _match_objs {
    my ($self, $pattern) = @_;

    my @objects;
    my $matcher_code;
    my $use_regexp = 0;

    if (ref $pattern eq 'Regexp') {
        $matcher_code = \&_match_regexp;
        $use_regexp = 1;
    } else {
        if ($pattern =~ m{^([^:]+):}) {
            $pattern = $1;
        }
        $matcher_code = \&_match_string;
    }

    for my $obj (@{$self->{nodes}}, @{$self->{subgraphs}}) {
        if ($matcher_code->($obj->id, $pattern)) {
            push @objects, $obj;
            $obj->{delayed} = 1 if $obj->{is_subgraph};
        }
    }

    if ($use_regexp && scalar @objects == 0) {
        Carp::carp("No objects are matched\n");
    }

    return @objects;
}

sub _match_regexp {
    my ($target_id, $regexp) = @_;
    return $target_id =~ m{$regexp};
}

sub _match_string {
    my ($target_id, $id) = @_;
    return $target_id eq $id;
}

sub edge_matcher {
    my ($self, $start_matcher, $end_matcher) = @_;

    if (scalar @_ > 3) {
        Carp::carp("ignore after 3rd paramter");
    }
}

sub name {
    my ($self, $name) = @_;
    $self->{id} = $name;
    return $self->{id};
}

sub type {
    my ($self, $type) = @_;

    unless ($type eq 'digraph' || $type eq 'graph') {
        Carp::croak("'type' should be 'digraph' or 'graph'");
    }

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

sub rank {
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

sub update_attrs {
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
        return if $graph->{delayed};

        my @lines = split /\n/, $graph->as_string;

        my @results;
        for my $line (@lines) {
            chomp $line;
            push @results, "  ${line}";
        }
        return @results;
    },
    'Graphviz::DSL::Edge' => sub {
        my ($edge, $is_directed) = @_;
        sprintf "  %s%s;", $edge->as_string($is_directed), _build_attrs($edge->attributes);
    },
    'Graphviz::DSL::Node' => sub {
        my $node = shift;
        sprintf "  %s%s;", $node->as_string, _build_attrs($node->attributes);
    },
);

sub as_string {
    my $self = shift;

    my @result;
    my $is_directed = $self->{type} eq 'digraph' ? 1 : 0;
    my $indent = '  ';

    my $graph_type = $self->{is_subgraph} ? 'subgraph' : $self->{type};
    push @result, sprintf "%s %s {", $graph_type, $self->{id};

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
        push @result, $print_func{$class}->($object, $is_directed);
    }

    for my $rank ( @{$self->{ranks}} ) {
        my ($type, $nodes) = @{$rank};

        my $node_str = join '; ', @{$nodes};
        push @result, sprintf "%s{ rank=%s; %s; }", $indent, $type, $node_str;
    }

    push @result, "}\n";
    return join "\n", @result;
}

sub equal_to {
    my ($self, $obj) = @_;

    if (blessed $obj && $obj->isa('Graphviz::DSL::Graph')) {
        return 0;
    }

    return $self->{id} eq $obj->{id};
}

# accessor
sub id { $_[0]->{id}; }

1;
