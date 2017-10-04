use strict;
use warnings;

use Test::More tests => 1;
use App::Prove::Elasticsearch::Indexer::DzilDist;
use FindBin;

BEGIN: {
    no warnings qw{once};
    $App::Prove::Elasticsearch::Indexer::DzilDist::dfile = "$FindBin::Bin/data/dist.ini";
    use warnings;
}

require App::Prove::Elasticsearch::Indexer::DzilDist;
is($App::Prove::Elasticsearch::Indexer::DzilDist::index,'App-Prove-Plugin-Elasticsearch',"DZIL module name found correctly");

