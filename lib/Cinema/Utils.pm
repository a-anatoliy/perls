#
#===============================================================================
#
#         FILE:  Utils.pm
#
#  DESCRIPTION:
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Anatolii A. Apanasiuk (), <a3three@gmail.com>
#      COMPANY:
#      VERSION:  0.20
#      CREATED:  25.09.2011 12:21:48 EEST
#  CHANGE DATE:  $Date: 2011-09-28 08:08:19 $
#     REVISION:  $Revision: 1.6 $
#===============================================================================
package Cinema::Utils;
use strict;
use warnings;
use Exporter;

our $VERSION     = 0.02;
our @ISA         = qw(Exporter);
our @EXPORT      = qw( ltrim rtrim trim dumper say );
our %EXPORT_TAGS = ( all => [@EXPORT], );

=over 12

=item C<ltrim>

=back

=cut

sub ltrim {
    my $str = shift;
    $str =~ s/^\s//;
    return $str;
}

=over 12

=item C<rtrim>

=back

=cut

sub rtrim {
    my $str = shift;
    $str =~ s/\s+$//;
    return $str;
}

=over 12

=item C<trim>

=back

=cut

sub trim {
    my $str = shift;
    $str =~ s/^\s//;
    $str =~ s/\s+$//;
    return $str;
}

=over 12

=item C<dumper>

dumper - subroutine to print out a hash of arrays

=back

=cut

sub dumper {
    my $thing = shift;
    my $res ;
    if (ref($thing) eq 'ARRAY') {
        return "~ Nothing was found." unless (scalar @$thing);
        foreach my $item (@{$thing}) {
            $res .= "-\n";
            while ( my ($k, $v) = each %$item ) {
                $res .= "  $k: $v\n";
            }
        }
    }
    else {
        $res = "$thing\n";
    }
    return $res;
}

=over 12

=item C<say>

say - subroutine to print out a message + "\n"

=back

=cut

sub say {
    my $msg = shift;
    defined $msg ? print "$msg\n" : print "\n";
}

1;
