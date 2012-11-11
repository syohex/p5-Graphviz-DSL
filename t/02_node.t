use strict;
use warnings;
use Test::More;

use Graphviz::DSL::Node;

subtest 'constructor' => sub {
    my $node = Graphviz::DSL::Node->new(id => 'foo');
    ok $node, 'constructor';
    isa_ok $node, 'Graphviz::DSL::Node';
};

subtest 'accessor' => sub {
    my $attrs = [[a => 'foo'], [b => 'bar']];
    my $node = Graphviz::DSL::Node->new(
        id         => 'foo',
        attributes => $attrs,
    );

    is $node->id, 'foo', "'id' accessor";
    is_deeply $node->attributes, $attrs, "'attributes' accessor";
};

subtest 'update attributes' => sub {
    my $node = Graphviz::DSL::Node->new(
        id         => 'foo',
        attributes => [[foo => 100], [bar => 200]],
    );

    $node->update_attributes([[foo => 300], [hoge => 400]]);
    my $expected = [[foo => 300], [bar => 200], [hoge => 400]];
    is_deeply $node->attributes, $expected, 'update attributes';
};

subtest 'as_string' => sub {
    my $node = Graphviz::DSL::Node->new(id => 'foo');
    is $node->as_string, '"foo"', "output of as_string";
};

subtest 'missing id parameter' => sub {
    eval {
        my $node = Graphviz::DSL::Node->new();
    };
    like $@, qr/missing mandatory parameter 'id'/;
};

done_testing;
