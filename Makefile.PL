#! /usr/bin/perl -w
use v5.10.1;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Test::DBIC::SQLite',
    VERSION_FROM  => 'lib/Test/DBIC/SQLite.pm',
    ABSTRACT_FROM => 'lib/Test/DBIC/SQLite.pm',

    PREREQ_PM => {
        'Test::Simple' => 0,
        'DBI'          => 0,
        'DBD::SQLite'  => 0,
    },
    BUILD_REQUIRES => {
        'Test::Tester' => 0,
    },

    LICENSE  => 'perl_5',
    META_ADD => {
        'meta-spec' => {version => 2},
        'resources' => {
            homepage   => '',
            repository => {
                type => 'git',
                url  => 'http://source.test-smoke.org/git/',
            },
        },
        'x_IRC' => 'irc://irc.perl.org/#amsterdam.pm',
    },
);
