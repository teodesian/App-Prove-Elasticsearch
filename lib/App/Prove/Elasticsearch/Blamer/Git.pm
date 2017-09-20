# ABSTRACT: Determine the responsible party for tests via git for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Blamer::Git

package App::Prove::Elasticsearch::Blamer::Git;

use strict;
use warnings;
use utf8;

use Git;

=head1 SUBROUTINES

=head2 get_responsible_party

Get the responsible party from the author.email in git-config

=cut

sub get_responsible_party {
    my $email = Git::command_oneline('config', 'user.email');
    chomp $email;
    return $email;
}

1;
