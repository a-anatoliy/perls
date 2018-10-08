use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Cinema::Library',
    AUTHOR              => q{Anatolii Apanasiuk <a3three@gmail.com>},
    VERSION_FROM        => 'lib/Cinema/Library.pm',
    ABSTRACT_FROM       => 'lib/Cinema/Library.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Storable'	 => 0,
		'Carp'		 => 0,
		'Cwd'		 => 0,
    },
	EXE_FILES => [ qw(bin/movie_storage.pl bin/sample_movies.txt )],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    #clean               => { FILES => 'Cinema-Library-*' },
    clean               => { FILES => clean_files() },
);

sub clean_files {
	return join(" ", "*.out", "movie.db", "*.tar.gz");
}
