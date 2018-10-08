package Cinema::Prompt;
use strict;
use warnings;
use Cinema::Utils qw( :all );
use Data::Dumper;

=head1 NAME

Cinema::Prompt - implementation of a view class to provide a user interface

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This module performs processing of user's input and output.

Perhaps a little code snippet.

    use Cinema::Prompt;

    my $foo = Cinema::Prompt->new();
    ...


=head1 SUBROUTINES/METHODS

=over 12

=item C<new>

Returns a new Cinema::Prompt object.

=back

=cut

sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my $self = {};
    bless $self, $class;
    return $self;

}

=over 12

=item C<menu>

menu - builds an interactive menu

=back

=cut

sub menu {
    my $self    = shift;
    my $ctrl    = shift;
    my @choices = qw(a d p n t s y q);
    my $input;
  INPUT:
    &show_input_menu;
    $input = <STDIN>;
    unless ( grep { $input =~ m/$_/i } @choices ) {
        say("ERROR: invalid menu option!");
        goto INPUT;
    }
    chomp($input);
    for ($input) {
        my $result;
        m/^a$/i && do { $result = $ctrl->dispatch( 'add', &get_args ); };
        m/^d$/i && do { $result = $ctrl->dispatch( 'delete', get_arg('movie ID') ); };
        m/^p$/i && do { $result = $ctrl->dispatch( 'display', get_arg('movie ID') );  print Dumper($result); };
        m/^n$/i && do { $result = $ctrl->dispatch( 'find_by_title', get_arg('searching string for title') ); };
        m/^s$/i && do { $result = $ctrl->dispatch( 'find_by_star', get_arg('searching string for movie stars') ); };
        m/^t$/i && do { $result = $ctrl->dispatch( 'get_list_by', 'title' ); };
        m/^y$/i && do { $result = $ctrl->dispatch( 'get_list_by', 'release_year' ); };
        m/^q$/i && do { last; };
        
        $self->print_data($result);
    }
    goto INPUT unless ( $input =~ /^q$/i );

    return 1;
}

=over 12

=item C<show_input_menu>

=back

=cut

sub show_input_menu {
    print "
---------------------------------
 *** Movie DB user interface ***
---------------------------------
Select one of:
a - Add new movie's record
d - Delete movie's record
p - Show movie properties
t - List movies by title
y - List movies by year
n - Find movie by name
s - Find movie by star
q - Exit
---------------------------------
Your choice: ?\b";

}

=over 12

=item C<get_arg>

get_arg - gets an argument

=back

=cut

sub get_arg {
    my $arg = shift;
    print "Input $arg: ";
    chomp( my $input = <STDIN> );
    return $input;
}

=over 12

=item C<get_args>

get_args - gets several arguments

=back

=cut

sub get_args {
    my $args = {
        title        => undef,
        release_year => 0,
        format       => undef,
        stars        => [],
    };
    ## will check: format, release_year
    my @formats     = qw(DVD VHS Blue-Ray);
    my $year_regexp = qr/\d{4}/;

    foreach my $k ( keys %$args ) {
        my $error = 0;
        my $input;

        do {
            my $tmp_key = ucfirst($k);
            $tmp_key =~ tr/_/ /;

            if ( $k eq 'stars' ) {
                print "Please, specify $tmp_key (if several, divide each name by comma): ";
            }
            else {
                print "Please, specify $tmp_key: ";
            }

            chomp( $input = <STDIN> );

            ## check if the data is correct
            my $append = undef;
            if ( $k eq 'format' && !grep { m/$input/ } @formats ) {
                $error  = 1;
                $append = "@formats";
            }
            elsif ( $k eq 'release_year' && $input !~ /$year_regexp/ ) {
                $error  = 1;
                $append = "YYYY";
            }
            else { $error = 0; }
            print "Invalid input! Should be as: $append\n"
              if ( defined $append );

        } while ($error);

        if ( $k eq 'stars' ) {
            push @{ $args->{$k} }, map { trim($_) } split /,/, $input;
        }
        else {
            $args->{$k} = $input;
        }
    }

    return $args;
}

=over 12

=item C<print_data>

=back

=cut

sub print_data {
    my $self = shift;
    my $data = shift;

    say( '=' x 70 );
    if ( UNIVERSAL::isa( $data, 'Cinema::Library' ) ) {
        say $data;
    }
    elsif ( ref($data) eq 'ARRAY' ) {
        say dumper('WE HAVE an ARRAY! - > '.$data);
    }
    else {
        say dumper($data);
    }
    say( '=' x 70 );
}

=head1 AUTHOR

Anatolii A. Apanasiuk, C<< <a3three at gmail dot com> >>

=head1 BUGS

Please report any bugs or feature requests to C<a3three at gmail dot com>.  


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cinema::Prompt



=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Anatolii A. Apanasiuk.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Cinema::Prompt
