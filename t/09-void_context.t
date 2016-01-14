#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 11;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{
    my $mock = Mock::Sub->new;
    eval { Mock::Sub->mock('One::foo', side_effect => sub { die "died"; }); };
    like ($@, qr/calling mock\(\) on the Mock::Sub/, "class calling mock() dies");
}
{
    my $mock = Mock::Sub->new;
    eval { $mock->mock('One::foo', side_effect => sub { die "died"; }); };
    like ($@, qr/in void context/, "obj calling mock() in void context dies");
}
{
    my $child = Mock::Sub::Child->new;
    eval { $child->mock('One::foo', side_effect => sub { die "died"; }); };
    like (
        $@, qr/can't call mock()/,
        "can't call mock() on child if it wasn't initialized by Mock::Sub"
    );
}
{
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo', return_value => 'void');
    my $ret = One::foo();

    is ($ret, 'void', "configured for the void test");

    $foo->unmock;
    $ret = One::foo();

    is ($ret, 'foo', "child object is unmocked");
    is ($foo->mocked_state, 0, "confirm child obj is unmocked");

    $foo->mock;
    $ret = One::foo();

    is ($foo->mocked_state, 1, "child obj calling mock in void w/ no params is mocked");
    is ($ret, undef, "child obj calling mock in void w/ params is mocked");

    $foo->mock(return_value => 'void');
    $ret = One::foo();
    is ($ret, 'void', "child obj calling mock in void with return_value works");
}
