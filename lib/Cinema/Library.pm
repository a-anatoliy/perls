package Cinema::Library;

use warnings; use strict;
use Carp;
use Cwd;
use Storable qw(lock_store lock_retrieve);
use Cinema::Utils qw( :all );

use Cinema::Prompt;
use Cinema::Storage;
use Data::Dumper;

use Log::Log4perl qw(get_logger);
# use Encode qw(encode decode);
use utf8;

use constant { 
    DBFILE      => 'movie',
    INIT_DBFILE => 'sample_movies.txt',
    LOG_CONFIG  => 'logger.conf',
    DEBUG_ON    => 1,
 };

our ($AUTOLOAD, $VERSION);
 
&Log::Log4perl::init( getcwd . '/' . LOG_CONFIG );

=head1 NAME

Cinema::Library - implementation of a controller class

=head1 VERSION

Version 0.01

=cut

$VERSION = '0.03';

=head1 SYNOPSIS

This module interacts with GUI and Model. 

Perhaps a little code snippet.

    use Cinema::Library;

    my $foo = Cinema::Library->new();
    ...


=head1 SUBROUTINES/METHODS

=over 12

=item C<new>

Returns a new Cinema::Library object.

=back

=cut

sub new {
    my $check = shift;
    my $fs = shift || undef;
    my $class = ref( $check ) || $check;
    my $self = {};
    my @availableDBformats = qw(xml txt json);
    
    unless ( $fs && ( grep { $fs eq $_ } @availableDBformats ) ) { $fs = 'txt'; }
       
    my %fields = (
     'title' => '',
     'release_year' => '',
     'format' => '',
     'stars' => '',
     'storage' => '',
     'file_format' => $fs,
     'global_debug' => DEBUG_ON,
     'dbh' => '',
     'dbfile' => DBFILE,
     'cache' => '',
     'defSRCfile' => INIT_DBFILE,
    );

    $self = bless { __methods => \%fields }, $class;
    $self->{errors} = [];
    $self->{work_path} = getcwd ;
    $self->{'availableDBformats'} = \@availableDBformats;
    
    $self->{logger} = get_logger();
# check existance of any DB files
    # $self->checkDBfile();
# get data from the DB
    $self->storage_init();
# init map for SQL queries
    # $self->{qm} = auth_query_map->new($self->getConfigValue('dbi','tables_prefix'));
# load html templates
    # $self->loadTemplate('header');
    # $self->loadTemplate('base');
    
    # my $cal_script = ''; $cal_script = (caller())[1]; $cal_script =~ s/.+[\/\\]//;
    # my $log_line = $cal_script.'::'.(caller(1))[3].'('.(caller())[2].')::'.__PACKAGE__.':: ' ;
    # $self->{logger}->debug(__PACKAGE__.$log_line. Dumper($self));
    
return $self;
}

sub AUTOLOAD {
    my $self = shift;
    my $cal_script = ''; $cal_script = (caller())[1]; $cal_script =~ s/.+[\/\\]//;
    my $log_line = $cal_script.'::'.(caller(1))[3].'('.(caller())[2].')::'.__PACKAGE__.'::';
    my $method = $AUTOLOAD;
    
    $method =~ s/.*://;

    my $ret;
    die "Cann't access method '$method'. $log_line " unless defined $self->{'__methods'}{$method};

    if (@_) {
        $ret = shift;
        $self->{'__methods'}{$method} = $ret if defined $ret;
    } else {
        $ret = $self->{'__methods'}{$method};
    }

return $ret;
}

sub DESTROY { }

sub dispatch {
    my $self = shift;
    my $action = shift;
    my $arg  = shift;

    my $actions = {
        'add'            => sub { $self->do_add(bless($arg)) if keys %$arg; },
        'delete'         => sub { $self->do_delete($arg) if $arg =~ /\d+/; },
        'display'        => sub { $self->select_by_id($arg) if $arg =~ /\d+/; },
        'get_list_by'    => sub { $self->select_all_by($arg) if $arg; },
        'find_by_title'  => sub { $self->select_by_title($arg) if $arg; },
        'find_by_star'   => sub { $self->select_by_star($arg) if $arg; },
        'import'         => sub { $self->do_import($arg) if $arg; },
        'menu'           => sub { Cinema::Prompt->new->menu($self); },        
    };

    return $actions->{$action}->($arg);
}

=head1 AUTHOR

Anatolii A. Apanasiuk, C<< <a3three at gmail dot com> >>

=head1 BUGS

Please report any bugs or feature requests to C<a3three at gmail dot com>.  


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cinema::Library



=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Anatolii A. Apanasiuk.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Cinema::Library
