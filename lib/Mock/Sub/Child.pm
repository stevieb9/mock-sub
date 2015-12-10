package Mock::Sub::Child;
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
    my $self = shift;
    my $sub = $self->{name} || shift;

    my %p = @_;
    for (keys %p){
        $self->{$_} = $p{$_};
    }

    $sub = "main::$sub" if $sub !~ /::/;

    my $fake;

    if (! exists &$sub){
        $fake = 1;
        warn "\n\nWARNING!: we've mocked a non-existent subroutine. " .
             "the specified sub does not exist.\n\n";
    }

    $self->_check_side_effect($self->{side_effect});

    if (defined $self->{return_value}){
        push @{ $self->{return} }, $self->{return_value};
    }

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
    $self->{state} = 1;

    return $self;
}
sub unmock {
    my $self = shift;
    my $sub = $self->{name};

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

    $self->{state} = 0;
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
sub DESTROY {
    $_[0]->unmock;
}
sub _end {}; # vim fold placeholder

1;

