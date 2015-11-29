#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 6;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{# reset()

    my $foo = Mock::Sub->mock('One::foo', return_value => 1);
    my $ret1 = Two::test;
    
    $foo->reset;

    my $ret2 = Two::test;

    is ($ret1, 1, "before reset, return_value is ok");
    is ($ret2, undef, "after reset, return_value is reset");

    $foo = Mock::Sub->mock('One::foo', side_effect => sub {return 10;});

    my $ret3 = Two::test;

    is ($ret3, 10, "before reset, side_effect does the right thing");

    $foo->reset;

    my $ret4 = Two::test;
    
    is ($ret4, undef, "after reset, side_effect does nothing");
}
