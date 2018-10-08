
use strict;
#use Data::Dumper;

my $cards;
&init;

exit;


### subroutines ###
sub init {
print "\n\n",'how many cards:',"\n";
$cards = <STDIN>;
&check($cards) ? &main($cards) : &init;
}


###very simple check value
sub check($) {
    my $stat = shift || return;
    if ($stat=~/\d+/ and $stat>1) { return 1 }
    else { print 'wrong value, type again'; return 0}; 
}


sub main($) {
my $n = shift;
my @a = ();
my $count = 0;
for ( my $i = 0; $i < $n; ++$i ) {
  $a[$i] = $i+1; 
}

my $array = \@a;
while (1) {
  $array = first( $array );
  ++$count;
  if ( isArr( \@a, $array ) ) {
    last;
  }
}
print $count, " \n";
}

sub isArr {
  my $a1 = shift;
  my $a2 = shift;

  for ( my $i = 0; $i < scalar(@{$a1}); ++$i ) {
    if ( $a1->[$i] != $a2->[$i] ) {
      return 0;
    }
  }
  return 1;
}

sub first {
  my $desk = shift;

  my $desk_size= scalar( @{$desk} );

  my @in_desk = ();
  my @in_table = ();

  if ($desk_size == 0 ) {

    return \@in_table;  
  }
  if ($desk_size == 1 ) {
    @in_table = @{$desk};  

    return \@in_table;  
  }

  if ( ($desk_size % 2) == 0 ) { # even
    
      for ( my $i = 0; $i < $desk_size; ++$i ) {
        if ( ($i % 2) != 0 ) {
          push( @in_table, $desk->[$i] );
        } else {
          push( @in_desk, $desk->[$i] )
        }
      }
      @in_table = reverse(@in_table);
  
  } else {
    
      push( @in_desk, $desk->[$desk_size-1] );
      
      for ( my $i = 0; $i < $desk_size-1; ++$i ) {
        if ( ($i % 2) != 0 ) {
          push( @in_table, $desk->[$i] );
        } else {
          push( @in_desk, $desk->[$i] )
        }
      }
      @in_table = reverse(@in_table);
  }


  my $next_step = first( \@in_desk ) ;
  my @result = ( @{$next_step}, @in_table ); 

  return \@result;
}