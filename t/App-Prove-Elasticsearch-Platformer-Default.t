use strict;
use warnings;

use Test::More tests => 1;
use Test::Deep;
use App::Prove::Elasticsearch::Platformer::Default;

{
    no warnings qw{redefine once};
    local *Sys::Info::OS::new = sub { return bless({},'Sys::Info::OS') };
    local *Sys::Info::OS::name = sub { return 'Zippy OS 6' };
    use warnings;
    local $] = 'v666';
    cmp_bag( App::Prove::Elasticsearch::Platformer::Default::get_platforms(),['Zippy OS 6','Perl v666'],"get_platforms returns expected information");
}
