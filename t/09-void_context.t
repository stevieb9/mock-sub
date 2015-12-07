#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{
    eval { Mock::Sub->mock('One::foo', side_effect => sub { die "died"; }); };
    like ($@, qr/in void context/, "calling mock() in void context dies");
}
