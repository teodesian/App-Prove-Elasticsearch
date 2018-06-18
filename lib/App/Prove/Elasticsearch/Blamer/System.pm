# ABSTRACT: Determine the responsible party for tests via system user & hostname for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Blamer::Env

package App::Prove::Elasticsearch::Blamer::System;

use strict;
use warnings;
use utf8;

use System::Info;

=head1 SUBROUTINES

=head2 get_responsible_party

Get the responsible party as your system user @ hostname.

=cut

sub get_responsible_party {
    my $info = System::Info->sysinfo_hash();
    return _get_uname() .'@'.$info->{hostname};
}

sub _get_uname {
    my @pw_info =  getpwuid($<);
    return $pw_info[0];
}

1;
