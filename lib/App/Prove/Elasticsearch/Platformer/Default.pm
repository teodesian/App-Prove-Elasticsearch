# ABSTRACT: Determine the platform of the system under test via Sys::Info::OS for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Platformer::Default

package App::Prove::Elasticsearch::Platformer::Default;

use strict;
use warnings;
use utf8;

use System::Info;

=head1 SUBROUTINES

=head2 get_platforms

Return the OS version and perl version as an array.

=cut

sub get_platforms {
    my $details = System::Info::sysinfo_hash();
    return [ $details->{osname}, $details->{distro}, "Perl $]" ]
}

1;
