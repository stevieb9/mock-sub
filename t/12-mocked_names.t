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
#    my $bar = $mock->mock('One::bar');
#    my $baz = $mock->mock('One::baz');

    my @names;

    @names = $mock->mocked_names;
    is (@names, 1, "return is correct");

    $foo->unmock;

    @names = $mock->mocked_names;
    is (@names, 0, "after unmock, return is correct");
#    ok (! grep /foo/, @names, "the unmocked sub isn't in the list of names");

    $foo->mock('One::foo');

    print Dumper $foo;
    @names = $mock->mocked_names;
    is (@names, 1, "after re-mock, return is correct");
    ok (grep /foo/, @names, "the re-mocked sub is in the list of names");
}
