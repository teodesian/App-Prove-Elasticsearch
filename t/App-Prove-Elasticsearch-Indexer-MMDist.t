use strict;
use warnings;

use Test::More tests => 1;
use FindBin;

BEGIN: {
    no warnings qw{once};
    $App::Prove::Elasticsearch::Indexer::MMDist::dfile = "$FindBin::Bin/data/Makefile.PL";
    use warnings;
}

require App::Prove::Elasticsearch::Indexer::MMDist;
is($App::Prove::Elasticsearch::Indexer::MMDist::index,'App-Prove-Plugin-Elasticsearch',"DZIL module name found correctly");
