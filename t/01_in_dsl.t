use strict;
use warnings;
use Test::More;

use Graph::Gviz;

subtest 'call outside graph function' => sub {
    my @funcs = qw/route add node edge nodes edges nodeset edgeset global rank
                   name type subgraph/;
    for my $method (@funcs) {
        eval {
            Graph::Gviz->$method();
        };
        like $@, qr/Can't call $method/, "Can't call '$method'";
    }
};

done_testing;
