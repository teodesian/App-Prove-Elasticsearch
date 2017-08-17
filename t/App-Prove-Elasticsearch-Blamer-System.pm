use strict;
use warnings;

use Test::More tests => 1;
use Test::Fatal;
use App::Prove::Elasticsearch::Blamer::Default;

{
    no warnings qw{redefine once}
    local *Sys::Info::OS::new = sub { return bless({},"Sys::Info::OS") };
    local *Sys::Info::OS::host_name = sub { return 'zippy.test' };
    local *Sys::Info::OS::login_name = sub { return 'zippy' };
    use warnings;
    like(exception { App::Prove::Elasticsearch::Blamer::System::get_responsible_party() },qr/root\@zippy.test/i,"get_responsible_party dies on no CHANGES");
}
