use strict;
use warnings;
use Test::More;

use Graph::Gviz::Edge;

subtest 'constructor' => sub {
    my $edge = Graph::Gviz::Edge->new(id => 'foo_bar');
    ok $edge, 'constructor';
    isa_ok $edge, 'Graph::Gviz::Edge';
};

subtest 'parse id parameter' => sub {
    my $edge = Graph::Gviz::Edge->new(id => 'foo:a_bar:b_hoge');

    is $edge->{id}, 'foo_bar_hoge', "'id' parameter";
    is $edge->{start}, 'foo', "'start' parameter";
    is $edge->{end}, 'bar', "'end' parameter";
    is $edge->{seq}, 'hoge', "'seq' parameter";
    is $edge->{start_port}, 'a', "'start_port' parameter";
    is $edge->{end_port}, 'b', "'end_port' parameter";
};

subtest 'accessor' => sub {
    my $attrs = { a => 100, b => 200 };
    my $edge = Graph::Gviz::Edge->new(id => 'foo_bar', attributes => $attrs);

    is $edge->id, 'foo_bar', "'id' accessor";
    is_deeply $edge->attributes, $attrs, "'attributes' accessor";
    is $edge->start_node_id, 'foo', "'start_node_id' accessor";
    is $edge->end_node_id, 'bar', "'end_node_id' accessor";
};

subtest 'output to string' => sub {
    my $edge = Graph::Gviz::Edge->new(id => 'foo:a_bar:b');
    my $str = $edge->as_string;
    is $edge->as_string, 'foo:a -> bar:b', 'as String with port';

    my $edge_noport = Graph::Gviz::Edge->new(id => 'foo_bar');
    is $edge_noport->as_string, 'foo -> bar', 'as String without port';
};

subtest 'return nodes pair' => sub {
    my $edge = Graph::Gviz::Edge->new(id => 'foo:a_bar:b');
    is_deeply $edge->nodes, ['foo', 'bar'], 'nodes method';
};

subtest 'update attributes' => sub {
    my $attrs = { a => 100, b => 200 };
    my $edge = Graph::Gviz::Edge->new(id => 'foo_bar', attributes => $attrs);

    $edge->update_attributes({ a => 300, c => 400 });
    is_deeply $edge->attributes, { a => 300, b => 200, c => 400 }, 'update attributes';
};

subtest 'update id info', sub {
    my $edge = Graph::Gviz::Edge->new(id => 'foo_bar');
    $edge->update_id_info('foo:a_bar:b');

    is $edge->{start}, 'foo', "'start' parameter";
    is $edge->{end}, 'bar', "'end' parameter";
    is $edge->{start_port}, 'a', "update 'start_port' parameter";
    is $edge->{end_port}, 'b', "update 'end_port' parameter";
};

subtest 'invalid constructor' => sub {
    eval {
        Graph::Gviz::Edge->new;
    };
    like $@, qr/missing mandatory parameter 'id'/, "missing 'id' parameter";

    eval {
        Graph::Gviz::Edge->new(id => 'foo');
    };
    like $@, qr/must contain underscore/, 'not contain underscore';

    eval {
        Graph::Gviz::Edge->new(id => 'foo-');
    };
    like $@, qr/must not include other/, 'contain invalid character';
};

done_testing;
