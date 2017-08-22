# PODNAME:  App::Prove::Plugin::Elasticsearch
# ABSTRACT: Prove Plugin to upload test results to elastic search as they are executed

package App::Prove::Plugin::Elasticsearch;

use strict;
use warnings;
use utf8;

use Config::Simple();
use File::HomeDir();

=head1 SYNOPSIS

`prove -PElasticsearch='server.host=zippy.test,server.port=666,client.blamer=FingerPointer,client.indexer=EvilIndexer,client.versioner=Git`

=head1 DESCRIPTION

Creates an index (if it does not exist)  called 'testsuite' in your specified Elasticsearch instance, which has the following parameters:

=over 4

=item B<body>: the raw text produced by prove -mv from your test.

=item B<elapsed>: the time it took the test to execute

=item B<occurred>: when the test began execution

=item B<executor>: the name of the executor.  This can be passed as executor=.  Defaults to root @ the host executed on.

=item B<version>: the version of the system under test.  See the versioner option as to how this is obtained.

=item B<environment>: the environment of the system under test.  See the platformer option as to how this is obtained.

=item B<name>: the filename of the test run

=item B<path>: the path to the test.  This is to allow tests with the same name at different paths to report correctly.

=item B<status>: whether the test global result was PASS, FAIL, SKIP, etc.  See L<App::Prove::Elasticsearch::Parser> for the rules as to these statuses.

=item B<steps>: detailed information (es object) as to the name, elapsed time, status and step # for each step.

=back

If this index does not exist, it will be created for you.
If an index exists with that name an exception will be thrown.
To override the index name to avoid exceptions, subclass App::Prove::Elasticsearch::Indexer and use your own name.
The name searched for must be a child of the App::Prove::Elasticsearch::Indexer, e.g. App::Prove::Elasticsearch::Indexer::EvilIndexer.

You may have noticed that this pluggable design does not necessarily mean you need to use elasticsearch as your indexer;
so long as the information above is all you need for your test management system, there's no reason you couldn't make a custom indexer for it.

=head2 VERSIONER

The version getter is necessarily complicated, as all perl modules do not necessarily provide a reliable method of acquiring this.
As such this behavior can be modified with the versioner= parameter.
This module ships with various versioners:

=over 4

=item B<Default>: used if no versioner is passed, the latest version in CHANGES is used.  Basically the CPAN module workflow.

=item B<Git>: use the latest SHA for the file.

=item B<Env>: use $ENV{TESTSUITE_VERSION} as the value used.  Handy when testing remote systems.

=back

App::Prove::Elasticsearch::Provisioner is built to be subclassed to discern the version used by your application.
For example, App::Prove::Elasticsearch::Provisioner::Default provides the 'Default' versioner.

=head2 PLATFORMER

Given that tests run on various platforms, we need a flexible way to determine that information.
As such, I've provided (you guessed it) yet another pluggable interface, App::Prove::Elasticsearch::Platformer.
Here are the shipped plugins:

=over 4

=item B<Default>: use Sys::Info::OS to determine the operating system environment, and $^V for the interpreter environment.

=item B<Env>: use $ENV{TESTSUITE_PLATFORM} as the environment.  Accepts comma separated variables.

=back

Unlike the other pluggable interfaces, this is intended to return an array of platforms describing the system under test.

=head2 BLAMER

All test results should be directly attributable to some entity.
As such, you can subclass App::Prove::Elasticsearch::Blamer to blame whatever is convenient for test results.
This module ships with:

=over 4

=item B<Default>: The latest author listed in CHANGES.

=item B<System>: user executing @ hostname

=item B<Git>: git config's author.email.

=item B<Env>: whatever is set in $ENV{TESTSUITE_EXECUTOR}.

=back

=head2 CONFIGURATION

All parameters passed to the plugin may be set in ~/elastest.conf, which read by Config::Simple.
Set the host and port values in the [Server] section.
Set the blamer, indexer and versioner values in the [Client] section.
If your Indexer & Versioner subclasses require additional configuration you may put them in arbitrary sections, as the entire configuration is passed to both parent classes.

=head1 CONSTRUCTOR

=head2 load

Like App::Prove::Plugin's example load() method, but that loads our configuration file, parses args and injects everything into $ENV to be read by the harness.
Also initializes the Elasticsearch index.

=cut

sub load {
    my ($class, $prove) = @_;

    my $app  = $prove->{app_prove};
    my $args = $prove->{args};

    my $conf = _process_configuration($args);

    $app->harness('App::Prove::Elasticsearch::Harness');
    $app->merge(1);

    my $indexer = _require_deps($conf);
    &{ \&{$indexer . "::check_index"} }($conf);

    return $class;
}

sub _process_configuration {
    my $args = shift;
    my $conf = {};

    my $homedir = File::HomeDir::my_home() || '.';
    if (-e $homedir) {
        Config::Simple->import_from("$homedir/elastest.conf", $conf) or die Config::Simple->error();
    }

    my @kvp = ();
    my ( $key, $value );
    foreach my $arg (@$args) {
        @kvp = split( /=/, $arg );
        if ( scalar(@kvp) < 2 ) {
            print
              "Unrecognized Argument '$arg' to App::Prove::Plugin::Elasticsearch, ignoring\n";
            next;
        }
        $key            = shift @kvp;
        $value          = join( '', @kvp );
        $conf->{$key} = $value;
    }

    #Set ENV for use by harness
    foreach my $key (keys(%$conf)) {
        my $km = uc($key);
        $km =~ s/\./_/g;
        $ENV{$km} = $conf->{$key};
    }

    return $conf;
}

sub _require_deps {
    my $conf = shift;
    my $index_suffix = $conf->{'client.indexer'} ? "::".$conf->{'client.indexer'} : '';
    my $indexer = "App::Prove::Elasticsearch::Indexer$index_suffix";

    eval "require $indexer";
    die $@ if $@;

    #Set ENV for use by harness
    $ENV{CLIENT_INDEXER} = $indexer;
    return $indexer;
}

1;

__END__

=head2 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
