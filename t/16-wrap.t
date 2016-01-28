#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
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

    my @array = wrap_1();

    is (ref \@array, 'ARRAY', "in list context, no pre/post, return is array");
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
    local $SIG{__WARN__} = sub { $msg = shift; };

    $w = $mock->wrap('wrap_1', side_effect => sub { return; });
    like ($msg, qr/side_effect parameter has/, "side_effect in wrap() warns");

    is ($w->{side_effect}, undef, "side_effect param gets removed in wrap()");
}
{
    my $w;
    my $mock = Mock::Sub->new;

    my $msg;
    local $SIG{__WARN__} = sub { $msg = shift; };

    $w = $mock->wrap('wrap_1', return_value => sub { return; });
    like ($msg, qr/return_value parameter has/, "side_effect in wrap() warns");

    is ($w->{return_value}, undef, "return_value param gets removed in wrap()");
}
{
    my $mock = Mock::Sub->new;
    my $w = $mock->wrap('wrap_2');

    my @ret = wrap_2('hello', 'world');

    is ($ret[0], 'hello', "arg 1 passed in to sub works with pre()");
    is ($ret[1], 'world', "arg 2 passed into sub works (with pre())");
    is (ref $ret[2], 'ARRAY', "arg 3 passed into sub works (with pre())");
}
{
    my $msg;
    local $SIG{__WARN__} = sub { $msg = shift; };

    my $mock = Mock::Sub->new;
    my $w = $mock->wrap('wrap_2');

    $w->pre( sub { warn "test" ; } );

    wrap_2();

    like ($msg, qr/test/, "pre() sub does the right thing");
}
{
    my $mock = Mock::Sub->new;
    my $w = $mock->wrap('wrap_3');

    $w->pre( sub { return 50; } );
    $w->post( sub { return $_[0]->[0] + 50; }, return => 1);

    my $ret = wrap_3();

    is ($ret, 100, "wrap() with pre() and post() pass args ok");
}
{
    my $mock = Mock::Sub->new;
    my $w = $mock->wrap('wrap_1');

    $w->post(
        sub { my $x = $_[1]->[0]; $x =~ s/_1//; return $x; },
        return => 1
    );

    my $ret = wrap_1();

    is ($ret, 'wrap', "return param in post() works");
}
{
    my $mock = Mock::Sub->new;
    my $w = $mock->wrap('wrap_3');

    $w->post( sub { shift; my @a = @{$_[0]}; return $a[0] + 500; } );

    my $ret = wrap_3();

    is ($ret, 1000, "post() without return param returns original sub return");
}
{
    my $mock = Mock::Sub->new;
    my $w = $mock->wrap('wrap_1');

    wrap_3();

    is ($w->mocked_state, 1, "sub is wrapped");

    $w->unmock;

    is ($w->mocked_state, 0, "sub is unwrapped");
}

done_testing();

sub wrap_1 {
    return "wrap_1";
}
sub wrap_2 {
    my @args = @_;
    my $list = [qw(1 2 3 4 5)];
    return (@args, $list);
}
sub wrap_3 {
    return 1000;
}
sub wrap_4 {
    my @args = @_;
    my @nums;
    for (@args){
        push @nums, $_ * 10;
    }
    return @nums;
}
