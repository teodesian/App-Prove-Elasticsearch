# PODNAME: App::Prove::Elasticsearch::Utils
# ABSTRACT: common functions used by multiple modules in the distribution.

package App::Prove::Elasticsearch::Utils;

use strict;
use warnings;

use Config::Simple();
use File::HomeDir();

=head1 FUNCTIONS

=head2 process_configuration

Read the configuration & any CLI args (key=value,key=value...), and set their values in ENV.

=cut

sub process_configuration {
    my $args = shift;
    my $conf = {};

    my $homedir = File::HomeDir::my_home() || '.';
    if (-e $homedir) {
        unless( Config::Simple->import_from("$homedir/elastest.conf", $conf) ) {
            warn Config::Simple->error() if -e "$homedir/elastest.conf";
        }
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

=head2 require_indexer($conf)

Require the needed indexer implied by the configuration passed.
Set the relevant ENV var for use by parser, etc.

=cut

sub require_indexer {
    my $conf = shift;
    my $index_suffix = $conf->{'client.indexer'} ? "::".$conf->{'client.indexer'} : '';
    my $indexer = "App::Prove::Elasticsearch::Indexer$index_suffix";

    eval "require $indexer";
    die $@ if $@;

    #Set ENV for use by harness
    $ENV{CLIENT_INDEXER} = $indexer;
    return $indexer;
}

=head2 require_planner($conf)

Require the needed planner implied by the configuration passed.
Set the relevant ENV var for use by parser, etc.

=cut

sub require_planner {
    my $conf = shift;
    return _require_generic(
        $conf,
        'App::Prove::Elasticsearch::Planner',
        'client.planner',
        'CLIENT_PLANNER'
    );
}

=head2 require_platformer($conf)

Require the needed platformer implied by the configuration passed.
Set the relevant ENV var for use by parser, etc.

=cut

sub require_platformer {
    my $conf = shift;
    return _require_generic(
        $conf,
        'App::Prove::Elasticsearch::Platformer',
        'client.platformer',
        'CLIENT_PLATFORMER'
    );
}

sub _require_generic {
    my ($conf,$prefix,$suffix_key,$envvar) = @_;
    my $suffix = $conf->{$suffix_key} // 'Default';
    my $module = "${prefix}::$suffix";

    eval "require $module";
    die $@ if $@;

    #Set ENV for use by harness
    $ENV{$envvar} = $module;
    return $module
}

1;
