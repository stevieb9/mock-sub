#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 14;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{# mock() instantiate

    my $test = Mock::Sub->mock('One::foo');
    is (ref $test, 'Mock::Sub', "instantiating with mock() works");

    Two::test;
    is ($test->called_count, 1, "instantiating with mock() can call methods");
}
{# new() instantiate

    my $mock = Mock::Sub->new;
    is (ref $mock, 'Mock::Sub', "instantiating with new() works");

    my $test = $mock->mock('One::foo');
    Two::test;
    is ($test->called_count, 1, "instantiating within an object works");
}
{ 

    my $mock = Mock::Sub->new;
    is (ref $mock, 'Mock::Sub', "instantiating with new() works");
    
    my $test1 = $mock->mock('One::foo');
    my $test2 = $mock->mock('One::bar');
    my $test3 = $mock->mock('One::baz');

    Two::test;
    Two::test2;
    Two::test2;
    Two::test3;
    Two::test3;
    Two::test3;

    is ($test1->called_count, 1, "1st mock from object does the right thing");
    is ($test2->called_count, 2, "2nd mock from object does the right thing");
    is ($test3->called_count, 3, "3rd mock from object does the right thing");

    Two::test;
    Two::test2;
    Two::test2;
    Two::test3;
    Two::test3;
    Two::test3;

    is ($test1->called_count, 2, "2nd 1st mock from object does the right thing");
    is ($test2->called_count, 4, "2nd 2nd mock from object does the right thing");
    is ($test3->called_count, 6, "2nd 3rd mock from object does the right thing");
}
{
    eval { my $test = Mock::Sub->mock('X::Yes'); };
    like ($@, qr/subroutine specified is not valid/, "dies if invalid sub param");
}
