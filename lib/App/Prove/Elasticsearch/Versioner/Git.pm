# ABSTRACT: Determine the version of a system under test via git for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Versioner::Git

package App::Prove::Elasticsearch::Versioner::Git;

use strict;
use warnings;
use utf8;

use Git;

=head1 SUBROUTINES

=head2 get_version

Reads your git log and returns the current SHA as the version.

=cut

sub get_version {
    my $out = Git::command_oneline('log', '--format=format:%H');
    my @shas = split(/\n/,$out);
    return shift(@shas);
}

=head2 get_file_version(file)

Rather than getting the version of the software under test, get the version of a specific file.
Used to discover the version of a test being run for feeding into the indexer.

=cut

sub get_file_version {
    my $input = shift;
    my $out = Git::command_oneline('log', '--format=format:%H', '--follow', $input);
    my @shas = split(/\n/,$out);
    return shift(@shas);
}

1;
