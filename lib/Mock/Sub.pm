package Mock::Sub;

use 5.006;
use strict;
use warnings;
use Data::Dumper;
our $VERSION = '0.02';

sub new {
    return bless {}, shift;
}
sub mock {
    
    shift; # throw away class/object

    my $self = bless {}, __PACKAGE__;
    my $sub = shift;
    %{ $self } = @_;

    if (defined $self->{return_value} && defined $self->{side_effect}){
        die "use only one of return_value or side_effect";
    }

    if (defined $self->{side_effect} && ref $self->{side_effect} ne 'CODE'){
        die "side_effect param must be a cref";
    }

    my $called;

    {
        no strict 'refs';
        no warnings 'redefine';

        *$sub = sub {
            $self->{name} = $sub;
            $self->{call_count} = ++$called; 
            return $self->{return_value} if defined $self->{return_value};
            $self->{side_effect}->() if $self->{side_effect};
        };
    }

    return $self;
}
sub called {
    return shift->call_count ? 1 : 0;
}
sub call_count {
    return shift->{call_count};
}
sub name {
    my $self = shift;
    print Dumper $self;
    return $self->{name};  
}
sub reset {
    my $self = shift;
    for (qw(side_effect return_value)){
        delete $self->{$_};
    }
}
sub _end {}; # vim placeholder

1;
=head1 NAME

Mock::Sub - Mock package, module, object and standard subs, with ability to collect stats.


=head1 SYNOPSIS

    use Mock::Sub;

    my $foo = Mock::Sub->mock('Package::foo');
    my $bar = Mock::Sub->mock('Package::bar');
    my $baz = Mock::Sub->mock('Package::baz');

    # wait until the mocked sub is called

    Package::foo();

    # then...

    $foo->name;         # name of sub that's mocked
    $foo->called;       # was the sub called?
    $foo->call_count;   # how many times was it called?

    # create a mock object to reduce typing

    my $mock = Mock::Sub->new;
    
    my $foo = $mock->('Package::foo');
    my $bar = $mock->('Package::bar');
    my $baz = $mock->('Package::baz');

    # have the mocked sub return something when it's called

    $foo = $mock->('Package::foo', return_value => 'True');

    # have the mocked sub perform an action

    $foo = $mock->('Package::foo', side_effect => sub { die "eval catch"; });
    

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
    is ($first->called, 1, "first if() covered");

    # coverage for second if()
    test(2);
    is ($second->called, 1, "first if() covered");


=head1 METHODS



=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-mocksub at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-MockSub>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mock::Sub


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-MockSub>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Mock::Sub
