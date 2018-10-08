#!/usr/bin/perl

use MIME::Lite;

my $sprava = 'OPL/2015/043472';

$msg = MIME::Lite->new(
From    =>'"Anatolii Apanasiuk" <a3three@gmail.com>',
# To      =>'aapanasiuk@luxoft.com',
# Cc      =>'a3three@gmail.com',
 To => 'oplaty@ufg.pl',
 Cc => 'oi@ufg.pl, ufg@ufg.pl, aapanasiuk@luxoft.com',

Subject =>'Numer sprawy: ' . $sprava,
Type    =>'multipart/related'
    );
$msg->attach(
        Type => 'text/html',
        Data => qq{
            <body>
            <div align="center">UBEZPIECZENIOWY<br>FUNDUSZ<br>GWARANCYJNY</div><br>
            <div><b>Imię i nazwisko:</b> Anatolii Apanasiuk.</div>
            <div><b>          Temat:</b> Kara za brak OC.</div>
            <div><b>   Numer sprawy:</b> $sprava </div>
            
            <p>Proszę dodać do sprawy $sprava mojego ubezpieczenia, z postawionym czasem zawarcia umowy 
            (dodanym firmą ubezpieczeniową w Ukrainie po mojej interpelacji ).
            <div>Dla zwrotu splaconego przeze mnie mandatu.</div></p>
            <div align="right">First time this email was sent on: 21/07/2015. no response...</div>
            <img src="cid:ensurance.jpg">
            </body>
        },
    );
$msg->attach(
        Type => 'image/jpg',
        Id   => 'ensurance.jpg',
        Path => '/home/anatolii/perl_scripts/data/AApanasiuk_ensurance.jpg',
    );
    $msg->send();


__END__
use MIME::Lite;
 
my $msg = MIME::Lite->new(
From    =>'robot@smt.com',
To      =>'aapanasiuk@luxoft.com',
Subject => 'Тема письма',
Type    => 'multipart/mixed' ) or die "cannot creat mime object";
 
$msg->attach( Type => 'text/html; charset=windows-1251',
              Data => "<body>\n<h1>Текст письма</h1>\n<br /><br />\n
              Наша картинка:<br /><img src=\"cid:slep.jpg\"/>\n</body>\n" ) or die "cannot attach 1";
 
$msg->attach( Type => 'text/plain; charset=windows-1251',
              Data => "Текст письма. Картинка прилагается.\n" ) or die "cannot attach 2";
 
$msg->attach( Type        => 'image/jpg',
              Path        => '/home/anatolii/perl_scripts/data/slep1.jpg',
              Filename    => '/home/anatolii/perl_scripts/data/slep.jpg',
              Id          => '/home/anatolii/perl_scripts/data/slep.jpg',
              Disposition => 'attachment' ) or die "cannot attach 3";
 
$msg->attach( Type        => 'application/x-zip-compressed',
              Path        => '/home/anatolii/perl_scripts/data/code.zip',
              Filename    => '/home/anatolii/perl_scripts/data/code.zip',
              Disposition => 'attachment' ) or die "cannot attach 4";
 
$msg->send();