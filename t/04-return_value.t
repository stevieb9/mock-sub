#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;

use lib 't/data';

BEGIN {
    use_ok('B');
    use_ok('Test::MockSub');
};

{# return_value

    my $foo = Test::MockSub->mock('A::foo', return_value => 'True');
    B::test;
    my $ret = B::test;

    is ($foo->call_count, 2, "mock obj with return_value has right call count");
    is ($ret, 'True', "mock obj with return_value has right ret val");
}
