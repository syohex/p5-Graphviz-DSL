use strict;
use warnings;
use Test::More;

use Graphviz::DSL;

subtest 'Graph constructor' => sub {
    my $graph = Graphviz::DSL::Graph->new();
    ok $graph, 'constructor';
    isa_ok $graph, 'Graphviz::DSL::Graph';

    is $graph->{id}, 'G', 'default graph name';
    is $graph->{type}, 'digraph', 'default graph type';
};

subtest 'add(route) one node' => sub {
    my $graph = graph { add 'foo' };
    is scalar @{$graph->{nodes}}, 1, 'add one node';
    is $graph->{nodes}->[0]->id, 'foo', 'node added name';
};

subtest 'add(route) multiple nodes' => sub {
    my @names = qw/foo bar baz/;
    my $graph = graph { route \@names };
    is scalar @{$graph->{nodes}}, 3, 'add multiple nodes';

    my @gots = map { $_->id } @{$graph->{nodes}};
    is_deeply \@gots, \@names, 'node added names';
};

subtest 'add multiple nodes and edges' => sub {
    my $graph = graph { route 'foo', [qw/a b/], [qw/bar hoge/], 'd' };
    is scalar @{$graph->{nodes}}, 6, 'node number';
    is scalar @{$graph->{edges}}, 4, 'edge number';

    my @expected = (['foo' => 'a'], ['foo' => 'b'],
                    ['bar' => 'd'], ['hoge', 'd']);
    my @gots = map { $_->id } @{$graph->{edges}};
    is_deeply \@gots, \@expected, 'edges between nodes';
};

subtest 'add multiple nodes and edges(odd args)' => sub {
    my $graph = graph { route 'foo', [qw/a b/], [qw/bar hoge/] };
    is scalar @{$graph->{nodes}}, 5, 'node number(odd args)';
    is scalar @{$graph->{edges}}, 2, 'edge number(odd args)';

    my @expected = (['foo' => 'a'], ['foo' => 'b']);
    my @gots = map { $_->id } @{$graph->{edges}};
    is_deeply \@gots, \@expected, 'edges between nodes';
};

subtest 'add new node' => sub {
    my @attrs = (a => 'bar', b => 'hoge');
    my $graph = graph { node 'foo', @attrs };
    is scalar @{$graph->{nodes}}, 1, 'add new node';

    my $node = $graph->{nodes}->[0];
    is $node->id, 'foo', 'node id';

    my $expected = [[a => 'bar'], [b => 'hoge']];
    is_deeply $node->attributes, $expected, 'node attributes';
};

subtest 'update node' => sub {
    my @attrs = (a => 'bar', b => 'hoge');
    my $graph = graph {
        node 'foo', @attrs;
        node 'foo', b => 'poo', c => 'moo';
    };
    is scalar @{$graph->{nodes}}, 1, 'not add node';

    my $node = $graph->{nodes}->[0];
    is $node->id, 'foo', 'not change node id';
    my $expected = [[a => 'bar'], [b => 'poo'], [c => 'moo']];
    is_deeply $node->attributes, $expected, 'update node attributes';
};

subtest 'add new edge' => sub {
    my @attrs = (a => 'bar', b => 'hoge');
    my $graph = graph { edge [foo => 'bar'], @attrs };
    is scalar @{$graph->{nodes}}, 2, 'add new node';
    is scalar @{$graph->{edges}}, 1, 'add new edge';

    my $edge = $graph->{edges}->[0];
    is_deeply $edge->id, ['foo' => 'bar'], 'edge id';

    my $expected = [[a => 'bar'], [b => 'hoge']];
    is_deeply $edge->attributes, $expected, 'edge attributes';
};

subtest 'update edge' => sub {
    my @attrs = (a => 'bar', b => 'hoge');
    my $graph = graph {
        edge ['foo' => 'bar'], @attrs;
        edge ['foo:x' => 'bar:y'], b => 'wao', c => 'moo';
    };
    is scalar @{$graph->{nodes}}, 2, 'not change nodes';
    is scalar @{$graph->{edges}}, 1, 'not change edges';

    my $edge = $graph->{edges}->[0];
    is_deeply $edge->id, ['foo' => 'bar'], 'not change edge id';
    is $edge->{start_port}, 'x', 'set start_port';
    is $edge->{end_port}, 'y', 'set end_port';

    my $expected = [[a => 'bar'], [b => 'wao'], [c => 'moo']];
    is_deeply $edge->attributes, $expected, 'update edge attributes';
};

subtest 'update global nodes attributes' => sub {
    my $graph = graph {
        nodes name => 'foo', age => '10';
    };
    my $expected = [[name => 'foo'], [age => '10']];
    is_deeply $graph->{gnode_attrs}, $expected, 'global attribute';
};

subtest 'update global edges attributes' => sub {
    my $graph = graph {
        edges label => 'hoge', color => 'blue';
    };
    is_deeply $graph->{gedge_attrs}, [[label => 'hoge'], [color => 'blue']];
};

subtest 'nodeset' => sub {
    my @nodes;
    my $graph = graph {
        add [qw/a b c/];
        add [qw/d e f/];
        @nodes = nodeset;
    };
    is scalar @nodes, 6, 'return total nodes';
};

subtest 'edgeset' => sub {
    my @edges;
    my $graph = graph {
        route [qw/a b c/], [qw/d e f/];
        route 'g', [qw/h i/];
        @edges = edgeset;
    };
    is scalar @edges, 11, 'return total edges';
};

subtest 'update graph global attributes' => sub {
    my $graph = graph {
        global name => 'japan', year => '1492';
    };
    is_deeply $graph->{graph_attrs}, [[name => 'japan'], [year => '1492']];
};

subtest 'rank' => sub {
    my $graph = graph {
        add [qw/foo bar/];
        rank 'same', 'foo', 'bar';
    };
    is scalar @{$graph->{ranks}}, 1, 'add rank';
    is_deeply $graph->{ranks}->[0], ['same', [qw/foo bar/]], 'set rank';

    for my $type (qw/same min max source sink/) {
        my $g = graph { route $type, 'foo' };
        ok $g, "valid type '$type'";
    }
};

subtest 'invalid rank' => sub {
    eval {
        graph {
            add [qw/foo bar/];
            rank 'hoge', 'foo', 'bar';
        };
    };
    like $@, qr/type must match any of/, 'invalid type';

    eval {
        graph { rank 'hoge'; };
    };
    like $@, qr/not specified nodes/, 'not specified node';
};

subtest 'subgraph' => sub {
    my $graph = graph {
        subgraph {
            global label => 'SUB';
            node 'init';
            node 'make';
        };
    };
    is scalar @{$graph->{subgraphs}}, 1, 'add subgraph';

    my $subgraph = $graph->{subgraphs}->[0];
    ok $subgraph, 'defined subgraph';
    isa_ok $subgraph, "Graphviz::DSL::Graph", 'subgraph is-a Graphviz::DSL::Graph';
};

subtest 'as_string(direct)' => sub {
    my $graph = graph {
        route main => [qw/init parse/];
        route init => 'make', parse => 'execute';
        route execute => [qw/make compare/];
    };

    my $expected = <<'...';
digraph G {
  main;
  init;
  main -> init;
  parse;
  main -> parse;
  make;
  init -> make;
  execute;
  parse -> execute;
  execute -> make;
  compare;
  execute -> compare;
}
...

    is $graph->as_string, $expected, 'as_string';
};

subtest 'as_string(undirect)' => sub {
    my $graph = graph {
        type 'graph';
        route main => [qw/init parse/];
        route init => 'make', parse => 'execute';
        route execute => [qw/make compare/];
    };

    my $expected = <<'...';
graph G {
  main;
  init;
  main -- init;
  parse;
  main -- parse;
  make;
  init -- make;
  execute;
  parse -- execute;
  execute -- make;
  compare;
  execute -- compare;
}
...

    is $graph->as_string, $expected, 'as_string';
};

subtest 'set name' => sub {
    my $graph = graph {
        name 'test_graph';
    };

    is $graph->{name}, 'test_graph', 'Set graph name';
};

subtest 'set type' => sub {
    my $graph = graph {
        type 'graph';
    };

    is $graph->{type}, 'graph', 'Set graph type';
};

done_testing;
