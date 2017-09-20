use strict;
use warnings;

use Test::More tests => 7;
use Test::Fatal;
use Test::Deep;

use App::Prove::Elasticsearch::Searcher::ByName;

{
    no warnings qw{redefine once};
    local *Search::Elasticsearch::new = sub { return 1 };
    local *App::Prove::Elasticsearch::Searcher::ByName::_require_deps = sub {};
    use warnings;

    is( exception { App::Prove::Elasticsearch::Searcher::ByName->new('a','b','c') }, undef, "Constructor works");
}

{

    no warnings qw{redefine once};
    local *Search::Elasticsearch::search = sub {
        my ($self,%q) = @_;
        return { hits => { hits => [ { _source => { name => 'zippy.test', version => '666.420', platform => 'a' } } ] } };
    };
    local *Cwd::abs_path = sub { return shift };
    local *File::Basename::basename = sub { return (split(/\//,shift))[-1] };
    local *File::Basename::dirname  = sub { return shift };
    local *main::get_version = sub {
        return '666.420';
    };
    local *main::get_platforms = sub {
        return ['a'];
    };
    use warnings;

    my $s = bless({'platformer' => 'main', 'versioner' => 'main', 'handle' => bless({ },'Search::Elasticsearch') },'App::Prove::Elasticsearch::Searcher::ByName');
    my @res = $s->filter('/path/to/zippy.test');
    cmp_bag(\@res,[],"bad tests get filtered out");

    @res = $s->filter('t/data/pass.test');
    cmp_bag(\@res,['t/data/pass.test'],"good tests *dont* get filtered out");

    no warnings qw{redefine once};
    local *main::get_platforms = sub { return [] };
    use warnings;

    @res = $s->filter('/path/to/zippy.test');
    cmp_bag(\@res,['/path/to/zippy.test'],"No platforms correctly recognized as being wrong");

    no warnings qw{redefine once};
    local *main::get_version = sub { return '666.421' };
    use warnings;

    @res = $s->filter('/path/to/zippy.test');
    cmp_bag(\@res,['/path/to/zippy.test'],"Wrong version correctly recognized as being wrong");

}

{
    my ($v,$p) = App::Prove::Elasticsearch::Searcher::ByName::_require_deps('Default','Default');
    is($v,'App::Prove::Elasticsearch::Versioner::Default',"Require deps returns correct versioner");
    is($p,'App::Prove::Elasticsearch::Platformer::Default',"Require deps returns correct platformer");
}
