use strict;
use warnings;
use Test::More;

use Graphviz::DSL::Node;
use Graphviz::DSL::Edge;

subtest 'constructor' => sub {
    my $edge = Graphviz::DSL::Edge->new(
        start => Graphviz::DSL::Node->new(id => 'foo'),
        end   => Graphviz::DSL::Node->new(id => 'bar'),
    );
    ok $edge, 'constructor';
    isa_ok $edge, 'Graphviz::DSL::Edge';
};

subtest 'accessor' => sub {
    my $start = Graphviz::DSL::Node->new(id => 'foo');
    my $end   = Graphviz::DSL::Node->new(id => 'bar');
    my $attrs = { a => 100, b => 200 };

    my $edge = Graphviz::DSL::Edge->new(
        start => $start,
        end   => $end,
        attributes => $attrs
    );

    ok $edge->start == $start, "'start' accessor";
    ok $edge->end   == $end, "'end' accessor";
    is_deeply $edge->attributes, $attrs, "'attributes' accessor";
};

subtest 'output to string' => sub {
    my $edge = Graphviz::DSL::Edge->new(
        start => Graphviz::DSL::Node->new(id => 'foo', port => 'a'),
        end   => Graphviz::DSL::Node->new(id => 'bar', port => 'b'),
    );
    my $str = $edge->as_string(1);
    is $str, '"foo:a" -> "bar:b"', 'as String with port';

    my $edge_noport = Graphviz::DSL::Edge->new(
        start => Graphviz::DSL::Node->new(id => 'foo'),
        end   => Graphviz::DSL::Node->new(id => 'bar'),
    );
    is $edge_noport->as_string(1), '"foo" -> "bar"', 'as String without port';
    is $edge_noport->as_string(0), '"foo" -- "bar"', 'as String without port(undirect)';
};

subtest 'update attributes' => sub {
    my $attrs = [[a => 100], [b => 200]];
    my $edge = Graphviz::DSL::Edge->new(
        start => Graphviz::DSL::Node->new(id => 'foo'),
        end   => Graphviz::DSL::Node->new(id => 'bar'),
        attributes => $attrs
    );

    $edge->update_attributes([[a => 300], [c => 400]]);
    my $expected = [[a => 300], [b => 200], [c => 400]];
    is_deeply $edge->attributes, $expected, 'update attributes';
};

subtest 'update edge', sub {
    my $edge = Graphviz::DSL::Edge->new(
        start => Graphviz::DSL::Node->new(id => 'foo'),
        end   => Graphviz::DSL::Node->new(id => 'bar'),
    );
    can_ok $edge, 'update_edge';

    $edge->update_edge(
        Graphviz::DSL::Node->new(id => 'foo', port => 'a', compass => 'aa'),
        Graphviz::DSL::Node->new(id => 'bar', port => 'b', compass => 'bb'),
    );

    my ($start, $end) = ($edge->start, $edge->end);

    is $start->{id}, 'foo', "'start' parameter";
    is $start->{port}, 'a', "update 'start port'";
    is $start->{compass}, 'aa', "update 'start compass'";
    is $end->{id}, 'bar', "'end' parameter";
    is $end->{port}, 'b', "update 'end port'";
    is $end->{compass}, 'bb', "update 'end compass'";
};

subtest 'equal to the edge' => sub {
    Graphviz::DSL::Node->new(id => 'foo');
    Graphviz::DSL::Node->new(id => 'bar');

    my $edge = Graphviz::DSL::Edge->new(
        start => Graphviz::DSL::Node->new(id => 'foo'),
        end   => Graphviz::DSL::Node->new(id => 'bar'),
    );

    ok $edge->equal_to($edge), 'equal to same ID';

    my $edge2 = Graphviz::DSL::Edge->new(
        start => Graphviz::DSL::Node->new(id => 'foo', port => 'a'),
        end   => Graphviz::DSL::Node->new(id => 'bar', port => 'b'),
    );
    ok $edge->equal_to($edge2), 'equal to same ID with port';
};

subtest 'invalid constructor' => sub {
    eval {
        Graphviz::DSL::Edge->new;
    };
    like $@, qr/missing mandatory parameter 'start'/, "missing 'start' parameter";

    eval {
        Graphviz::DSL::Edge->new(start => 'foo');
    };
    like $@, qr/should isa/, "invalid start parameter class";

    eval {
        Graphviz::DSL::Edge->new(
            start => Graphviz::DSL::Node->new(id => 'foo'),
        );
    };
    like $@, qr/missing mandatory parameter 'end'/, "missing 'end' parameter";

    eval {
        Graphviz::DSL::Edge->new(
            start => Graphviz::DSL::Node->new(id => 'foo'),
            end   => 'foo',
        );
    };
    like $@, qr/should isa/, "invalid end parameter class";
};

done_testing;
