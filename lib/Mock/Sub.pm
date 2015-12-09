package Mock::Sub;
use 5.006;
use strict;
use warnings;

use Carp qw(croak);
use Data::Dumper;
use Scalar::Util qw(weaken);

our $VERSION = '1.02';

sub new {
    my $self = bless {}, shift;
    %{ $self } = @_;

    if ($self->{side_effect}){
        $self->_check_side_effect($self->{side_effect});
    }
    return $self;
}
sub mock {

    my $thing = shift;
    my $sub = shift;
    my $self;

    if (ref($thing) eq __PACKAGE__ && $thing->{unmocked}){
        $self = $thing;
        $self->{unmocked} = 0;
    }
    else {
        $self = bless {}, __PACKAGE__;
        if (! defined wantarray){
            croak "\n\ncalling mock() in void context isn't allowed. ";
        }
    }

    %{ $self } = @_;

    if (ref($thing) eq __PACKAGE__){

        $self->{mock} = $thing;
        $self->_mocked($sub, 1);

        if ($thing->{side_effect}){
            $self->{side_effect} = $thing->{side_effect};
        }
        if (defined $thing->{return_value}){
            $self->{return_value} = $thing->{return_value};
        }
        undef $thing;
    }

    $sub = "main::$sub" if $sub !~ /::/;

    my $fake;

    if (! exists &$sub){
        $fake = 1;
        warn "\n\nWARNING!: we've mocked a non-existent subroutine. " .
             "the specified sub does not exist.\n\n";
    }

    $self->_check_side_effect($self->{side_effect});
    push @{ $self->{return} }, $self->{return_value};

    $self->{name} = $sub;
    $self->{orig} = \&$sub if ! $fake;

    $self->{called_count} = 0;

    {
        no strict 'refs';
        no warnings 'redefine';

        my $mock = $self;
        weaken $mock;

        *$sub = sub {

            @{ $mock->{called_with} } = @_;
            ++$mock->{called_count};

            if ($mock->{side_effect}) {
                if (wantarray){
                    my @effect = $mock->{side_effect}->(@_);
                    return @effect if @effect;
                }
                else {
                    my $effect = $mock->{side_effect}->(@_);
                    return $effect if defined $effect;
                }
            }

            return if ! $mock->{return};

            return ! wantarray && @{ $mock->{return} } == 1
                ? $mock->{return}[0]
                : @{ $mock->{return} };
        };
    }
    return $self;
}
sub unmock {
    my $self = shift;
    my $sub = $self->{name};

    $self->{unmocked} = 1;
    $self->_mocked($sub, 0);

    {
        no strict 'refs';
        no warnings 'redefine';

        if (defined $self->{orig}) {
            *$sub = \&{ $self->{orig} };
        }
        else {
            undef *$sub if $self->{name};
        }
    }

    $self->reset;
}
sub called {
    return shift->called_count ? 1 : 0;
}
sub called_count {
    return shift->{called_count} || 0;
}
sub called_with {
    my $self = shift;
    if (! $self->called){
        croak "\n\ncan't call called_with() before the mocked sub has " .
            "been called. ";
    }
    return @{ $self->{called_with} };
}
sub name {
    return shift->{name};  
}
sub reset {
    for (qw(side_effect return_value return called called_count called_with)){
        delete $_[0]->{$_};
    }
}
sub return_value {
    my $self = shift;
    @{ $self->{return} } = @_;
}
sub side_effect {
    $_[0]->_check_side_effect($_[1]);
    $_[0]->{side_effect} = $_[1];
}
sub _check_side_effect {
    if (defined $_[1] && ref $_[1] ne 'CODE') {
        croak "\n\nside_effect parameter must be a code reference. ";
    }
}
sub mocked_names {
    my $self = shift;

    my @names;

    for (keys %{ $self->{mocked} }) {
        print $self->{mocked}{$_}{state};
        if ($self->{mocked}{$_}{state}){
            push @names, $_;
        }
    }
    return @names;
}
sub mocked_objects {
    my $self = shift;

    my @mocked;
    for (keys %{ $self->{mocked} }){
        push @mocked, $self->{mocked}{$_}{object};
    }
    return @mocked;
}
sub mocked_state {
    my ($self, $sub) = @_;
    if ($self->{mock}){
        # we're a child
        return $self->{state};
    }
    else {
        # we're a mock
        return $self->{mocked}{$sub}{state};
    }
}
sub _mocked {
    my ($self, $sub, $state) = @_;
    if (! defined $sub && (caller(2))[3] !~ /DESTROY/){
        croak "_mocked() requires both a sub name and state passed in ";
    }
    if ($self->{mock} && ref($self->{mock}) ne 'SCALAR' ){
        $self->{mock}{mocked}{$sub}{state} = $state || 0;
        $self->{state} = $state || 0;
        $self->{mock}{mocked}{$sub}{name} = $self->{name};
    }
}
sub DESTROY {
    $_[0]->unmock;
}
sub _end {}; # vim fold placeholder

1;
=head1 NAME

Mock::Sub - Mock package, object and standard subroutines, with unit testing in mind.


=head1 SYNOPSIS

    # see EXAMPLES for a full use case and caveats

    use Mock::Sub;

    my $foo = Mock::Sub->mock('Package::foo');

    # wait until the mocked sub is called

    Package::foo();

    # then...

    $foo->name;         # name of sub that's mocked
    $foo->called;       # was the sub called?
    $foo->called_count; # how many times was it called?
    $foo->called_with;  # array of params sent to sub

    # create a mock object to reduce typing when multiple subs are mocked

    my $mock = Mock::Sub->new;

    my $foo = $mock->mock('Package::foo');
    my $bar = $mock->mock('Package::bar');

    # have the mocked sub return something when it's called (list or scalar).
    # See new() to find out how to set a return value once and have it used in
    # all child mocks

    $foo->return_value(1, 2, {a => 1});
    my @return = Package::foo;

    # have the mocked sub perform an action (the side effect function receives
    # the parameters sent into the mocked sub). See new() to find out how to
    # set side_effect up once, and have it copied to all child mocks

    $foo->side_effect( sub { die "eval catch" if @_; } );

    eval { Package::foo(1); };
    like ($@, qr/eval catch/, "side_effect worked with params");

    # extract the parameters the sub was called with (best if you know what
    # the original sub is expecting)

    my @args = $foo->called_with;

    # reset the mock object for re-use within the same scope (does not restore
    # the mocked sub)

    $foo->reset;

    # restore original functionality to the sub (we do this by default on
    # DESTROY()). This also calls reset() on the ojbect

    $foo->unmock;

    # re-mock a sub using the same object after unmocking (this is the only
    # time void context with mock() is permitted)

    $foo->mock('One::foo');

=head1 DESCRIPTION

Easy to use and very lightweight module for mocking out sub calls.
Very useful for testing areas of your own modules where getting coverage may
be difficult due to nothing to test against, and/or to reduce test run time by
eliminating the need to call subs that you really don't want or need to test.

=head1 EXAMPLE

Here's a full example to get further coverage where it's difficult if not
impossible to test certain areas of your code (eg: you have if/else statements,
but they don't do anything but call other subs. You don't want to test the
subs that are called, nor do you want to add statements to your code).

Note that if the end subroutine you're testing is NOT Object Oriented (and
you're importing them into your module that you're testing), you have to mock
them as part of your own namespace (ie. instead of Other::first, you'd mock
MyModule::first).

   # module you're testing:

    package MyPackage;
    
    use Other;
    use Exporter qw(import);
    @EXPORT_OK = qw(test);
   
    my $other = Other->new;

    sub test {
        my $arg = shift;
        
        if ($arg == 1){
            # how do you test this... there's no return etc.
            $other->first();        
        }
        if ($arg == 2){
            $other->second();
        }
    }

    # your test file

    use MyPackage qw(test);
    use Mock::Sub;
    use Test::More tests => 2;

    my $mock = Mock::Sub->new;

    my $first = $mock->mock('Other::first');
    my $second = $mock->mock('Other::second');

    # coverage for first if() in MyPackage::test
    test(1);
    is ($first->called, 1, "1st if() statement covered");

    # coverage for second if()
    test(2);
    is ($second->called, 1, "2nd if() statement covered");


=head1 METHODS

=head2 C<new(%opts)>

Instantiates and returns a new C<Mock::Sub> object.

Optional options:

=over 4

=item C<return_value>

Set this to have all mocked subs created with this mock object return anything
you wish (accepts a single scalar only. See C<return_value()> method to return
a list and for further information). You can also set it in individual mocks
only (see C<mock()>).

=item C<side_effect>

Set this in C<new()> to have the side effect passed into all child mocks
created with this object. See C<side_effect()> method.

=back

=head2 C<mock('sub', %opts)>

Instantiates a new object on each call (calling in void context is not
allowed). 'sub' is the name of the subroutine to mock (requires full package
name if the sub isn't in C<main::>).

The mocked sub will return undef if a return value isn't set, or a side effect
doesn't return anything.

Optional options:

Both C<return_value> and C<side_effect> can be set in this method to
individualize each mock object. Set in C<new> to have all mock objects use
the same configuration.

There's also C<return_value()> and C<side_effect()> methods if you want to
set, change or remove these values after instantiation.

=head2 C<unmock>

Restores the original functionality back to the sub, and runs C<reset()> on
the object.

=head2 C<called>

Returns true if the sub being mocked has been called.

=head2 C<called_count>

Returns the number of times the mocked sub has been called.

=head2 C<called_with>

Returns an array of the parameters sent to the subroutine. C<croak()s> if
we're called before the mocked sub has been called.

=head2 C<name>

Returns the full name of the sub being mocked, as entered into C<mock()>.

=head2 C<side_effect($cref)>

Add (or change/remove) a side effect after instantiation.

Send in a code reference containing an action you'd like the
mocked sub to perform (C<die()> is useful for testing with C<eval()>).

The side effect function will receive all parameters sent into the mocked sub.

You can use both C<side_effect()> and C<return_value()> params at the same
time. C<side_effect> will be run first, and then C<return_value>. Note that if
C<side_effect>'s last expression evaluates to any value whatsoever
(even false), it will return that and C<return_value> will be skipped.

To work around this and have the side_effect run but still get the
return_value thereafter, write your cref to evaluate undef as the last thing
it does: C<sub { ...; undef; }>.


=head2 C<return_value>

Add (or change, delete) the mocked sub's return value after instantiation.
Can be a scalar or list. Send in C<undef> to remove a previously set value.

=head2 C<reset>

Resets the functional parameters (C<return_value>, C<side_effect>), along
with C<called()> and C<called_count()> back to undef/false.

=head1 NOTES

I didn't make this a C<Test::> module (although it started that way) because
I can see more uses than placing it into that category.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 BUGS

Please report any bugs or requests at
L<https://github.com/stevieb9/mock-sub/issues>

=head1 REPOSITORY

L<https://github.com/stevieb9/mock-sub>

=head1 BUILD RESULTS

Travis-CI: L<https://travis-ci.org/stevieb9/mock-sub>

CPAN Testers: L<http://matrix.cpantesters.org/?dist=Mock-Sub>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mock::Sub

=head1 ACKNOWLEDGEMENTS

Python's MagicMock module.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Mock::Sub

