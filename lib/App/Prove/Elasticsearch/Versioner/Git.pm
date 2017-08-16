# ABSTRACT: Determine the version of a system under test via git for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Versioner::Git

package App::Prove::Elasticsearch::Versioner::Git;

use strict;
use warnings;
use utf8;

use Git;

sub get_version {
    my $out = Git::command_oneline('log', '--format=format:%H');
    my @shas = split(/\n/,$out);
    return shift(@shas);
}
