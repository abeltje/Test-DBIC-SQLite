#! perl -I. -w
use utf8;
use Test::Tester;
use t::Test::abeltje;

use Test::DBIC::SQLite;

{
    my $schema;
    # This is the only Test::Tester thing we do for an actual database
    # the rest of the tests is there to check that the hooks worked
    check_test(
        sub {
            $schema = Test::DBIC::SQLite->connect_dbic_ok(
                schema_class      => 'Music::Schema',
                pre_deploy_hook   => \&pre_deploy_hook,
                post_connect_hook => \&populate_db,
            );
        },
        {
            ok   => 1,
            name => "the schema ISA Music::Schema",
        },
        "Test::DBIC::SQLite->connect_dbic_ok()"
    );

    my $broadway = $schema->resultset('Album')->search(
        { name => 'Broadway the Hard Way' }
    )->first;
    isa_ok($broadway, 'Music::Schema::Result::Album');

    # First check that the function is available via DBI
    my $uc_last = $schema->storage->dbh->selectrow_hashref(
        "SELECT uc_last('uc_last') AS freturn"
    );
    is_deeply(
        $uc_last,
        { freturn => 'uc_lasT' },
        "Successfully implemented a function during PRE-DEPLOY"
    ) or diag(explain($uc_last));

    # Now integrate that function with DBIx::Class
    my $thing = $schema->resultset('AlbumArtist')->search(
        { name => 'Frank Zappa' },
        { columns => [ { ul_name => \'uc_last(name)' } ] }
    )->first;
    is(
        $thing->get_column('ul_name'),
        'frank zappA',
        "SELECT uc_last(name) AS ul_name FROM ...; works!"
    );
}

abeltje_done_testing();

sub pre_deploy_hook {
    my $schema = shift;
    my $dbh = $schema->storage->dbh;
    $dbh->sqlite_create_function(
        'uc_last',
        1,
        sub { my ($str) = @_; $str =~ s{(.*)(.)$}{\L$1\U$2}; return $str },
    );
}

sub populate_db {
    my $schema = shift;
    use Music::FromYAML;
    artist_from_yaml($schema, 't/zappa.yml')
}
