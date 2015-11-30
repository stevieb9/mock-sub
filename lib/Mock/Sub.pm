package Mock::Sub;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.08';

sub new {
    return bless {}, shift;
}
sub mock {
    
    shift; # throw away class/object

    my $self = bless {}, __PACKAGE__;
    my $sub = shift;
    %{ $self } = @_;

    if (! exists &$sub){
        die "subroutine specified is not valid";
    }

    $self->{name} = $sub;

    # can't do side_effect and return_value in one pass (yet)

    if (defined $self->{return_value} && defined $self->{side_effect}){
        die "use only one of return_value or side_effect";
    }

    # side_effect must be a legit code reference

    if (defined $self->{side_effect} && ref $self->{side_effect} ne 'CODE'){
        die "side_effect parameter must be a code reference";
    }

    my $called;

    {
        no strict 'refs';
        no warnings 'redefine';

        *$sub = sub {
            @{ $self->{called_with} } = @_;
            $self->{called_count} = ++$called;
            return $self->{side_effect}->() if $self->{side_effect};
            return $self->{return_value} if defined $self->{return_value};
        };
    }
    return $self;
}
sub called {
    return shift->called_count ? 1 : 0;
}
sub called_count {
    return shift->{called_count};
}
sub called_with {
    return @{ shift->{called_with} };
}
sub name {
    return shift->{name};  
}
sub reset {
    my $self = shift;
    for (qw(side_effect return_value called called_count called_with)){
        delete $self->{$_};
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
    $foo->called_count;   # how many times was it called?

    # create a mock object to reduce typing when multiple subs
    # are mocked

    my $mock = Mock::Sub->new;

    my $foo = $mock->mock('Package::foo');
    my $bar = $mock->mock('Package::bar');

    # have the mocked sub return something when it's called (you can use void
    # context if you don't need the functionality of the object)

    $mock->mock('Package::foo', return_value => 'True');
    my $return = Package::foo;

    # have the mocked sub perform an action (void context again)

    $mock->mock('Package::foo', side_effect => sub { die "eval catch"; });
    eval { Package::foo; };
    print 'died' if $@;

    # extract the parameters the sub was called with (best if you know what
    # the original sub is expecting

    my @args = $foo->called_with;

    # reset the mocked sub for re-use within the same scope

    $foo->reset;


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

Instantiates a new object on each call. 'sub' is the name of the subroutine
to mock (requires full package name if the sub isn't in C<main::>).

Options:

return_value: Set this to have the mocked sub return anything you wish.

side_effect: Send in a code reference containing an action you'd like the
mocked sub to perform (C<die()> is useful for testing with C<eval()>).

Note that only one of these parameters may be sent in at a time.

=head2 C<called>

Returns true if the sub being mocked has been called.

=head2 C<called_count>

Returns the number of times the mocked sub has been called.

=head2 C<called_with>

Returns an array of the parameters sent to the subroutine.

=head2 C<name>

Returns the full name of the sub being mocked, as entered into C<mock()>.

=head2 C<reset>

Resets the functional parameters (C<return_value>, C<side_effect>), along
with C<called()> and C<called_count> back to undef/untrue.

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

