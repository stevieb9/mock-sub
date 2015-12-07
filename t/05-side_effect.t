#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 15;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{# side_effect
    
    my $cref = sub {die "throwing error";};
    Mock::Sub->mock('One::foo', side_effect => $cref);
    eval{Two::test;};
    like ($@, qr/throwing error/, "side_effect with a cref works");
}
{# side_effect

    my $href = {};
    eval {Mock::Sub->mock('One::foo', side_effect => $href);};
    like ($@, qr/side_effect param/, "mock() dies if side_effect isn't a cref");
}
{
    eval {Mock::Sub->mock('One::foo', side_effect => sub {}, return_value => 1);};
#    like ($@, qr/use only one of/, "mock() dies if both side_effect and return_value are supplied");
}
{
    my $cref = sub {50};
    my $foo = Mock::Sub->mock('One::foo', side_effect => $cref);
    my $ret = Two::test;
    is ($ret, 50, "side_effect properly returns a value if die() isn't called")
}
{
    my $cref = sub {'False'};
    my $foo = Mock::Sub->mock(
        'One::foo',
        side_effect => $cref,
        return_value => 'True');
    my $ret = Two::test;
    is ($ret, 'False', "side_effect with value returns with return_value");
}
{
    my $cref = sub {undef};
    my $foo = Mock::Sub->mock(
        'One::foo',
        side_effect => $cref,
        return_value => 'True');
    my $ret = Two::test;
    is ($ret, 'True', "side_effect with no value, return_value returns");
}
{
    my $foo = Mock::Sub->mock('One::foo');
    my $ret = Two::test;

    is ($ret, '', "no side effect set yet");

    $foo->side_effect(sub {50});

    $ret = Two::test;

    is ($ret, 50, "side_effect() can add an effect after instantiation");

}
{
    my $foo = Mock::Sub->mock('One::foo');

    eval { $foo->side_effect(10); };

    like ($@, qr/side_effect parameter/,
          "side_effect() can add an effect after instantiation"
    );

}
{
    my $foo = Mock::Sub->mock('One::foo');

    my $cref = sub {
        return \@_;
    };
    $foo->side_effect($cref);

    my $ret = One::foo(1, 2, {3 => 'a'});

    is (ref $ret, 'ARRAY', 'side_effect now has access to called_with() args');
    is ($ret->[0], 1, 'side_effect 1st arg is 1');
    is ($ret->[1], 2, 'side_effect 2nd arg is 2');
    is (ref $ret->[2], 'HASH', 'side_effect 3rd arg is a hash');
    is ($ret->[2]{3}, 'a', 'side_effect args work properly')
}

