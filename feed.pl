#!/usr/bin/perl

use strict; use warnings;
use Data::Dumper;
use utf8; use feature qw(say);
use File::Open qw(fopen);


my $file_in = 'feed_file.txt';
# my $file_in = 'feed_file_short.txt';
my $file_out = 'feed_file_compressed.txt';

my $fh_in  = fopen $file_in,  'r';
my $fh_out = fopen $file_out, 'w';

my %count;
my %unsubst=();
my %subst = (
   108, 'a', 109, 'b', 107,'c1',
  'PFD' , 'd', 'SEBS', 'e', 'KZ'  , 'f', 'FXDC', 'j',
  'FXCM', 'h', 'FFS' , 'i', 'DUBA', 'g', 'FXDD', 'k',
  'GAIN', 'l', 'SBD' , 'm', 'PEP' , 'n', 'TDFX', 'o',
);
map { $unsubst { $subst{$_}  } = $_ } keys %subst;

while (defined(my $line = $fh_in->getline)) {
	chomp($line);
	my ($h,$sec,$one,$two,$three,$let) = split(' ', $line);
	map { $_ = sprintf("%.3f",$_) } ($one,$two,$three);
	for my $v ($one,$two,$three) {
		map { $v =~ s/$_/$subst{$_}/ } keys %subst;
	};
	my $str = sprintf('%s %s %s %s',$one,$two,$three,($subst{$let} || $let));
 	$fh_out->print($str,"\n") or die "$0: $file_out: $!\n";
}
 
$fh_out->close or die "$0: $file_out: $!\n";
$fh_in->close;

say 'done';

my ($hh,$mm,$ss)=(0,0,0);
my $decompr = 'feed_file_DE-compressed.txt';

   $fh_in  = fopen $file_out, 'r';
my $fh_dec = fopen $decompr,  'w';

while (defined(my $line = $fh_in->getline)) {
		chomp($line);
	my ($one,$two,$three,$let) = split(' ', $line);
	for my $v ($one,$two,$three) {
		# say $v;
		map { $v =~ s/$_/$unsubst{$_}/ } keys %unsubst;
	};
	my $str = sprintf('%02d:%02d:%02d %02d:%02d %s %s %s %s',$hh,$mm,$ss,$hh,$mm,$one,$two,$three,$unsubst{$let});
	$ss++;
	if ($ss == 60) { $mm++; $ss=0 };
	if ($mm == 60) { $hh++; $mm=0 };
	$fh_dec->print($str,"\n") or die "$0: $file_out: $!\n";
}
$fh_dec->close or die "$0: $file_out: $!\n";
$fh_in->close;


exit;



# 00:00:01 00:00
# 00:00:02 00:00
# 00:00:03 00:00
# 00:00:04 00:00
# 00:00:05 00:00
# -----------------
# 00:00:59 00:00
# 00:01:00 00:01
# 00:01:01 00:01
# -----------------
# 23:59:58 23:59
# 23:59:59 23:59