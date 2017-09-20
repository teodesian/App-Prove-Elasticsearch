# ABSTRACT: Determine the responsible party for tests via system user & hostname for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Blamer::Env

package App::Prove::Elasticsearch::Blamer::System;

use strict;
use warnings;
use utf8;

use Sys::Info::OS;

=head1 SUBROUTINES

=head2 get_responsible_party

Get the responsible party as your system user @ hostname.

=cut

sub get_responsible_party {
    my $info = Sys::Info::OS->new();
    return $info->login_name().'@'.$info->host_name();
}

1;
