package Test::DBIC::DBDConnector;
use v5.12.0;
use Moo::Role;

with 'MooX::Params::CompiledValidators';

requires qw( MyDBD_connection_parameters MyDBD_check_wants_deploy );

use parent 'Test::Builder::Module';

our $VERSION = '0.01';

sub builder { return Test::Builder::Module->builder }

=head1 NAME

Test::DBIC::DBDConnector - A Moo::Role for implementing DBD-versions of a DBIC test-class

=head1 SYNOPSIS

    package Test::DBIC::SQLite;
    use Moo;
    with 'Test::DBIC::MyDBD';

    sub MyDBD_connection_parameters {
        my $class = shift;
        my ($db_name) = @_;

        $db_name //= ':memory:';
        return [ "dbi:SQLite:dbname=$db_name" ];
    }

    sub MyDBD_check_wants_deploy {
        my $class = shift;
        my ($connection_params) = @_;

        my ($db_name) = $connection_params->[0] =~ m{dbname=(.+)(?:;|$)};
        my $wants_deploy = $db_name eq ':memory:'
            ? 1
            : ((not -f $db_name) ? 1 : 0);
        return $wants_deploy;
    }

    use namespace::autoclean 0.16;
    1;

    package main;
    use Test::More;
    my $schema = Test::DBIC::SQLite->connect_dbic_ok(schema_class => 'My::Schema');
    done_testing();

output:

    ok 1 - the schema ISA My::Schema
    1..1

=head1 DESCRIPTION

This L<Moo::Role> is intended to be the base for this type of tester module. It
is part of the L<Test::DBIC::SQLite> distribution because I<SQLite> is also used
for testing L<DBIx::Class>, so the only way to test this role (that deploys a
L<DBIx::Class::Schema> subclass to a database), was to write a working
implementation of L<Test::DBIC::SQLite> although there already was one.

=head2 Test::DBIC::YourDBD->connect_dbic_ok(%arguments)

=head3 Arguments

These are named parameters.

=over

=item B<schema_class> => C<$your_schema_class> (Required)

This is the L<DBIx::Class::Schema> subclass for your ORM.

=item B<dbi_connect_info> => C<$your_dbd_connect_info> (Optional)

 This argument is B<always> passed to the Driver-Specific-Implementation of C<<
 MyDBD_connection_parameters() >> that should return an array of arguments that
 will be passed to C<< DBIx::Class::Schema->connect() >>.

=item B<pre_deploy_hook> => C<$pre_deploy_hook> (Optional)

A CodeRef to execute I<before> C<< $schema->deploy >> is called.

This CodeRef is called with an instantiated C<< $your_schema_class >> object as argument.

=item B<post_connect_hook> => C<$post_connect_hook> (Optional)

A coderef to execute I<after> C<< $schema->deploy >> is called, if at all.

This coderef is called with an instantiated C<< $your_schema_class >> object as argument.

=back

=cut

sub connect_dbic_ok {
    my $class = shift;
    $class->validate_parameters(
        {
            $class->parameter(
                schema_class => $class->Required,
                {store => \my $schema_class}
            ),
            $class->parameter(
                dbi_connect_info => $class->Optional,
                {store => \my $connect_info}
            ),
            $class->parameter(
                pre_deploy_hook => $class->Optional,
                {store => \my $pre_deploy_hook}
            ),
            $class->parameter(
                post_connect_hook => $class->Optional,
                {store => \my $post_connect_hook}
            ),
        },
        {@_}
    );

    my $test_name = "the schema ISA $schema_class";

    # Start doing the test-procedure
    eval "require $schema_class";
    if (my $error = $@) {
        $class->builder->diag("Error loading '$schema_class': $error");
        return $class->builder->ok(0, $test_name);
    }

    my $connection_parameters = $class->MyDBD_connection_parameters($connect_info);
    my $wants_deploy = $class->MyDBD_check_wants_deploy($connection_parameters);

    my $schema = eval {
        $schema_class->connect(@$connection_parameters);
    };
    if (my $error = $@) {
        $class->builder->diag(
            "Error connecting '$schema_class' to '$connection_parameters->[0]': $error"
        );
        return $class->builder->ok(0, $test_name);
    }

    if ($wants_deploy) {
        if ($pre_deploy_hook) {
            eval { $pre_deploy_hook->($schema) };
            if (my $error = $@) {
                $class->builder->diag("Error in pre-deploy-hook: $error");
                $class->builder->ok(0, $test_name);
            }
        }

        eval { $schema->deploy };
        if (my $error = $@) {
            $class->builder->diag(
                "Error deploying '$schema_class' to '$connection_parameters->[0]': $error"
            );
            return $class->builder->ok(0, $test_name);
        }
    }
    if ($post_connect_hook) {
        eval { $post_connect_hook->($schema) };
        if (my $error = $@) {
            $class->builder->diag("Error in post-connect-hook: $error");
            return $class->builder->ok(0, $test_name);
        }
    }

    $class->builder->is_eq(ref($schema), $schema_class, $test_name);
    return $schema;
}

around MyDBD_connection_parameters => sub {
    my $connection_parameters = shift;
    my $self = shift;

    my $parameters = $self->$connection_parameters(@_);
    push @$parameters, undef while @$parameters < 3;

    my $options = $parameters->[3] // { };
    $options->{skip_version} //= 1;
    $parameters->[3] = $options;
    return $parameters;
};

=begin proxy-method

=head2 builder

This method just returns C<< Test::Builder::Module->builder >>

=end proxy-method

=head2 Test::DBIC::YourDBD->MyDBD_connection_parameters()

C<MyDBD_connection_parameters> is a class method that you must implement in your class.

=head3 Arguments

It gets the second argument from C<dbic_connect_ok()>, this will be DBD specific.

=head3 Response

This method should return an ArrayRef with the list of arguments to pass to C<<
YourDBD::DBIC::Schema->connect() >>

=cut

=head2 Test::DBIC::YourDBD->MyDBD_check_wants_deploy()

C<MyDBD_check_wants_deploy> is a class method that you must implement in your class.

=head3 Arguments

It get the second argument from C<dbic_connect_ok()>, this will be DBD specific.

=cut

=begin override

=head2 import_extra

This method is called by L<Test::Builder::Module>.

=end override

=cut

sub import_extra {
    strict->import;
    warnings->import;
    Test::Builder::Module->import;
}

=begin hide

=head2 ValidationTemplates

Current templates use L<Types::Standard>:

=over

=item schema_class => StrMatch[qr{^ [A-Za-z]\w+ (?:[:]{2}[A-Za-z]\w+)* $}x]

=item dbi_connect_info => Any

=item pre_deploy_hook => CodeRef

=item post_connect_hook => CodeRef

=back

This local version of the C<ValidationTemplates()> can be augmented by using C<around>

    around ValidationTemplates => sub {
        my $vt    = shift;
        my $class = shift;

        use Types::Standard qw( HashRef );
        my $templates = $class->$vt;
        return {
            %$templates,
            dbi_connect_info => { type => HashRef },
        };
    };

=end hide

=cut

sub ValidationTemplates {
    use Types::Standard qw( Maybe Any StrMatch CodeRef );
    return {
        schema_class      => { type => StrMatch[qr{^ [A-Za-z]\w+ (?:[:]{2}[A-Za-z]\w+)* $}x] },
        dbi_connect_info  => { type => Any },
        pre_deploy_hook   => { type => Maybe[CodeRef] },
        post_connect_hook => { type => Maybe[CodeRef] },
    };
}

1;

=head1 COPYRIGHT

(c) MMXXI - Abe Timmerman <abeltje@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
