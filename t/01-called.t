#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{# called()

    my $test = Mock::Sub->mock('One::foo');
    Two::test;
    Two::test;

    my $called = $test->called;
    is ($called, 1, "count() does the right thing after one call");
}

