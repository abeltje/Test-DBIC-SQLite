#! perl -I.
use t::Test::abeltje;

use Test::DBIC::SQLite;

{
    note("Check backward-compatible function 'connect_dbic_sqlite_ok'");
    my $schema = connect_dbic_sqlite_ok(
        'Music::Schema',
        undef,    # ':memory:'
        \&populate_db
    );

    ok(
        exists($schema->storage->connect_info->[3]{skip_version}),
        "skip_version exists"
    ) or diag(explain($schema->storage->connect_info));

    my @albums = $schema->resultset('Album')->search(
        {'album_artist.name' => 'Madness'},
        {join => 'album_artist'}
    );
    is(@albums, 1, "Found 1 album");

    my @songs = $albums[0]->search_related('songs', {}, {order => 'track'});
    is(@songs, 14, "Found 14 songs");
    is($songs[1]->name, 'One Step Beyond', "Correct song");
}

{
    note("Check the 'connect_dbic_ok' method");
    my $schema = Test::DBIC::SQLite->connect_dbic_ok(
        schema_class      => 'Music::Schema',
        post_connect_hook => \&populate_db
    );

    ok(
        exists($schema->storage->connect_info->[3]{skip_version}),
        "skip_version exists"
    ) or diag(explain($schema->storage->connect_info));

    my @albums = $schema->resultset('Album')->search(
        {'album_artist.name' => 'Madness'},
        {join => 'album_artist'}
    );
    is(@albums, 1, "Found 1 album");

    my @songs = $albums[0]->search_related('songs', {}, {order => 'track'});
    is(@songs, 14, "Found 14 songs");
    is($songs[1]->name, 'One Step Beyond', "Correct song");
}

abeltje_done_testing();

sub populate_db {
    my ($schema) = @_;
    use Music::FromYAML 'artist_from_yaml';
    artist_from_yaml($schema, 't/madness.yml')
}
