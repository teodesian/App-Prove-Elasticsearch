use strict;
use warnings;

use Test::More tests => 1;
use Test::Fatal;
use App::Prove::Elasticsearch::Versioner::Git;

{
    no warnings qw{redefine once};
    local *Git::command_oneline = sub { return '666' };
    use warnings;
    is(App::Prove::Elasticsearch::Versioner::Git::get_version(),'666',"get_version returns correct version in TESTSUITE_VERSION");
}
