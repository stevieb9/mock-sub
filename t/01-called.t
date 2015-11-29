#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;

use lib 't/data';

BEGIN {
    use_ok('B');
    use_ok('Test::MockSub');
};

{# called()

    my $test = Test::MockSub->mock('A::foo');
    B::test;
    B::test;

    my $called = $test->called;
    is ($called, 1, "count() does the right thing after one call");
}

