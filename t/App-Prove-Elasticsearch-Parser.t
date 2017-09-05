use strict;
use warnings;

use Test::More tests => 11;
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
    local *App::Prove::Elasticsearch::Indexer::index_results                 = sub { };
    local *App::Prove::Elasticsearch::Blamer::Default::get_responsible_party = sub { return 'billy' };
    local *App::Prove::Elasticsearch::Versioner::Default::get_version        = sub { return '666' };
    local *App::Prove::Elasticsearch::Platformer::Default::get_platforms     = sub { return ['zippyOS'] };
    local *App::Prove::Elasticsearch::Parser::_require_deps                  = sub { return @expected_modules };
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
    SKIP: {
        skip("Couldn't build parser",9) unless $p;
        is(exception {$p->run()}, undef, "Running parser works");
        is($p->{upload}->{version},'666',"Version correctly recognized");
        is($p->{upload}->{executor},'billy',"Executor correctly recognized");
        is($p->{upload}->{path},"$FindBin::Bin/data","Path correctly recognized");
        is($p->{upload}->{name},"pass.test","Test name correctly recognized");
        cmp_bag($p->{upload}->{platform},['zippyOS'],"Platform(s) correctly recognized");
        #status, steps, body
        like($p->{upload}->{body},qr/yay/i,"Full test output captured");
        is(scalar(@{$p->{upload}->{steps}}),1,"Test steps captured");
        is($p->{upload}->{status},'OK',"Test status captured");
    }
}
