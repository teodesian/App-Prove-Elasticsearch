# ABSTRACT: Determine the responsible party for tests via environment variable for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Blamer::Env

package App::Prove::Elasticsearch::Blamer::Env;

use strict;
use warnings;
use utf8;

=head1 SUBROUTINES

=head2 get_responsible_party

Get the responsible party from $ENV{TESTSUITE_EXECUTOR}

=cut

sub get_responsible_party {
    die "TESTSUITE_EXECUTOR not set" unless $ENV{TESTSUITE_EXECUTOR};
    return $ENV{TESTSUITE_EXECUTOR};
}

1;
