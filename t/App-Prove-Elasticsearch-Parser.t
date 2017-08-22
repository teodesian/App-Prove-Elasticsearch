use strict;
use warnings;

use Test::More tests => 1;
use Test::Fatal;
use Test::Deep;
use Capture::Tiny qw{capture_merged};

use FindBin;
use App::Prove::Elasticsearch::Parser;

{
    no warnings qw{redefine once};
    use warnings;

    my $opts = { 'server.host'       => 'zippy.test',
                 'server.port'       => 666,
                 'client.indexer'    => '',
                 'client.blamer'     => 'Default',
                 'client.platformer' => 'Default',
                 'client.versioner'  => 'Default',
    };

    is(exception { App::Prove::Elasticsearch::Parser->new() }, undef, "make_parser executes all the way through");
}


