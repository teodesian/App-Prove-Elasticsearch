use strict;
use warnings;

package Test::GrapeApe::Tester;

use parent qw{Test::Class};
use Test::More;
use Test::Fatal;
use Test::Deep;
use Capture::Tiny qw{capture};

use App::ape::test;

sub test_new : Test(4) {
    is(App::ape::test->new(),1,"Passing no args results in error");
    is(App::ape::test->new(qw{--status OK}),2,"Passing no tests results in error");

    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Utils::process_configuration = sub { return {} };
    use warnings;

    is(App::ape::test->new(qw{--status OK whee.test}),3,"Calling with insufficient configuration results in error");

    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Utils::process_configuration = sub { return { 'server.host' => 'whee.test', 'server.port' => 666 } };
    local *App::Prove::Elasticsearch::Utils::require_indexer    = sub { return "Grape::Ape" };
    local *App::Prove::Elasticsearch::Utils::require_versioner  = sub { return "Grape::Ape" };
    local *App::Prove::Elasticsearch::Utils::require_blamer     = sub { return "Grape::Ape" };
    local *App::Prove::Elasticsearch::Utils::require_searcher   = sub { return "Grape::Ape" };
    local *App::Prove::Elasticsearch::Utils::require_platformer = sub { return "Grape::Ape" };
    local *Grape::Ape::check_index = sub {};
    local *Grape::Ape::new = sub { return bless({},'Grape::Ape') };
    local *Grape::Ape::get_version = sub { return 666 };
    local *Grape::Ape::get_file_version = sub { return 8675309 };
    local *Grape::Ape::get_platforms = sub { return ['a','b'] };
    use warnings;

    isa_ok(App::ape::test->new(qw{--status OK whee.test}),"App::ape::test");
}

__PACKAGE__->runtests();
