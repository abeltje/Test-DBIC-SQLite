#! perl -I. -w
use utf8;
use Test::Tester;
use t::Test::abeltje;

use Test::DBIC::SQLite;

{
    check_test(
        sub {
            my $schema = connect_dbic_sqlite_ok('DummySchema');
        },
        {
            ok   => 1,
            name => 'the schema ISA DummySchema',
        },
        "connect_dbic_sqlite_ok()"
    );
}

{
    my $dbname = $0;
    my $schema;
    check_test(
        sub {
            $schema = connect_dbic_sqlite_ok(
                'DummySchema', $dbname
            );
        },
        {
            ok => 1,
            name => "the schema ISA DummySchema",
        },
        "connect_dbic_sqlite_ok($dbname)"
    );
    is($schema->[0], "dbi:SQLite:dbname=$dbname", "$dbname");
}
{
    my $dbname = "WillNotEverExistInThis.distro";
    my $schema;
    check_test(
        sub {
            $schema = connect_dbic_sqlite_ok(
                'DummySchema', $dbname
            );
        },
        {
            ok => 1,
            name => "the schema ISA DummySchema",
        },
        "connect_dbic_sqlite_ok($dbname)"
    );
    is($schema->[0], "dbi:SQLite:dbname=$dbname", "$dbname");
}

{
    my ($premature, @results) = run_tests(
        sub {
            my $schema = connect_dbic_sqlite_ok('DummyNocompile');
        }
    );
    like(
        $premature,
        qr{Error\ loading\ 'DummyNocompile':
          \ DummyNocompile.pm\ did\ not\ return\ a\ true\ value}x,
        "require DummyNoCompile; fails"
    );
}

{
    my ($premature, @results) = run_tests(
        sub {
            my $schema = connect_dbic_sqlite_ok('DummyNoconnect');
        }
    );
    like(
        $premature,
        qr{Error connecting 'DummyNoconnect' to 'dbi:SQLite:dbname=:memory:'},
        "DummyNoconnect->connect(); fails"
    );
}

{
    my ($premature, @results) = run_tests(
        sub {
            no warnings 'redefine', 'once';
            local *DummySchema::deploy = sub { die "no deploy" };
            my $schema = connect_dbic_sqlite_ok('DummySchema');
        }
    );
    like(
        $premature,
        qr{Error deploying 'DummySchema' to 'dbi:SQLite:dbname=:memory:': no deploy},
        "DummySchema->deploy(); fails"
    );
}

{
    my ($premature, @results) = run_tests(
        sub {
            my $callback = sub { die "error in callback" };
            my $schema = connect_dbic_sqlite_ok('DummySchema', undef, $callback);
        }
    );
    like(
        $premature,
        qr{Error in post-connect-hook: error in callback at $0},
        "calling callback fails"
    );
}

{
    check_test(
        sub {
            my $callback = sub { return 1; };
            my $schema = connect_dbic_sqlite_ok('DummySchema', undef, $callback);
        },
        {
            ok   => 1,
            name => 'the schema ISA DummySchema',
        },
        "connect_dbic_sqlite_ok()"
     );
}

done_testing();
