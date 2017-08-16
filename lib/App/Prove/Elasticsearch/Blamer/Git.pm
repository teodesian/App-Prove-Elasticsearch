# ABSTRACT: Determine the responsible party for tests via git for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Blamer::Git

package App::Prove::Elasticsearch::Blamer::Git;

use strict;
use warnings;
use utf8;

use Git;

sub get_responsible_party {
    my $email = Git::command_oneline('config', 'user.email');
    chomp $email;
    return $email;
}
