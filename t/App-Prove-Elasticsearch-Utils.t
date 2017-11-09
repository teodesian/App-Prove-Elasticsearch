use strict;
use warnings;

use Test::More tests => 7;
use Test::Fatal;
use Test::Deep;

use FindBin;
use App::Prove::Elasticsearch::Utils;

CONF: {
    no warnings qw{redefine once};
    local *Config::Simple::import_from = sub {  $_[2]->{'server.host'} = 'zippy.test'; $_[2]->{'server.port'} = '666'; return 1 };
    local *File::HomeDir::my_home      = sub { return $FindBin::Bin };
    use warnings;

    my $expected = { 'server.host' => 'zippy.test', 'server.port' => 666 };
    is_deeply(App::Prove::Elasticsearch::Utils::process_configuration([]),$expected,"Config file parsed correctly");

    $expected = { 'server.host' => 'hug.test', 'server.port' => 333 };
    is_deeply(App::Prove::Elasticsearch::Utils::process_configuration(['server.host=hug.test','server.port=333']),$expected,"Config file parsed correctly, overridden correctly");

    no warnings qw{redefine once};
    local *File::HomeDir::my_home      = sub { return '/bogus' };
    is_deeply(App::Prove::Elasticsearch::Utils::process_configuration(['server.host=hug.test','server.port=333']),$expected,"No Config file OK too");
    use warnings;
}

REQUIRE: {
    is(exception { App::Prove::Elasticsearch::Utils::require_indexer({}) },undef,"Indexer load OK: defaults");
    like(exception { App::Prove::Elasticsearch::Utils::require_indexer({ 'client.indexer' => 'Bogus' }) },qr/INC/,"Indexer load fails on bogus module");

    #TODO cover require_planner and require_platformer
}

GET_LAST_ID: {
    no warnings qw{redefine once};
    local *Search::Elasticsearch::search = sub { return { 'hits' => { 'hits' => [] } } };
    use warnings;

    my $e = bless({},'Search::Elasticsearch');
    is(App::Prove::Elasticsearch::Utils::get_last_index($e,'zippy'), 0, "Can get last index when there are no hits.");

    no warnings qw{redefine once};
    local *Search::Elasticsearch::search = sub { return { 'hits' => { 'hits' => [1], total => 3 } } };
    use warnings;

    is(App::Prove::Elasticsearch::Utils::get_last_index($e,'zippy'), 3, "Can get last index when there are 3 hits.");

}


