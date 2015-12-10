#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{
    my $mock = Mock::Sub->new;
    eval { $mock->mock('One::foo', side_effect => sub { die "died"; }); };
    like ($@, qr/in void context/, "class calling mock() in void context dies");
}
{
    my $mock = Mock::Sub->new;
    eval { $mock->mock('One::foo', side_effect => sub { die "died"; }); };
    like ($@, qr/in void context/, "obj calling mock() in void context dies");
}
{
    my $child = Mock::Sub::Child->new;
    eval { $child->mock('One::foo', side_effect => sub { die "died"; }); };
    like ($@, qr/in void context/, "child calling mock() in void context dies");
}
