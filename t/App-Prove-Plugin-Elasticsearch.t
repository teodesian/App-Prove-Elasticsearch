use strict;
use warnings;

use Test::More tests => 6;
use Test::Fatal;
use Test::Deep;
use Capture::Tiny qw{capture_merged};

use FindBin;
use App::Prove;
use App::Prove::Plugin::Elasticsearch;

MAIN: {

    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Indexer::check_index = sub { };
    local *App::Prove::Plugin::Elasticsearch::_process_configuration = sub { return {} };
    local *App::Prove::Plugin::Elasticsearch::_require_deps = sub { return 'App::Prove::Elasticsearch::Indexer' };
    use warnings;

    my $p = {args => [], app_prove => App::Prove->new()};
    is(exception { App::Prove::Plugin::Elasticsearch->load($p) }, undef, "Happy path can execute all the way through");
}

CONF: {
    no warnings qw{redefine once};
    local *Config::Simple::import_from = sub {  $_[2]->{'server.host'} = 'zippy.test'; $_[2]->{'server.port'} = '666'; return 1 };
    local *File::HomeDir::my_home      = sub { return $FindBin::Bin };
    use warnings;

    my $expected = { 'server.host' => 'zippy.test', 'server.port' => 666 };
    is_deeply(App::Prove::Plugin::Elasticsearch::_process_configuration([]),$expected,"Config file parsed correctly");

    $expected = { 'server.host' => 'hug.test', 'server.port' => 333 };
    is_deeply(App::Prove::Plugin::Elasticsearch::_process_configuration(['server.host=hug.test','server.port=333']),$expected,"Config file parsed correctly, overridden correctly");

    no warnings qw{redefine once};
    local *File::HomeDir::my_home      = sub { return '/bogus' };
    is_deeply(App::Prove::Plugin::Elasticsearch::_process_configuration(['server.host=hug.test','server.port=333']),$expected,"No Config file OK too");
    use warnings;
}

REQUIRE: {
    is(exception { App::Prove::Plugin::Elasticsearch::_require_deps({}) },undef,"Indexer load OK: defaults");
    like(exception { App::Prove::Plugin::Elasticsearch::_require_deps({ 'client.indexer' => 'Bogus' }) },qr/INC/,"Indexer load fails on bogus module");
}
