#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 8;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{# return_value

    my $foo = Mock::Sub->mock('One::foo', return_value => 'True');
    Two::test;
    my $ret = Two::test;

    is ($foo->called_count, 2, "mock obj with return_value has right call count");
    is ($ret, 'True', "mock obj with return_value has right ret val");
}
{# return_value

    my $foo = Mock::Sub->mock('One::foo');
    my $ret = Two::test;

    is ($ret, '', "no return_value set yet");

    $foo->return_value(50);
    $ret = Two::test;
    is ($ret, 50, "return_value() does the right thing when adding");

    $foo->return_value('hello');
    $ret = Two::test;
    is ($ret, 'hello', "return_value() updates the value properly");

    $foo->return_value(undef);
    $ret = Two::test;
    is ($ret, '', "return_value() undef's the value properly");
}
