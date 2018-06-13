use strict;
use warnings;

use Test::More tests => 3;
use Cwd qw{abs_path};
use Test::Fatal;

use App::ape;

like( exception { App::ape->new('zippy') }, qr/valid command/i, "Valid command must be passed to ape");

my $old_procname = $0;

no warnings qw{redefine once};
*App::ape::test::new = sub { return 'whee' };
use warnings;

is( App::ape->new('test', '--help'), 'whee', "Correct ape submodule used");
is( $0, abs_path('lib/App/ape/test.pm'), "program name set correctly for use by perldoc help");

$0 = $old_procname;
