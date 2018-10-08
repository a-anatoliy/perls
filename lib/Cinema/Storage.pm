package Cinema::Storage;
use strict; use warnings;

use Carp;
use Storable qw(lock_store lock_retrieve freeze thaw);
use XML::Simple;
use IO::File;
use JSON::XS;
use XML::LibXML;

use File::Copy;
use Cwd;
use Cinema::Utils qw( :all );
use base qw ( Cinema::Library );
use Data::Dumper;

our (@ISA, @EXPORT);

BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    @EXPORT = qw( storage_init getDBfileName checkDBfile do_import doRenameFiles generateDBfile
        generateJSON generateXML generateTXT checkStorable retrieve select_all_by select_by_id
        );  # symbols to export on request

}

use constant { 
    DBFILE => 'movie',
    INIT_DBFILE => 'sample_movies.txt',
 };

our $VERSION = '0.02';

sub checkStorable {
    my $self = shift;
    eval{lock_retrieve($self->{'db_files'}{'txt'}) };
    return (scalar $@) ? 0 : 1;
}

sub storage_init {
    my $self   = shift;
# we need a full qualified path to current data file that used for importing
    $self->defSRCfile(sprintf('%s/%s',$self->{'work_path'},$self->defSRCfile)),
    $self->getDBfileName();
return $self;
}

sub checkDBfile {
    my $self = shift;
    foreach (@{$self->{'availableDBformats'}}) {
        my $p = sprintf('%s/%s.%s',$self->{'work_path'},$self->dbfile,$_);
        if (-r $p) { $self->{'db_files'}{$_}=$p }
    }
    
    unless ($self->checkStorable) { $self->generateTXT; }

    if ( ! scalar keys %{$self->{'db_files'}} 
        || scalar keys %{$self->{'db_files'}} < scalar(@{$self->{'availableDBformats'}})
       ) {
            map {
                # $self->do_import(undef,$_) unless (exists $self->{'db_files'}{$_});
                $self->generateDBfile($_) unless (exists $self->{'db_files'}{$_});
                
            } @{$self->{'availableDBformats'}};
    }
return $self;
}

sub getDBfileName {
    my $self = shift;
    my $dbfile = getcwd . '/' . $self->dbfile;
       $dbfile.='.'.$self->file_format;
    $self->{logger}->info("using DB: $dbfile") if $self->global_debug;
    $self->checkDBfile();
    $self->dbh($dbfile);
    $self->cache($self->retrieve());

return 1;
}

sub cache : lvalue {
    my $self = shift;
    $self->{'cache'};
}

sub dbh {
    my $self = shift;
    $self->{'dbh'};
}

sub do_add {
    my $self = shift;
    my $data = shift;
    my $id = $self->get_new_id;
    $self->{'cache'}->{$id} = $data;
    ## store data into the file
    $self->store;
    return "Record has been added under ID $id.";
}

sub do_delete {
    my $self = shift;
    my $id   = shift;

    if ( exists( $self->{'cache'}->{$id} ) ) {
        delete( $self->{'cache'}->{$id} );
        $self->store;
        return "Record ID $id has been deleted.";
    }
    else {
        return "Can't delete a record. Invalid ID or record does not exist.";
    }

}

sub select_by_id {
    my $self = shift;
    my $id   = shift;
$self->{logger}->debug(__PACKAGE__. " search id: $id");

    if ($self->cache and ref($self->cache) eq 'ARRAY') {
        foreach my $h (@{$self->cache}) {
            if ($h->{'id'} == $id) {
             $self->{logger}->debug(__PACKAGE__. Dumper($h));
            return $h;
            }
        }
    }
}

sub select_by_star {
    my $self     = shift;
    my $substr   = shift;
    my $ids_objs = $self->get_ids_objs;
    my $res      = [];

    foreach my $r ( @{$ids_objs} ) {
        foreach my $star ( @{ $r->{'obj'}->stars } ) {
            if ( $star =~ /\b$substr/i ) {
                push @$res,
                  {
                    id    => $r->{'id'},
                    star  => $star,
                    title => $r->{'obj'}->title
                  };
            }
        }
    }

    return $res;
}

sub select_by_title {
    my $self     = shift;
    my $substr   = shift;
    my $ids_objs = $self->get_ids_objs;
    my $res      = [];

    foreach my $r ( @{$ids_objs} ) {
        if ( $r->{'obj'}->title =~ /$substr/i ) {
            push @$res, { id => $r->{'id'}, title => $r->{'obj'}->title };
        }
    }

    return $res;
}

sub select_all_by {
    my $self = shift;
    my $attr = shift;
    my $res  = [];

    ## -----------------------------------------------------------------------------
    ## Generic sorting subroutine:
    ## it analyzes an attribute (numeric or string), after that sorts by <=> or cmp
    ## -----------------------------------------------------------------------------
    my $by_attr = sub {
        ( $a->{'obj'}->$attr() =~ /^\d+$/ && $b->{'obj'}->$attr() =~ /^\d+$/ )
          ? $a->{'obj'}->$attr() <=> $b->{'obj'}->$attr()
          : uc( $a->{'obj'}->$attr() ) cmp uc( $b->{'obj'}->$attr() );
    };

    my $ids_objs = $self->get_ids_objs;

    foreach my $r ( sort { $by_attr->() } @{$ids_objs} ) {
        if ( $attr eq 'title' ) {
            push @$res, { title => $r->{'obj'}->title, id => $r->{'id'} };
        } else {
            push @$res,
              {
                title => $r->{'obj'}->title,
                id    => $r->{'id'},
                $attr => $r->{'obj'}->$attr()
              };
        }
    }
    return $res;
}

sub store {
    my $self = shift;
    lock_store $self->cache, $self->dbh;
}

sub retrieve {
    my $self = shift;
    return lock_retrieve( $self->{'db_files'}{'txt'} );
}

sub doRenameFiles {
# yeah, I know about File::Find
# but people need recursion
my $self = shift;
my $file = shift || return 1;

    if ( -r $self->{'db_files'}{$file} ) {
        File::Copy::move($self->{'db_files'}{$file}, $self->{'db_files'}{$file}.'.old');
    }
$self->doRenameFiles(@_);
$self->{'db_files'} = {};
return 1;
}

sub do_import {
    my $self    = shift;
    my $newFile = shift;
#
# in case if this variable is defined
# it's means that we need to rewrite all of currently working files
#
    if ( $newFile and ! -e $newFile) {
        croak "ERROR: file $newFile does not exist or it isn't an ASCII text file.";
        unless ( -e $self->defSRCfile ) {
            croak "ERROR: initial file ".$self->defSRCfile." does not exist or it isn't an ASCII text file.";
            return 1;
        }
    } else {
=comment
 ok. we have a request to update/import our db.
 so we need to check existance of previous version of db files
 and just to be on a safe side make backup all of these files.
=cut
        $self->defSRCfile($newFile);

        if (scalar keys %{$self->{'db_files'}}) {
            $self->doRenameFiles(keys %{$self->{'db_files'}});
        } else {
            #there is no files (first run?) nothing to do
        }
        
    my $cal_script = ''; $cal_script = (caller())[1]; # $cal_script =~ s/.+[\/\\]//;
    my $log_line = $cal_script.'::'.(caller(1))[3].'('.(caller())[2].')::'.__PACKAGE__.':: ' ;
    #              Cinema::StorageLibrary.pm::Cinema::Library::__ANON__(138)::Cinema::Storage::
    $self->{logger}->debug(__PACKAGE__.$log_line );
        
    $self->checkDBfile();        
    }
    
    return 1;

}

sub generateDBfile {
    my $self = shift;
    my $file_format = shift;
    unless ($file_format) { croak "ERROR: destination file format unknown."; }
    my $cal_script = ''; $cal_script = (caller())[1]; $cal_script =~ s/.+[\/\\]//;
    my $log_line = $cal_script.'::'.(caller(1))[3].'('.(caller())[2].')::'.__PACKAGE__.':: ' ;
    $self->{logger}->debug(__PACKAGE__.$log_line. 'Request for generating: ['.$file_format.']');
    
    # @methods = qw(name rank serno);
    # %his_info = map { $_ => $ob->$_() } @methods;
    
    my $actions; 
    eval($actions = { map { $_ => 'generate'.uc($_) } @{$self->{'availableDBformats'}} });
    my $methName = $actions->{$file_format};
       $self->$methName();
return 1;

}

sub generateJSON {
    my $self = shift;
    $self->{'logger'}->info('Generate JSON data file start!') if $self->global_debug;
    my $fname = sprintf('%s/%s.%s',$self->{work_path},$self->dbfile,'json');
    my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
        my $fh = IO::File->new("> $fname");
        if (defined $fh) {
            print $fh $coder->encode($self->retrieve());
            $fh->close;
        } else {
            my $errMsg = qq~ERROR: Couldn't open [$fname] for writing. $!~;
            $self->{'logger'}->info($errMsg);            
            croak $errMsg;
        }
return 1;
}

sub generateXML {
    my $self = shift;
    $self->{'logger'}->info('Generate XML data file start!') if $self->global_debug;

    my $doc = XML::LibXML->createDocument( "1.0", "UTF-8" );
    my $root = $doc->createElement("movie");

    foreach my $h (@{$self->retrieve()}) {
        my $movie = $doc->createElement( 'item' );
            while (my ($name,$value) = each(%{$h})) {
                my $movie_data = $doc->createElement( $name );

                if ($value and ref($value) eq 'ARRAY') {
                    foreach (@{$value}) {
                        my $star = $doc->createElement( 'name' );
                        $star->appendTextNode($_);
                        $movie_data->appendChild( $star );
                    }
                } else { $movie_data->appendTextNode($value); }
                
            $movie->appendChild( $movie_data );
            }
        $root->appendChild($movie);
    }

    $doc->setDocumentElement($root);

    $doc->serialize( 1 );
    $doc->toFile( sprintf('%s/%s.%s',$self->{work_path},$self->dbfile,'xml'), 1 );

    # print $doc->toString();
return 1;
}

sub generateTXT {
    my $self = shift;
    my $data;
    $self->{'logger'}->info('Generate Storable data file start!') if $self->global_debug;

    open( my $fh, '<', $self->defSRCfile ) or croak "ERROR: $!";
    my @tmp = grep { $_ !~ /^$/ } <$fh>;
    close $fh;
    chomp(@tmp);

    my $id = 1;
    while (@tmp) {
        my ( $t_key, $title, @rest ) = split /:/, shift @tmp;
        my ( $y_key, $year )   = split /:/, shift @tmp;
        my ( $f_key, $format ) = split /:/, shift @tmp;
        my ( $s_key, $stars )  = split /:/, shift @tmp;

        # :WORKAROUND:24.09.2011:: to process title like '2001: A Space Odyssey'
        $title .= ':' . shift(@rest) if (@rest);
        $title .= join( ': ', @rest ) if ( scalar(@rest) );

        ## compose the data, make all keys lovercase and s/ /_/, remove leading space
        ## every movie's record will saved as the Cinema::Library object
        push @{$data}, { 'id' => $id,
                rename_key($t_key) => trim($title),
                rename_key($y_key) => trim($year),
                rename_key($f_key) => trim($format),
                rename_key($s_key) => [ map { ltrim($_) } split /,/, $stars ],
            };
        ++$id;
    }

    my $p = sprintf('%s/%s.%s',$self->{work_path},$self->dbfile,'txt');
    ## serialize the data using Storable method (with locking)
    if (lock_store $data, $p) {
        $self->{db_files}{txt} = $p
    } else {
            my $errMsg = "Can't serialize the data: $!";
            $self->{'logger'}->info($errMsg);            
            croak $errMsg;
    }
    ## put the data into the cache
return 1;
}

sub get_new_id {
    my $self = shift;
    my $max  = undef;
    map { $max = $_ if ( !$max || $_ > $max ) } keys %{ $self->{'cache'} };
    ++$max;
    return $max;
}

sub get_ids_objs {
    my $self   = shift;
    my $couple = [];

    while ( my ( $id, $obj ) = each %{ $self->{'cache'} } ) {
        push @$couple, { id => $id, obj => $obj };
    }
    return $couple;
}

sub rename_key {
    my $key = shift;
    $key =~ s/\s/_/;
    return lc $key;
}

sub do_XMLsave {
    my $data = shift;
    my $fname = getcwd . '/' . DBFILE;
       $fname =~ s!db$!xml!;

# file allready exists - nothing to do
    return 1 if (-r $fname);
       
    my $fh = IO::File->new("> $fname");
    if (defined $fh) {
        XMLout($data,OutputFile => $fh,XMLDecl=>1,NoSort=>1,KeepRoot=>1);
        $fh->close;
    } else { croak "Couldn't open [$fname] for writing: $!"; }
return 1;
}

sub getXMLfile {
my $parser = new XML::LibXML;
my $doc    = $parser->parse_file('my_test.xml');
my $root   = $doc->getDocumentElement;
my $out;
    foreach my $node ($root->findnodes('item')) {
    my $h = {};
        if ($node->hasChildNodes()) {
        my @child = $node->childNodes();

            foreach my $child(@child) {
                    my $elname = $child->getName();
                    next if $elname =~ m!^#!;
                    my $data = $child->textContent();
                    if ($elname and $data) {
                        chomp($data);
                        if ($elname eq 'stars') {
                            $data = [ map { trim($_) } split("\n",trim($data)) ];
                        }
                        $h->{$elname} = $data;

                    }
            }
        }
    push @{$out}, $h;
    }
 print Dumper($out);
print "\n".'-----------------',"\n";
return $out;
}

sub getJSONfile {
    my $json_xs = JSON::XS->new();
    $json_xs->utf8(1);
    return $json_xs->decode(_readfile('movie.json'));
}

sub _readfile {
    my $fname = shift;
    my $data;
    my $fh = IO::File->new("< $fname");
        if (defined $fh) {
            $data = do { local $/; <$fh> };
            $fh->close;
        } else { print qq~\nCouldn't open [$fname]: $@ $!\n~;}

    return $data;
}




=head1 AUTHOR

Anatolii A. Apanasiuk, C<< <a3three at gmail dot com> >>

=head1 BUGS

Please report any bugs or feature requests to C<a3three at gmail dot com>.  


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cinema::Storage



=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Anatolii A. Apanasiuk.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Cinema::Storage
