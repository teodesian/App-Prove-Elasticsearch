use strict;
use warnings;

use Test::More tests => 3;
use Test::Fatal;
use Test::Deep;
use Capture::Tiny qw{capture_merged};

use FindBin;
use App::Prove::Elasticsearch::Parser;
use Carp::Always;

my @expected_modules = (
        'App::Prove::Elasticsearch::Versioner::Default',
        'App::Prove::Elasticsearch::Blamer::Default',
        'App::Prove::Elasticsearch::Indexer',
        'App::Prove::Elasticsearch::Platformer::Default'
);

{

    my $opts = { 'server.host'       => 'zippy.test',
                 'server.port'       => 666,
                 'client.indexer'    => 'App::Prove::Elasticsearch::Indexer',
                 'client.blamer'     => 'Default',
                 'client.platformer' => 'Default',
                 'client.versioner'  => 'Default',
                 'ignore_exit'       => undef,
                 'merge'             => 1,
                 'source'            => "$FindBin::Bin/data/pass.test",
                 'spool'             => undef,
                 'switches'          => [],
    };

    my @modules = App::Prove::Elasticsearch::Parser::_require_deps(undef,$opts);
    cmp_bag(\@modules,\@expected_modules,"Require of default extensions OK");
}

{
    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Indexer::index_results = sub { shift; diag explain shift; };
    local *App::Prove::Elasticsearch::Blamer::Default = sub { return 'billy' };
    local *App::Prove::Elasticsearch::Versioner::Default = sub { return '666' };
    local *App::Prove::Elasticsearch::Platformer::Default = sub { return ['zippyOS'] };
    local *App::Prove::Elasticsearch::Parser::_require_deps = sub { return @expected_modules };
    use warnings;

    my $opts = { 'server.host'       => 'zippy.test',
                 'server.port'       => 666,
                 'client.indexer'    => 'App::Prove::Elasticsearch::Indexer',
                 'client.blamer'     => 'Default',
                 'client.platformer' => 'Default',
                 'client.versioner'  => 'Default',
                 'ignore_exit'       => undef,
                 'merge'             => 1,
                 'source'            => "$FindBin::Bin/data/pass.test",
                 'spool'             => undef,
                 'switches'          => [],
    };

    my $p;
    is(exception { $p = App::Prove::Elasticsearch::Parser->new( $opts ) }, undef, "make_parser executes all the way through");
    is(exception {$p->run()}, undef, "Running parser works");
}


