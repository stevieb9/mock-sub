package Mock::Sub;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    return bless {}, shift;
}
sub mock {
    shift;
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
sub reset {
    my $self = shift;
    delete $self->{$_} for keys %{ $self };
}
sub _end {}; # vim placeholder

1;
=head1 NAME

Mock::Sub - The great new Mock::Sub!


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Mock::Sub;

    my $foo = Mock::Sub->new();
    ...


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
