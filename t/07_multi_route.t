use strict;
use warnings;
use Test::More;

use Graphviz::DSL;

subtest 'multi route' => sub {
    my $graph = graph {
        multi_route [a => [qw/b c d/] => e => [qw/f g/]];
    };

    my @expected = (
        [a => 'b'], [a => 'c'], [a => 'd'],
        [b => 'e'], [c => 'e'], [d => 'e'],
        [e => 'f'], [e => 'g'],
    );

    my @gots;
    for my $edge (@{$graph->{edges}}) {
        push @gots, [ $edge->start->id, $edge->end->id ];
    }

    is_deeply \@gots, \@expected;
};

subtest 'multi route(all scalar)' => sub {
    my $graph = graph {
        multi_route [a => b => c => 'd'];
    };

    my @expected = (
        [a => 'b'], [b => 'c'], [c => 'd'],
    );

    my @gots;
    for my $edge (@{$graph->{edges}}) {
        push @gots, [ $edge->start->id, $edge->end->id ];
    }

    is_deeply \@gots, \@expected;
};

subtest 'multi route(all ArrayRef)' => sub {
    my $graph = graph {
        multi_route [['a', 'b'] => ['c'] => ["e", 'f', 'g'] => ['h']];
    };

    my @expected = (
        [a => 'c'], [b => 'c'],
        [c => 'e'], [c => 'f'], [c => 'g'],
        [e => 'h'], [f => 'h'], [g => 'h'],
    );

    my @gots;
    for my $edge (@{$graph->{edges}}) {
        push @gots, [ $edge->start->id, $edge->end->id ];
    }

    is_deeply \@gots, \@expected;
};

done_testing;
