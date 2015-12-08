#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{# called()

    my $test = Mock::Sub->mock('One::foo');

    is ($test->called, 0, "called() before a call is correct");

    Two::test;

    is ($test->called, 1, "called() is 1 after one call");

    Two::test;

    is ($test->called, 1, "called() is still 1 after two calls");
}

