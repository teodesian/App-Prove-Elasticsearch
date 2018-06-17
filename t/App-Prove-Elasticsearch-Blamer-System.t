use strict;
use warnings;

use Test::More tests => 1;
use Test::Fatal;
use App::Prove::Elasticsearch::Blamer::System;

{
    no warnings qw{redefine once};
    local *Sys::Info::OS::new = sub { return bless({},"Sys::Info::OS") };
    local *Sys::Info::OS::host_name = sub { return 'zippy.test' };
    local *Sys::Info::OS::login_name = sub { return 'zippy' };
    use warnings;
    is(App::Prove::Elasticsearch::Blamer::System::get_responsible_party(),'zippy@zippy.test',"get_responsible_party returns expected results");
}
