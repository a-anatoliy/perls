#!/usr/bin/perl 
use strict; use warnings;
use lib qw(../lib);
use Cinema::Library;
use Cinema::Utils qw( :all );
use Data::Dumper;
use Getopt::Long;

######################## &usage if ( scalar(@ARGV) == 0 );

## get command line options
my ( $import, $delete, $prop, $by_title, $by_year, $find_by_name, $find_by_star, $menu, $add, $fs );

GetOptions(
    'import=s'        => \$import,
    'delete=s'        => \$delete,
    'property=i'      => \$prop,
    'title-list'      => \$by_title,
    'year-list'       => \$by_year,
    'find-by-name=s'  => \$find_by_name,
    'find-by-star=s'  => \$find_by_star,
    'menu'            => \$menu,
    'add=s'           => \$add,
    'file_format=s'   => \$fs,
    'help!'           => \&usage,
) or &usage;


## create Cinema::Library object
my $obj = Cinema::Library->new($fs);
# $obj->{logger}->info(Dumper($obj));
# print Dumper($obj);

# exit;

say( '*' x 80 );
## process command line arguments
SWITCH: {
    defined $import && do {
        say('Doing import...');
        say('Data saved.') if $obj->dispatch('import', $import);
    };
    defined $add && do {
        say('Doing adding...');
        say( '*' x 80 );
        my $add_hash = check_add_arg($add);
        say $obj->dispatch('add', $add_hash);
    };
    defined $delete && do {
        say('Doing deleting...');
        say( '*' x 80 );
        say $obj->dispatch('delete', $delete);
    };
    defined $prop && do {
        say("Displaying movie's properties...");
        say( '*' x 80 );
        say $obj->dispatch('display', $prop);
    };
    defined $by_title && do {
        say('List movies by title...');
        say( '*' x 80 );
        say dumper( $obj->dispatch('get_list_by', 'title' ));
    };
    defined $by_year && do {
        say('List movies by year...');
        say( '*' x 80 );
        say dumper( $obj->dispatch('get_list_by', 'release_year' ));
    };
    defined $find_by_name && do {
        say('Search movies by titles...');
        say( '*' x 80 );
        say dumper( $obj->dispatch('find_by_title', $find_by_name ));
    };
    defined $find_by_star && do {
        say('Search movies by stars...');
        say( '*' x 80 );
        say dumper( $obj->dispatch('find_by_star', $find_by_star ));
    };
    defined $menu && do {
        say('Using interactive menu mode...');
        $obj->dispatch('menu');
    };
}

## ---------------------------------------------------------
## check_add_arg - subroutine to an argument for add action
## ---------------------------------------------------------
sub check_add_arg {
    my $arg = shift;
    my $hash_arg = {};

    ## try to split the string
    %$hash_arg = split /[;=]/, $arg;

    my @keys    = qw(release_year title format stars);
    my @formats = qw(VHS DVD Blue-Ray);
    my $error   = 0;

    ## exactly must be 4 keys
    usage("Invalid quantity of the keys. The keys are: @keys") if (scalar(keys %$hash_arg) != 4);

    foreach my $k (keys %$hash_arg) {
        ## check each key
        unless ( grep { $k eq $_ } @keys ) {
            $error = 1;
        }
        ## check each value
        else {
            $error = 1 if ( $k eq 'release_year' && $hash_arg->{$k} !~ m/\d{4}/ );
            $error = 1 if ( $k eq 'format' && ! grep { $hash_arg->{$k} eq $_ } @formats );
            $error = 1 if ( $k eq 'title' && ! defined($hash_arg->{$k}) );
            $error = 1 if ( $k eq 'stars' && ! defined($hash_arg->{$k}) );
        }
    }
    
    usage("Can't add a new movie - invalid key or value in the argument.") if $error;

    ## keys and values are fine, process 'stars'
    my $star_str = $hash_arg->{'stars'};
    $hash_arg->{'stars'} = [ split /,/, $star_str ];

    return $hash_arg;
}


## -----------------------------------------------------
## usage - subroutine to print usage message + an error
## -----------------------------------------------------
sub usage {
    if (@_) {
        say("ERROR: @_") unless ($_[0] eq 'help');
        say('-' x 80);
    }
    print <<"USAGE";
Usage: $0 --import <file.txt> [-i, -d, -a, -s, -t, -y, --find-by-title, --find-by-star, -m]
        -i, --import        import movies from a data source txt file
        -a, --add           add a movie's record. The argument string should looks like: 
                            $0 --add 'release_year=YYYY;title=The movie;format=DVD;stars=John Doe,Jack Sharper' 
                            NOTE: the argument string should be quoted!
        -d, --delete        delete a movie (it will ask movie ID)
        -p, --property      show properties of a movie (it will ask movie ID)
        -t  --title-list    show list title and IDs of all movies, alphabetically 
        -y, --year-list     show list title and IDs of all movies, chronologically
            --find-by-name  find movies by name (it will ask for a search string)
            --find-by-star  find movies by star (it will ask for a star name)
        -m, --menu          script will prompt an interactive menu to add a new record, etc

            --help  display this help and exit 

USAGE
    exit(0);
}

__END__
