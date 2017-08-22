use strict;
use warnings;

use Test::More tests => 2;
use Test::Fatal;
use Test::Deep;
use Capture::Tiny qw{capture_merged};

use FindBin;
use App::Prove::Elasticsearch::Harness;

{
    my $p = { verbosity => 1 };
    my $harness;
    is(exception { $harness = App::Prove::Elasticsearch::Harness->new($p) }, undef, "Happy path can execute all the way through");

    SKIP: {
        skip("Couldn't make harness",1) unless $harness;
        no warnings qw{redefine once};
        local *App::Prove::Elasticsearch::Parser::new = sub {};
        use warnings;

        my $scheduler = $harness->make_scheduler("$FindBin::Bin/data/pass.test");
        is(exception { $harness->make_parser($scheduler->get_job()) }, undef, "make_parser executes all the way through");
        #TODO check ENV is OK
    }
}

