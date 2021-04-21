#! /usr/bin/perl -w
use v5.10.1;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Test::DBIC::SQLite',
    VERSION_FROM  => 'lib/Test/DBIC/SQLite.pm',
    ABSTRACT_FROM => 'lib/Test/DBIC/SQLite.pm',
    AUTHOR        => 'Abe Timmerman <abeltje@cpan.org>',

    PREREQ_PM => {
        'Test::Simple' => 0,
        'DBI'          => 0,
        'DBD::SQLite'  => 0,
    },
    BUILD_REQUIRES => {
        'Test::Warnings'      => 0,
        'Test::Fatal'         => 0,
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
        'Test::Tester'        => 0,
    },

    MIN_PERL_VERSION => '5.010001',
    LICENSE  => 'perl_5',
    META_ADD => {
        'meta-spec' => {version => 2},
        'resources' => {
            homepage   => '',
            repository => {
                type => 'git',
                url  => 'https://github.com/abeltje/Test-DBIC-SQLite.git',
            },
        },
        'x_IRC' => 'irc://irc.perl.org/#amsterdam.pm',
    },
);
