use strict;
use warnings;

use Test::More tests => 7;
use Test::Fatal;

use App::Prove::Elasticsearch::Indexer;

#check_index
{
    no warnings qw{redefine once};
    local *Search::Elasticsearch::new = sub { return bless({},'Search::Elasticsearch') };
    local *Search::Elasticsearch::indices = sub { return bless({},'Search::Elasticsearch::Indices') };
    local *Search::Elasticsearch::Indices::exists = sub { return 1};
    use warnings;

    like(exception { App::Prove::Elasticsearch::Indexer::check_index() }, qr/server must be specified/i,"Indexer dies in the event server & port  is not specified");
    like(exception { App::Prove::Elasticsearch::Indexer::check_index({ 'server.port' => 666 }) }, qr/server must be specified/i,"Indexer dies in the event server are not specified");
    like(exception { App::Prove::Elasticsearch::Indexer::check_index({ 'server.host' =>'zippy.test' }) }, qr/port must be specified/i,"Indexer dies in the event port is not specified");

    is(App::Prove::Elasticsearch::Indexer::check_index({ 'server.host' => 'zippy.test', 'server.port' => 666}),0,"Indexer skips indexing in the event index already exists.");

    no warnings qw{redefine once};
    local *Search::Elasticsearch::Indices::exists = sub { return 0 };
    local *Search::Elasticsearch::Indices::create = sub { };
    use warnings;

    is(App::Prove::Elasticsearch::Indexer::check_index({ 'server.host' => 'zippy.test', 'server.port' => 666 }),1,"Indexer runs in the event index nonexistant.");
}

#index_results
{
    no warnings qw{redefine once};
    local *Search::Elasticsearch::new = sub { return bless({},'Search::Elasticsearch') };
    local *Search::Elasticsearch::index = sub { };
    local *Search::Elasticsearch::exists = sub { return 1};
    local *App::Prove::Elasticsearch::Indexer::_get_last_index = sub { return 0 };
    use warnings;

    is(App::Prove::Elasticsearch::Indexer::index_results({ 'server.host' => 'zippy.test', 'server.port' => 666 }, { name => 'zippy.test' }), 1, "Indexer runs in the event index nonexistant.");

    no warnings qw{redefine once};
    local *Search::Elasticsearch::exists = sub { return 0 };
    use warnings;

    like( exception { App::Prove::Elasticsearch::Indexer::index_results({ 'server.host' => 'zippy.test', 'server.port' => 666 }, { name => 'zippy.test' }) }, qr/failed to index/i, "Indexer runs in the event index nonexistant.");

}

#TODO test _get_last_index
