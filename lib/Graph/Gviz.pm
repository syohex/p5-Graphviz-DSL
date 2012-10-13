package Graph::Gviz;
use strict;
use warnings;
use 5.008_001;

use Carp ();
use Encode ();
use Graph::Gviz::Edge;
use Graph::Gviz::Node;

our $VERSION = '0.01';

use overload (
    '""'     => sub { $_[0]->as_string },
    fallback => 1,
);

sub import {
    my $class = shift;
    my $pkg   = caller;

    no strict   'refs';
    no warnings 'redefine';

    *{"$pkg\::graph"}    = _build_graph();
    *{"$pkg\::add"}      = sub { goto &add      };
    *{"$pkg\::route"}    = sub { goto &route    };
    *{"$pkg\::node"}     = sub { goto &node     };
    *{"$pkg\::edge"}     = sub { goto &edge     };
    *{"$pkg\::nodes"}    = sub { goto &nodes    };
    *{"$pkg\::edges"}    = sub { goto &edges    };
    *{"$pkg\::nodeset"}  = sub { goto &nodeset  };
    *{"$pkg\::edgeset"}  = sub { goto &edgeset  };
    *{"$pkg\::global"}   = sub { goto &global   };
    *{"$pkg\::rank"}     = sub { goto &rank     };
    *{"$pkg\::subgraph"} = (sub { sub (&) { goto &subgraph } })->();
}

sub _new {
    my ($class, %args) = @_;

    my $name = delete $args{name} || 'G';
    my $type = delete $args{type} || 'digraph';

    bless {
        name        => $name,
        type        => $type,
        edges       => [],
        nodes       => [],
        gnode_attrs => {},
        gedge_attrs => {},
        graph_attrs => {},
        subgraphs   => [],
        ranks       => [],
    }, $class;
}

sub _build_nodes {
    my $self = shift;

    sub {
        $self->_nodes;
    };
}

sub _update_attrs {
    my ($self, $key, %args) = @_;

    my %old_attrs = %{$self->{$key}};
    $self->{$key} = {
        %old_attrs,
        %args,
    };
}

sub _update_gnode_attrs {
    my ($self, %args) = @_;

    my %old_attrs = %{$self->{gnode_attrs}};
    $self->{gnode_attrs} = {
        %old_attrs,
        %args,
    };
}

sub _update_gedge_attrs {
    my ($self, %args) = @_;

    my %old_attrs = %{$self->{gedge_attrs}};
    $self->{gedge_attrs} = {
        %old_attrs,
        %args,
    };
}

sub _create_node {
    my $self = shift;

    sub {
        $self->_node(@_);
    }
}

sub _find_node {
    my ($self, $id) = @_;

    for my $node (@{$self->{nodes}}) {
        return $node if $node->id eq $id;
    }

    return;
}

sub _node {
    my ($self, $id, %args) = @_;
    my $attrs = %args ? {%args} : {};

    if (my $node = $self->_find_node($id)) {
        $node->update_attributes($attrs);
    } else {
        push @{$self->{nodes}}, Graph::Gviz::Node->new(
            id         => $id,
            attributes => $attrs
        );
    }
}

sub _find_edge {
    my ($self, $id) = @_;

    for my $edge (@{$self->{edges}}) {
        return $edge if $edge->id eq $id;
    }

    return;
}

sub _edge {
    my ($self, $id, %args) = @_;
    my $attrs = %args ? { %args } : {};

    unless ($id =~ m{._.}) {
        Carp::croak("'id' should be joined with '_'");
    }

    my $dummy = Graph::Gviz::Edge->new(
        id    => $id,
        attributes => $attrs
    );

    if (my $edge = $self->_find_edge($dummy->id)) {
        $edge->update_attributes($attrs);
        $edge->update_id_info($id) if $edge->id ne $id;
    } else {
        push @{$self->{edges}}, $dummy;
        $self->_create_nodes;
    }
}

sub _build_graph {
    my ($subgraph) = @_;

    sub (&) {
        my $code = shift;

        my $self = defined $subgraph ? $subgraph : Graph::Gviz->_new();

        no warnings 'redefine';

        local *add      = sub { $self->_add(@_) };
        local *route    = sub { $self->_add(@_) };
        local *node     = sub { $self->_node(@_) };
        local *edge     = sub { $self->_edge(@_) };
        local *nodes    = sub { $self->_update_attrs('gnode_attrs', @_) };
        local *edges    = sub { $self->_update_attrs('gedge_attrs', @_) };
        local *nodeset  = sub { @{$self->{nodes}} };
        local *edgeset  = sub { @{$self->{edges}} };
        local *global   = sub { $self->_update_attrs('graph_attrs', @_) };
        local *rank     = sub { $self->_rank(@_) };
        local *subgraph = _build_subgraph($self);

        $code->();
        $self;
    }
}

sub _build_subgraph {
    my $parent = shift;

    sub (&) {
        my $code = shift;
        my $num  = scalar @{$parent->{subgraphs}};

        my $self = Graph::Gviz->_new(name => "cluster${num}", type => 'subgraph');
        my $graph = _build_graph($self);

        my $subgraph = $graph->($code);
        push @{$parent->{subgraphs}}, $subgraph;
    };
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
        my $cmd_str = sprintf "dot -T%s %s -o %s.%s", $type, $dotfile, $path, $type;
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

sub _build_attrs {
    my ($attrs, $is_join) = @_;

    return '' unless %{$attrs};

    unless (defined $is_join) {
        $is_join = 1;
    }

    my @strs;
    for my $k (sort keys %{$attrs}) {
        my $v = $attrs->{$k};
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

sub as_string {
    my $self = shift;

    my @result;
    my $indent = '  ';

    push @result, sprintf "%s %s {", $self->{type}, $self->{name};

    if (%{$self->{graph_attrs}}) {
        my $graph_attrs_str = join ";\n$indent", @{_build_attrs($self->{graph_attrs}, 0)};
        push @result, sprintf "%s%s;", $indent, $graph_attrs_str;
    }

    if (%{$self->{gnode_attrs}}) {
        my $gnode_attr_str = _build_attrs($self->{gnode_attrs});
        push @result, sprintf "%snode%s;", $indent, $gnode_attr_str;
    }

    if (%{$self->{gedge_attrs}}) {
        my $gedge_attr_str = _build_attrs($self->{gedge_attrs});
        push @result, sprintf "%sedge%s;", $indent, $gedge_attr_str;
    }

    for my $node (@{$self->{nodes}}) {
        my $node_str = $node->as_string;
        my $node_attr_str = _build_attrs($node->attributes);
        push @result, sprintf "%s%s%s;", $indent, $node_str, $node_attr_str;
    }

    for my $edge (@{$self->{edges}}) {
        my $edge_str = $edge->as_string;
        my $edge_attr_str = _build_attrs($edge->attributes);
        push @result, sprintf "%s%s%s;", $indent, $edge_str, $edge_attr_str;
    }

    for my $graph (@{$self->{subgraphs}}) {
        my @lines = split /\n/, $graph->as_string;

        for my $line (@lines) {
            chomp $line;
            push @result, "${indent}${line}";
        }
    }

    for my $rank ( @{$self->{ranks}} ) {
        my ($type, $nodes) = @{$rank};

        my $node_str = join '; ', @{$nodes};
        push @result, sprintf "%s{ rank=%s; %s; }", $indent, $type, $node_str;
    }

    push @result, "}\n";
    return join "\n", @result;
}

sub __stub {
    my $func = shift;
    return sub {
        Carp::croak "Can't call $func() outside graph block";
    };
}

*route    = __stub 'route';
*add      = __stub 'add';
*node     = __stub 'node';
*edge     = __stub 'edge';
*nodes    = __stub 'nodes';
*edges    = __stub 'edges';
*nodeset  = __stub 'nodeset';
*edgeset  = __stub 'edgeset';
*global   = __stub 'global';
*rank     = __stub 'rank';
*subgraph = __stub 'subgraph';

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

Graph::Gviz - Graphviz Perl interface with DSL

=head1 SYNOPSIS

  use Graph::Gviz;

  my $graph = graph {
      route main => [qw/init parse cleanup printf/];
      route init => 'make', parse => 'execute';
      route execute => [qw/make compare printf /];

      nodes colorscheme => 'piyg8', style => 'filled';

      my $index = 1;
      for my $n ( nodeset() ) {
          node($n->id, fillcolor => $index++);
      }

      edges arrowhead => 'onormal', color => 'magenta4';
      edge 'main_printf', arrowtail => 'diamond', color => '#3355FF';
      global bgcolor => 'white';

      node 'execute', shape => 'Mrecord',
                      label => '{<x>execute | {a | b | c}}';
      node 'printf',  shape => 'Mrecord',
                      label => '{printf |<y> format}';

      edge 'execute:x_printf:y';
      rank 'same', 'cleanup', 'execute';

      subgraph {
          global label => 'SUB';
          node 'init';
          node 'make';
      };
  };

  $graph->save(path => 'output', type => 'png', encoding => 'utf-8');

=head1 DESCRIPTION

Graph::Gviz is Perl version of Ruby gem I<Gviz>.

=head1 INTERFACES

=head2 Method in DSL

=head3 C<< add, route >>

Add nodes and them edges. C<route> is alias of C<add> function.
You can call these methods like following.

=over

=item C<< add $nodes >>

Add C<$nodes> to this graph. C<$nodes> should be Scalar or ArrayRef.

=item C<< add $node1, \@edges1, $node2, \@edges2 ... >>

Add nodes and edges. C<$noden> should be Scalar or ArrayRef.
For example:

    add [qw/a b/], [qw/c d/]

Add node I<a> and I<b> and add edge a->c, a->d, b->c, b->d.

=back

=head3 C<< node($node_id, [%attributes]) >>

Add node or update attribute of specified node.

=head3 C<< edge($edge_id, [%attributes]) >>

Add edge or update attribute of specified edge.

=head3 C<< nodes(%attributes) >>

Update attribute of all nodes.

=head3 C<< edges(%attributes) >>

Update attribute of all edges.

=head3 C<< nodeset >>

Return registered nodes.

=head3 C<< edgeset >>

Return registered edges.

=head3 C<< global >>

Update graph attribute.

=head3 C<< rank >>

Set rank.

=head3 C<< subgraph($coderef) >>

Create subgraph.

=head2 Class Method

=head3 C<< $graph->save(%args) >>

Save graph as DOT file.

C<%args> is:

=over

=item path

Basename of output file.

=item type

Output image type, such as I<png>, I<gif> etc.
C<Graph::Gviz> don't output image if you omit this attribute.

=item encoding

Encoding of output DOT file. Default is I<utf-8>.

=back

=head3 C<< $graph->as_string >>

Return DOT file as string. This is same as strigify itself.
Graph::Gviz overload stringify operation.

=head1 SEE ALSO

Gviz L<https://github.com/melborne/Gviz>

Graphviz L<http://www.graphviz.org/>

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2012- Syohei YOSHIDA

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
