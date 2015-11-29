#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 13;

use lib 't/data';

BEGIN {
    use_ok('B');
    use_ok('Test::MockSub');
};

{# mock() instantiate

    my $test = Test::MockSub->mock('A::foo');
    is (ref $test, 'Test::MockSub', "instantiating with mock() works");

    B::test;
    is ($test->call_count, 1, "instantiating with mock() can call methods");
}
{# new() instantiate

    my $mock = Test::MockSub->new;
    is (ref $mock, 'Test::MockSub', "instantiating with new() works");

    my $test = $mock->mock('A::foo');
    B::test;
    is ($test->call_count, 1, "instantiating within an object works");
}
{ 

    my $mock = Test::MockSub->new;
    is (ref $mock, 'Test::MockSub', "instantiating with new() works");
    
    my $test1 = $mock->mock('A::foo');
    my $test2 = $mock->mock('A::bar');
    my $test3 = $mock->mock('A::baz');

    B::test;
    B::test2;
    B::test2;
    B::test3;
    B::test3;
    B::test3;

    is ($test1->call_count, 1, "1st mock from object does the right thing");
    is ($test2->call_count, 2, "2nd mock from object does the right thing");
    is ($test3->call_count, 3, "3rd mock from object does the right thing");

    B::test;
    B::test2;
    B::test2;
    B::test3;
    B::test3;
    B::test3;

    is ($test1->call_count, 2, "2nd 1st mock from object does the right thing");
    is ($test2->call_count, 4, "2nd 2nd mock from object does the right thing");
    is ($test3->call_count, 6, "2nd 3rd mock from object does the right thing");
}
