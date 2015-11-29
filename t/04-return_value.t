#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{# return_value

    my $foo = Mock::Sub->mock('One::foo', return_value => 'True');
    Two::test;
    my $ret = Two::test;

    is ($foo->call_count, 2, "mock obj with return_value has right call count");
    is ($ret, 'True', "mock obj with return_value has right ret val");
}
