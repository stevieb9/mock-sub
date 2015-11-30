#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{# called_count()

    my $test = Mock::Sub->mock('One::foo');

    Two::test;
    is ($test->called_count, 1, "count() does the right thing after one call");

    Two::test;
    Two::test;
    Two::test;
    Two::test;
    is ($test->called_count, 5, "count() does the right thing after one call");
}

