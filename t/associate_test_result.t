use strict;
use warnings;

use Test::More tests => 9;
use Test::Deep;
use FindBin;

SKIP: {
    require_ok("$FindBin::Bin/../bin/associate_test_result") or skip("Can't require the needed binary",5);
    is(Bin::associate_test_result::main(),1,"Bad exit code provided when insufficient test args are passed");
    is(Bin::associate_test_result::main("zippy.test"),4,"Bad exit code provided when insufficient defect args are passed");

    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Utils::process_configuration = sub { return {} };
    use warnings;
    is(Bin::associate_test_result::main(qw{-d YOLO-666 zippy.test}),3,"Bad exit code provided when insufficient configuration passed");

    my %args_parsed;
    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Utils::process_configuration = sub { return { 'server.host' => 'zippy.test', 'server.port' => 666} };
    local *App::Prove::Elasticsearch::Utils::require_indexer = sub { return 'BogusIndexer' };
    local *BogusIndexer::check_index = sub {};
    local *BogusIndexer::associate_case_with_result = sub { %args_parsed = @_; return 0 };
    use warnings;
    is(Bin::associate_test_result::main(qw{-p clownOS -p clownBrowser -v 666.666 -d YOLO-420 -d YOLO-666 zippy.test}),0,"Good exit code provided when good args are passed");
    my $args_expected = {
        platforms => ['clownOS', 'clownBrowser'],
        versions  => ['666.666'],
        defects   => ['YOLO-420', 'YOLO-666'],
        case      => 'zippy.test',
    };
    is_deeply(\%args_parsed,$args_expected,"Arg Parse seems to work");

    no warnings qw{redefine once};
    local *BogusIndexer::associate_case_with_result = sub { return 2 };
    use warnings;
    is(Bin::associate_test_result::main(qw{-p clownOS -p clownBrowser -v 666.666 -d YOLO-420 -d YOLO-666 zippy.test}),2,"Bad exit code provided when good args are passed, but failure occurs");
}

like(qx{$FindBin::Bin/../bin/associate_test_result -h},qr/usage/i,"Usage printed when run -h, file is executable");
is($?,0,"Good exit code from binary in -h mode");
