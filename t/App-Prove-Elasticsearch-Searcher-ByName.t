use strict;
use warnings;

use Test::More tests => 3;
use Test::Fatal;
use Test::Deep;

use App::Prove::Elasticsearch::Searcher::ByName;

{
    no warnings qw{redefine once};
    local *Search::Elasticsearch::new = sub { return 1 };
    use warnings;

    is( exception { App::Prove::Elasticsearch::Searcher::ByName->new('a','b','c') }, undef, "Constructor works");
}

{
    no warnings qw{redefine once};
    local *Search::Elasticsearch::search = sub {
        my ($self,%q) = @_;
        return [] if $q{body}{query}{match}{name} =~ /zippy.test$/;
        return ['some.test'];
    };
    local *Cwd::abs_path = sub { return shift };
    local *File::Basename::basename = sub { return shift };
    local *File::Basename::dirname  = sub { return shift };
    use warnings;

    my $s = bless({ 'handle' => bless({},'Search::Elasticsearch') },'App::Prove::Elasticsearch::Searcher::ByName');
    my @res = $s->filter('/path/to/zippy.test');
    cmp_bag(\@res,[],"bad tests get filtered out");

    @res = $s->filter('t/data/pass.test');
    cmp_bag(\@res,['t/data/pass.test'],"good tests *dont* get filtered out");
}
