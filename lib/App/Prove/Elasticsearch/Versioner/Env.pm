# ABSTRACT: Determine the version of a system under test via environment variable for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Versioner::Env

package App::Prove::Elasticsearch::Versioner::Env;

use strict;
use warnings;
use utf8;

=head1 SUBROUTINES

=head2 get_version

Reads $ENV{TESTSUITE_VERSION} and returns the version therein.

=cut

sub get_version {
    die "TESTSUITE_VERSION not set" unless $ENV{TESTSUITE_VERSION};
    return $ENV{TESTSUITE_VERSION};
}

1;
