#!/usr/bin/perl -T
# $Date: 2011-09-28 08:07:16 $
# $Revision: 1.5 $

use Data::Dumper;
use Test::More tests => 11;
my @methods = qw(release_year title stars format);

BEGIN { use_ok('Cinema::Library') || print "Bail out!"; }

## get Cinema::Library object
my $obj1 = Cinema::Library->new();
isa_ok( $obj1, 'Cinema::Library' );

#diag( "Testing creating of Cinema::Library object" );
can_ok( $obj1, @methods );

#diag( "Testing accessing of the methods (@methods)" );

my $obj2 = Cinema::Library->new(
    title        => 'Men in black',
    stars        => [ 'Will Smith', 'Tommy Lee Jones' ],
    release_year => 1997,
    format       => 'DVD',
);
ok( $obj2->title  =~ /.+/, ' Tile is not empty' );
ok( $obj2->release_year  =~ /\d+/, ' Release year is numeric' );
ok( $obj2->format =~ /[A-Z\-]/, ' Format is alphabetical' );
ok( ref($obj2->stars) eq 'ARRAY', ' Stars is a list' );
ok( ref($obj2->dispatch('get_list_by','release_year')) eq 'ARRAY', ' Get list movies by year');
ok( ref($obj2->dispatch('get_list_by','title')) eq 'ARRAY', ' Get list movies by title');
ok( ref($obj2->dispatch('find_by_title','the')) eq 'ARRAY', ' Search movies by title');
ok( ref($obj2->dispatch('find_by_star', 'will')) eq 'ARRAY', ' Search movies by star name');
