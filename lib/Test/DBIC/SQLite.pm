package Test::DBIC::SQLite;
use Moo;
with 'Test::DBIC::DBDConnector';

use parent 'Test::Builder::Module';
our @EXPORT = qw( connect_dbic_sqlite_ok );

our $VERSION = "1.00";

sub import_extra {
    warnings->import;
    strict->import;
}

sub connect_dbic_sqlite_ok {
    my $class = __PACKAGE__;
    my %args = $class->validate_positional_parameters(
        [
            $class->parameter(schema_class      => $class->Required),
            $class->parameter(dbi_connect_info  => $class->Optional),
            $class->parameter(post_connect_hook => $class->Optional),
        ],
        \@_
    );
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    # defaults don't work for optional positional parameters :(
    $args{dbi_connect_info} //= ':memory:';
    delete($args{post_connect_hook}) if @_ < 3;
    return $class->connect_dbic_ok(%args);
}

sub MyDBD_connection_parameters {
    my $class = shift;
    $class->validate_positional_parameters(
        [
            $class->parameter(
                dbi_connect_info => $class->Required,
                { store => \my $db_name }
            ),
        ],
        \@_
    );

    return [ "dbi:SQLite:dbname=$db_name" ];
}

sub MyDBD_check_wants_deploy {
    my $class = shift;
    $class->validate_positional_parameters(
        [
            $class->parameter(
                connection_info => $class->Required,
                { store => \my $connection_params }
            )
        ],
        \@_
    );

    my ($db_name) = $connection_params->[0] =~ m{dbname=(.+)(?:;|$)};
    my $wants_deploy = $db_name eq ':memory:'
        ? 1
        : ((not -f $db_name) ? 1 : 0);

    return $wants_deploy;
}

around ValidationTemplates => sub {
    my $vt = shift;
    my $class = shift;

    use Types::Standard qw( Maybe Str ArrayRef );

    my $validation_templates = $class->$vt();

    return {
        %$validation_templates,
        dbi_connect_info => { type => Maybe[Str], default => ':memory:' },
        connection_info  => { type => ArrayRef },
    };
};

use namespace::autoclean 0.16;
1;

=pod

=head1 NAME

Test::DBIC::SQLite - Connect to and deploy a DBIx::Class::Schema on SQLite

=head1 SYNOPSIS

The old way:

    #! perl -w
    use Test::More;
    use Test::DBIC::SQLite;
    my $schema = connect_dbic_sqlite_ok('My::Schema');
    done_testing();

The new way:

    #! perl -w
    use Test::More;
    use Test::DBIC::SQLite;
    my $schema = Test::DBIC::SQLite->connect_dbic_ok(schema_class => 'My::Schema');
    done_testing();

=head1 DESCRIPTION

This is a re-implementation of C<Test::DBIC::SQLite v0.01> that uses the
L<Moo::Role>: L<Test::DBIC::DBDConnector>.

It will C<import()> L<warnings> and L<strict> for you.

=begin hide

=head2 import_extra

L<Test::Builder::Module>'s way to import extra stuff, in this case enable
L<warnings> and L<strict> in the calling scope.

=end hide

=head2 connect_dbic_sqlite_ok($class[, $dbname[, $pre_deploy_hook[, $post_connect_hook]]])

Create an SQLite database (default in memory) and deploy the schema.

=head3 Arguments

Positional.

=over

=item $class (Required)

The class name of the L<DBIx::Class::Schema> to use.

=item $dbname (Optional)

The default is B<:memory:>, but a name for diskfile can be set here.

=item $pre_deploy_hook (Optional)

This callback is called after connecting to the database and just before calling
C<deploy> on the schema instance. Useful for initialising functions or triggers
that need to be in place for the schema, because it depends on it.

=item $post_connect_hook (Optional)

This callback is called after the connection is established and deploy, if that
was triggered. This hook is useful for populating the database.

=back

=head3 Returns

An initialized instance of C<$class>.

=head1 AUTHOR

(c) MMXV - Abe Timmerman <abeltje@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
