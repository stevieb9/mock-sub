#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{
    my $foo = Mock::Sub->mock('One::foo');
    One::foo;
    is ($foo->name, 'One::foo', "name() does the right thing");
}
