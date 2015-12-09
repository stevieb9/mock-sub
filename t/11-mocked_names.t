#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 11;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{
    my $mock = Mock::Sub->new;

    my $foo = $mock->mock('One::foo');
}
