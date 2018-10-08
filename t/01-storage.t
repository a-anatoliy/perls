#!/usr/bin/perl
# $Date: 2011-09-28 22:52:46 $
# $Revision: 1.6 $

use Data::Dumper;
#use Test::More tests => 10;
use Test::More no_plan;

my @methods = qw(cache do_add do_delete cache dbh);
my $txt_db = 'blib/script/sample_movies.txt';

BEGIN { use_ok('Cinema::Storage') || print "Bail out!"; }
## need to be loaded to get the access to Cinema::Library methods
BEGIN { use_ok('Cinema::Library') || print "Bail out!"; }

## get Cinema::Storage object
my $obj1 = Cinema::Storage->new();
isa_ok( $obj1, 'Cinema::Storage' );

#diag( "Testing creating of Cinema::Storage object" );
can_ok( $obj1, @methods );
ok($obj1->do_import($txt_db) == 1 , 'Importing data from text db');
ok($obj1->get_new_id =~ /\d+/, 'Getting new record ID');
ok(ref($obj1->get_ids_objs) eq 'ARRAY', 'Got list of IDs and objects');
isa_ok($obj1->select_by_id(1), 'Cinema::Library');
ok(ref($obj1->select_by_star('will')) eq 'ARRAY', 'Got list of IDs, titles, movie stars');
ok(ref($obj1->select_by_title('the')) eq 'ARRAY', 'Got list of IDs and titles');
ok(ref($obj1->select_all_by('format')) eq 'ARRAY', 'Got list of IDs, titles, formats');
ok($obj1->store);
ok($obj1->retrieve);
#diag( "Testing accessing of the methods (@methods)" );

