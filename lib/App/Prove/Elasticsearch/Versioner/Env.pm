# ABSTRACT: Determine the version of a system under test via environment variable for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Versioner::Env

package App::Prove::Elasticsearch::Versioner::Env;

use strict;
use warnings;
use utf8;

sub get_version {
    die "TESTSUITE_VERSION not set" unless $ENV{TESTSUITE_VERSION};
    return $ENV{TESTSUITE_VERSION};
}

1;
