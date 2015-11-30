#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{
    Mock::Sub->mock('One::foo', side_effect => sub { die "died"; });
    eval { One::foo; };
    like ($@, qr/died/, "side_effect in void context works");
}
{
    Mock::Sub->mock('One::foo', return_value => 'True');
    my $ret = One::foo;
    is ($ret, 'True', "return_value in void context works");
}

