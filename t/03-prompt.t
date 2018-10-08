#!/usr/bin/perl -T
# $Date: 2011-09-28 22:52:46 $
# $Revision: 1.2 $

use Data::Dumper;
use Test::More tests => 3;

BEGIN { use_ok('Cinema::Prompt') || print "Bail out!"; }

## get Cinema::Library object
my $prompt = Cinema::Prompt->new();
isa_ok( $prompt, 'Cinema::Prompt' );
can_ok( $prompt, qw(print_data menu) );

