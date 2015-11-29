#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mock::Sub' ) || print "Bail out!\n";
}

diag( "Testing Mock::Sub $Mock::Sub::VERSION, Perl $], $^X" );
