use strict;
use warnings;
use Test::More;

use Graphviz::DSL::Edge;

subtest 'constructor' => sub {
    my $edge = Graphviz::DSL::Edge->new(id => ['foo' => 'bar']);
    ok $edge, 'constructor';
    isa_ok $edge, 'Graphviz::DSL::Edge';
};

subtest 'parse id parameter' => sub {
    my $edge = Graphviz::DSL::Edge->new(id => ['foo:a' => 'bar:b']);

    is_deeply $edge->{id}, ['foo' => 'bar'], "'id' parameter";
    is $edge->{start}, 'foo', "'start' parameter";
    is $edge->{end}, 'bar', "'end' parameter";
    is $edge->{start_port}, 'a', "'start_port' parameter";
    is $edge->{end_port}, 'b', "'end_port' parameter";
};

subtest 'accessor' => sub {
    my $attrs = { a => 100, b => 200 };
    my $edge = Graphviz::DSL::Edge->new(
        id => ['foo' => 'bar'],
        attributes => $attrs
    );

    is_deeply $edge->id, ['foo' => 'bar'], "'id' accessor";
    is_deeply $edge->attributes, $attrs, "'attributes' accessor";
    is $edge->start_node_id, 'foo', "'start_node_id' accessor";
    is $edge->end_node_id, 'bar', "'end_node_id' accessor";
};

subtest 'output to string' => sub {
    my $edge = Graphviz::DSL::Edge->new(id => ['foo:a' => 'bar:b']);
    my $str = $edge->as_string;
    is $edge->as_string, 'foo:a -> bar:b', 'as String with port';

    my $edge_noport = Graphviz::DSL::Edge->new(id => ['foo' => 'bar']);
    is $edge_noport->as_string, 'foo -> bar', 'as String without port';
};

subtest 'return nodes pair' => sub {
    my $edge = Graphviz::DSL::Edge->new(id => ['foo:a' => 'bar:b']);
    is_deeply $edge->nodes, ['foo', 'bar'], 'nodes method';
};

subtest 'update attributes' => sub {
    my $attrs = [[a => 100], [b => 200]];
    my $edge = Graphviz::DSL::Edge->new(
        id => ['foo' => 'bar'],
        attributes => $attrs
    );

    $edge->update_attributes([[a => 300], [c => 400]]);
    my $expected = [[a => 300], [b => 200], [c => 400]];
    is_deeply $edge->attributes, $expected, 'update attributes';
};

subtest 'update id info', sub {
    my $edge = Graphviz::DSL::Edge->new(id => ['foo' => 'bar']);
    $edge->update_id_info(['foo:a:aa' => 'bar:b:bb']);

    is $edge->{start}, 'foo', "'start' parameter";
    is $edge->{end}, 'bar', "'end' parameter";
    is $edge->{start_port}, 'a', "update 'start port'";
    is $edge->{end_port}, 'b', "update 'end port'";
    is $edge->{start_compass}, 'aa', "update 'start compass'";
    is $edge->{end_compass}, 'bb', "update 'end compass'";
};

subtest 'equal to the edge' => sub {
    my $edge = Graphviz::DSL::Edge->new(id => ['foo' => 'bar']);
    ok $edge->equal_to(['foo' => 'bar']), 'equal to same ID';
    ok $edge->equal_to(['foo:a' => 'bar:b']), 'equal to same ID with port';
};

subtest 'invalid constructor' => sub {
    eval {
        Graphviz::DSL::Edge->new;
    };
    like $@, qr/missing mandatory parameter 'id'/, "missing 'id' parameter";

    eval {
        Graphviz::DSL::Edge->new(id => 'foo');
    };
    like $@, qr/should be ArrayRef/, 'not ArrayRef';
};

done_testing;
