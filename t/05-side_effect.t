#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 6;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{# side_effect
    
    my $cref = sub {die "throwing error";};
    my $foo = Mock::Sub->mock('One::foo', side_effect => $cref);
    eval{Two::test;};
    like ($@, qr/throwing error/, "side_effect with a cref works");
}
{# side_effect

    my $href = {};
    eval {Mock::Sub->mock('One::foo', side_effect => $href);};
    like ($@, qr/side_effect param/, "mock() dies if side_effect isn't a cref");
}
{
    eval {Mock::Sub->mock('One::foo', side_effect => sub {}, return_value => 1);};
    like ($@, qr/use only one of/, "mock() dies if both side_effect and return_value are supplied");
}
{
    my $cref = sub {50};
    my $foo = Mock::Sub->mock('One::foo', side_effect => $cref);
    my $ret = Two::test;
    is ($ret, 50, "side_effect properly returns a value if die() isn't called")
}
