use strict;
use warnings;

use Test::More tests => 3;
use Test::Fatal;
use App::Prove::Elasticsearch::Versioner::Default;

{
    local $0 = 't/data/bogus/zippy.t';
    is(App::Prove::Elasticsearch::Versioner::Default::get_version(),'0.111.1112.2.2.3',"get_version returns correct version in CHANGES");
}

{
    local $0 = '/bogus/someFileThatDoesNotExist.hokum';
    like(exception { App::Prove::Elasticsearch::Versioner::Default::get_version() },qr/could not open/i,"get_version dies on no CHANGES");
}

{
    local $0 = 't/data/bogus/morebogus/zippy.t';
    like(exception { App::Prove::Elasticsearch::Versioner::Default::get_version() },qr/could not determine/i,"get_version dies on no author in CHANGES");
}
