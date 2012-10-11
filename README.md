# NAME

Graph::Gviz - Graphviz Perl interface with DSL

# SYNOPSIS

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

        node 'execute', shape => 'Mrecord', label => '{<x>execute | {a | b | c}}';
        node 'printf',  shape => 'Mrecord', label => '{printf |<y> format}';

        edge 'execute:x_printf:y';
        rank 'same', 'cleanup', 'execute';

        subgraph {
            global label => 'SUB';
            node 'init';
            node 'make';
        };
    };

    $graph->save(path => 'output', type => 'png', encoding => 'utf-8');

# DESCRIPTION

Graph::Gviz is Perl version of Ruby gem _Gviz_.

# INTERFACES

## Method in DSL

### `add $node, [%attributes]`

Add node with C<%attributes>.

### `route $node, [%attributes]`

`route` is alias of `add` function.

### `node($node_id, [%attributes])`

Add node or update attribute of specified node.

### `edge($edge_id, [%attributes])`

Add edge or update attribute of specified edge.

### `nodes(%attributes)`

Update attribute of all nodes.

### `edges(%attributes)`

Update attribute of all edges.

### `nodeset`

Return registered nodes.

### `edgeset`

Return registered edges.

### `global`

Update graph attribute.

### `rank`

Set rank.

### `subgraph($coderef)`

Create subgraph.

## Class Method

### `$graph->save(%args)`

Save graph as DOT file.

`%args` is:

- path

Basename of output file.

- type

Output image type, such as _png_, _gif_ etc.
`Graph::Gviz` don't output image if you omit this attribute.

- encoding

Encoding of output DOT file. Default is _utf-8_.

### `$graph->as_string`

Return DOT file as string.

# SEE ALSO

Gviz [https://github.com/melborne/Gviz](https://github.com/melborne/Gviz)

Graphviz [http://www.graphviz.org/](http://www.graphviz.org/)

# AUTHOR

Syohei YOSHIDA <syohex@gmail.com>

# COPYRIGHT

Copyright 2012- Syohei YOSHIDA

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
