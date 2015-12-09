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
    is ($foo->mocked_state('One::foo'), 1, "obj 1 has proper mock state");
    is ($mock->mocked_state('One::foo'), 1, "mock has proper mock state on obj 1");

    my $bar = $mock->mock('One::bar');
    is ($bar->mocked_state('One::bar'), 1, "obj 2 has proper mock state");
    is ($bar->mocked_state('One::bar'), 1, "mock has proper mock state on obj 2");

    $foo->unmock;
    is ($foo->mocked_state('One::foo'), 0, "obj 1 has proper unmock state");
    is ($mock->mocked_state('One::foo'), 0, "mock has proper ummock state on obj 1");

    my $mock2 = Mock::Sub->new;

    $foo->mock('One::foo');
    is ($foo->mocked_state('One::foo'), 1, "obj has proper mock state with 2 mocks");
    is ($mock2->mocked_state('One::foo'), undef, "mock2 can't see into mock 1");
    is ($foo->mocked_state('One::foo'), 1, "...and original mock obj still has state");

}
