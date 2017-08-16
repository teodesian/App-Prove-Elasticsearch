# ABSTRACT: Determine the platform(s) of the system under test via environment variable for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Platformer::Env

package App::Prove::Elasticsearch::Platformer::Env;

use strict;
use warnings;
use utf8;

sub get_platforms {
    die "TESTSUITE_PLATFORM not set" unless $ENV{TESTSUITE_PLATFORM};
    my @ret = split(/,/,$ENV{TESTSUITE_PLATFORM});
    return \@ret;
}

1;
