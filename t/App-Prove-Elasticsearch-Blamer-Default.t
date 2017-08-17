use strict;
use warnings;

use Test::More tests => 3;
use Test::Fatal;
use App::Prove::Elasticsearch::Blamer::Default;

{
    local $0 = 't/data/bogus/lessbogus/subdir/zippy.t';
    is(App::Prove::Elasticsearch::Blamer::Default::get_responsible_party(),'TEODESIAN',"get_responsible_party returns correct author in CHANGES");
}

{
    local $0 = '/bogus/someFileThatDoesNotExist.hokum';
    like(exception { App::Prove::Elasticsearch::Blamer::Default::get_responsible_party() },qr/could not open/i,"get_responsible_party dies on no CHANGES");
}

{
    local $0 = 't/data/bogus/zippy.t';
    like(exception { App::Prove::Elasticsearch::Blamer::Default::get_responsible_party() },qr/could not determine/i,"get_responsible_party dies on no author in CHANGES");
}
