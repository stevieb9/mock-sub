#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 13;

BEGIN {
    use_ok( 'Mock::Sub' ) || print "Bail out!\n";
}

diag( "Testing Mock::Sub $Mock::Sub::VERSION, Perl $], $^X" );

can_ok('Mock::Sub', 'new');
can_ok('Mock::Sub', 'mock');
can_ok('Mock::Sub', 'unmock');
can_ok('Mock::Sub', 'called');
can_ok('Mock::Sub', 'called_count');
can_ok('Mock::Sub', 'called_with');
can_ok('Mock::Sub', 'name');
can_ok('Mock::Sub', 'reset');
can_ok('Mock::Sub', 'return_value');
can_ok('Mock::Sub', 'side_effect');
can_ok('Mock::Sub', '_check_side_effect');
can_ok('Mock::Sub', 'DESTROY');

