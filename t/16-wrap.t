#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{
    my $w;
    my $mock = Mock::Sub->new;
    $w = $mock->wrap('wrap_1');

    is ($w->mocked_state, 1, "sub is mocked");

    is (wrap_1(), 'wrap_1', "wrapped sub with no pre/post does the right thing");
}
{
    my $w;
    my $mock = Mock::Sub->new;

    eval {$w = $mock->wrap('wrap_1', pre => 'adsf'); };
    like ($@, qr/\Qwrap()'s 'pre' param\E/, "wrap() pre param needs cref");
}
{
    my $w;
    my $mock = Mock::Sub->new;

    eval { $w = $mock->wrap('wrap_1', post => 'adsf'); };
    like ($@, qr/\Qwrap()'s 'post' param\E/, "wrap() post param needs cref");
}
{
    my $w;
    my $mock = Mock::Sub->new;

    eval { $w = $mock->wrap('wrap_1', pre => sub {return 10; } ); };
    is (ref $w, 'Mock::Sub::Child', "wrap()'s pre param works with a cref" );
}
{
    my $w;
    my $mock = Mock::Sub->new;

    eval { $w = $mock->wrap('wrap_1', post => sub { return 10; }); };
    is (ref $w, 'Mock::Sub::Child', "wrap()'s post param works with a cref" );
}
{
    my $w;
    my $mock = Mock::Sub->new;

    my $msg;
    $SIG{__WARN__} = sub { $msg = shift; };

    $w = $mock->wrap('wrap_1', side_effect => sub { return; });
    like ($msg, qr/side_effect parameter has/, "side_effect in wrap() warns");

    is ($w->{side_effect}, undef, "side_effect param gets removed in wrap()");
}
{
    my $w;
    my $mock = Mock::Sub->new;

    my $msg;
    $SIG{__WARN__} = sub { $msg = shift; };

    $w = $mock->wrap('wrap_1', return_value => sub { return; });
    like ($msg, qr/return_value parameter has/, "side_effecct in wrap() warns");

    is ($w->{return_value}, undef, "return_value param gets removed in wrap()");
}




done_testing();

sub wrap_1 {
    return "wrap_1";
}
sub wrap_2 {
    my $list = [qw(1 2 3 4 5)];
    return $list;
}
