#! perl -w
use v5.12.0;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Test::DBIC::SQLite',
    VERSION_FROM  => 'lib/Test/DBIC/SQLite.pm',
    ABSTRACT_FROM => 'lib/Test/DBIC/SQLite.pm',
    AUTHOR        => 'Abe Timmerman <abeltje@cpan.org>',
    LICENSE          => 'perl',

    PREREQ_PM => {
        'Test::Simple'           => 0,
        'DBIx::Class'            => 0,
        'Moo'                    => '2.00',
        'namespace::autoclean'   => '0.16',
        'BDB::SQLite'            => '1.29',    # Test-dep of DBIx::Class
        'MooX::Params::Validate' => '0.04',
        'Types::Standard'        => '1.008',
    },
    BUILD_REQUIRES => {
        'Test::Warnings'      => 0,
        'Test::Fatal'         => 0,
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
        'Test::Tester'        => 0,
        'YAML'                => 0,
    },

    MIN_PERL_VERSION => '5.012000',
    META_ADD         => {
        'meta-spec' => {version => 2},
        'resources' => {
            homepage   => 'https://github.com/abeltje/Test-DBIC-SQLite.git',
            repository => {
                type => 'git',
                url  => 'https://github.com/abeltje/Test-DBIC-SQLite.git',
            },
        },
        'x_IRC' => 'irc://irc.perl.org/#amsterdam.pm',
    },
);
