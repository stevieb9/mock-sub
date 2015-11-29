#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;

use lib 't/data';

BEGIN {
    use_ok('B');
    use_ok('Test::MockSub');
};

{# call_count()

    my $test = Test::MockSub->mock('A::foo');

    B::test;
    is ($test->call_count, 1, "count() does the right thing after one call");

    B::test;
    B::test;
    B::test;
    B::test;
    is ($test->call_count, 5, "count() does the right thing after one call");
}

