#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 6;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{
    my $mock = Mock::Sub->new;

    my $foo = $mock->mock('One::foo', return_value => 'Mocked');
    my $ret = One::foo();
    is ($ret, 'Mocked', "One::foo is mocked");

    $foo->unmock;
    $ret = One::foo();
    is ($ret, 'foo', "One::foo is now unmocked with unmock()");

    $foo = $mock->mock('One::foo', return_value => 'Mocked');
    $ret = One::foo();
    is ($ret, 'Mocked', "One::foo is mocked after being unmocked");

    $foo->unmock;
    $ret = One::foo();
    is ($ret, 'foo', "One::foo is now unmocked again");
}

