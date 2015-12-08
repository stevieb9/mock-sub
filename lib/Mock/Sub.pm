package Mock::Sub;
use 5.006;
use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(weaken isweak);

our $VERSION = '0.11';

sub new {
    return bless {}, shift;
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
            croak "\n\ncalling mock() in void context isn't allowed.";
        }
    }

    %{ $self } = @_;

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

    if (! $fake) {
        $self->{orig} = \&$sub;
    }

    my $called;

    {
        no strict 'refs';
        no warnings 'redefine';


        *$sub = sub {

            weaken $self if ! isweak $self;

            @{ $self->{called_with} } = @_;
            $self->{called_count} = ++$called;
            if ($self->{side_effect}) {
                if (wantarray){
                    my @effect = $self->{side_effect}->(@_);
                    return @effect if @effect;
                }
                else {
                    my $effect = $self->{side_effect}->(@_);
                    return $effect if defined $effect;
                }
            }

            return undef if ! $self->{return};

            return ! wantarray && @{ $self->{return} } == 1
                ? $self->{return}[0]
                : @{ $self->{return} };
        };
    }
    return $self;
}
sub unmock {
    my $self = shift;
    my $sub = $self->{name};

    $self->{unmocked} = 1;

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
    return shift->{called_count};
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
sub DESTROY {
    my $self = shift;
    if (! $self->{keep_mock_on_destroy}){
        $self->unmock;
    }
}
sub _end {}; # vim fold placeholder

1;
=head1 NAME

Mock::Sub - Mock module, package, object and standard subroutines, with unit testing in mind.


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

    # have the mocked sub return something when it's called (list or scalar)

    $foo->return_value(1, 2, {a => 1});
    my @return = Package::foo;

    # have the mocked sub perform an action

    $foo->side_effect( sub { die "eval catch"; } );

    eval { Package::foo; };
    like ($@, qr/eval catch/, "side_effect worked");

    # extract the parameters the sub was called with (best if you know what
    # the original sub is expecting)

    my @args = $foo->called_with;

    # reset the mocked sub for re-use within the same scope

    $foo->reset;

    # restore original functionality to the sub (we do this by default on
    # DESTROY())

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

=head2 C<new>

Instantiates and returns a new Mock::Sub object.

=head2 C<mock('sub', %opts)>

Instantiates a new object on each call (calling in void context is not
allowed). 'sub' is the name of the subroutine to mock (requires full package
name if the sub isn't in C<main::>).

The mocked sub will return undef if a return value isn't set, or a side effect
doesn't return anything.

Options:

=over 4

=item C<return_value>

Set this to have the mocked sub return anything you wish (accepts a single
scalar only. See C<return_value()> method to return a list).

=item C<side_effect>

Send in a code reference containing an action you'd like the
mocked sub to perform (C<die()> is useful for testing with C<eval()>).

You can use both side_effect and return_value params at the same time.
side_effect will be run first, and then return_value. Note that if
side_effect's last expression evaluates to any value whatsoever (even false),
it will return that and return_value will be skipped.

To work around this and have the side_effect run but still get the
return_value thereafter, write your cref to evaluate undef as the last thing
it does: C<sub { ...; undef; }>.

=item C<keep_mock_on_destroy>

By default, we restore original sub functionality after the mock object goes
out of scope. You can keep the mocked sub in place by setting this parameter
to any true value.

=back

=head2 C<unmock>

Restores the original functionality back to the sub, and runs C<reset()> on
the object.

=head2 C<called>

Returns true if the sub being mocked has been called.

=head2 C<called_count>

Returns the number of times the mocked sub has been called.

=head2 C<called_with>

Returns an array of the parameters sent to the subroutine. C<dies()> if we're
called before the mocked sub has been called.

=head2 C<name>

Returns the full name of the sub being mocked, as entered into C<mock()>.

=head2 C<side_effect($cref)>

Add (or change/remove) a side effect after instantiation. Same rules apply
here as they do for the C<side_effect> parameter.

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

