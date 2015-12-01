#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 9;

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

{
    $SIG{__WARN__} = sub {};
    my $mock = Mock::Sub->new;
    my $fake = $mock->mock('X::y', return_value => 'true');

    my $ret = X::y();
    is ($ret, 'true', "successfully mocked a non-existent sub");
    is ($fake->{orig}, undef, "fake mock doesn't keep sub history");

    $fake->unmock;
    eval { X::y(); };
    like ($@, qr/Undefined subroutine/,
          "unmock() unloads the symtab entry for the faked sub"
    );
}
