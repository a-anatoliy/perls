#!/usr/bin/perl -T
# $Date: 2011-09-24 15:48:10 $
# $Revision: 1.2 $

use Test::More tests => 1;

BEGIN {
    use_ok( 'Cinema::Library' ) || print "Bail out!";
}

diag( "Testing Cinema::Library $Cinema::Library::VERSION, Perl $], $^X" );
