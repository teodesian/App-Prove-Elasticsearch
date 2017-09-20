# ABSTRACT: Determine the platform of the system under test via Sys::Info::OS for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Platformer::Default

package App::Prove::Elasticsearch::Platformer::Default;

use strict;
use warnings;
use utf8;

use Sys::Info::OS;

=head1 SUBROUTINES

=head2 get_platforms

Return the OS version and perl version as an array.

=cut

sub get_platforms {
    my $info = Sys::Info::OS->new();
    return [ $info->name( edition => 1, long => 1 ), "Perl $]" ]
}

1;
