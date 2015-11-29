#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{# call_count()

    my $test = Mock::Sub->mock('One::foo');

    Two::test;
    is ($test->call_count, 1, "count() does the right thing after one call");

    Two::test;
    Two::test;
    Two::test;
    Two::test;
    is ($test->call_count, 5, "count() does the right thing after one call");
}

