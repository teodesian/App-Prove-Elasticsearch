use strict;
use warnings;

package Test::GrapeApe::Planner;

use parent qw{Test::Class};
use Test::More;
use Test::Fatal;
use Test::Deep;

use App::ape::plan;

sub test_new : Test(5) {
    is(App::ape::plan->new(),2,"No args returns bad exit code");
    is(App::ape::plan->new(qw{--version 666 --show --prompt}),3,"Bad exit code returned due to incompatible options");

    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Utils::process_configuration = sub{return {}};
    use warnings;

    is(App::ape::plan->new(qw{--version 666}),4,"Bad exit code returned due to insufficient configuration");

    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Utils::process_configuration = sub {return { 'server.host' => 'bogus', 'server.port' => 'bogus'}};
    local *App::Prove::Elasticsearch::Utils::require_platformer = sub { return 'Grape::Ape::BananaBoat' };
    local *Grape::Ape::BananaBoat::get_platforms = sub { return ['grape', 'ape'] };
    local *App::Prove::Elasticsearch::Utils::require_planner = sub { return 'Grape::Ape::BananaBoat' };
    local *Grape::Ape::BananaBoat::check_index = sub {};
    local *App::Prove::Elasticsearch::Utils::require_queue = sub { return 'Grape::Ape::BananaBoat' };
    local *Grape::Ape::BananaBoat::new = sub { return bless({},'Grape::Ape::BananaBoat')};
    local *Grape::Ape::BananaBoat::_get_searcher = sub { return 'Grape::Ape::LostBananaPeel' };
    local *App::Prove::State::new = sub { return bless({},'App::Prove::State') };
    local *App::Prove::State::extensions = sub {};
    local *App::Prove::State::get_tests = sub { my (undef,undef,@ret) = @_; return @ret };
    use warnings;

    my $obj = App::ape::plan->new(qw{--version 666 --ext .t --platform zippy });

    my $expected = {
       'allplatforms' => undef,
       'exts' => [
         '.t'
       ],
       'name' => undef,
       'pairwise' => undef,
       'platforms' => [
         'zippy'
       ],
       'prompt' => undef,
       'recurse' => undef,
       'replay' => undef,
       'requeue' => undef,
       'show' => undef,
       'version' => '666'
    };

    isa_ok($obj,"App::ape::plan");
    is_deeply($obj->{options},$expected,"args appear to parse correctly");
}

__PACKAGE__->runtests();
