# ABSTRACT: Determine the version of a system under test via the module's Changes file for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Versioner::Default

package App::Prove::Elasticsearch::Versioner::Default;

use strict;
use warnings;
use utf8;

use File::Basename qw{dirname};
use Cwd qw{abs_path};

=head1 SUBROUTINES

=head2 get_version

Reads Changes and returns the version therein.

=cut

sub get_version {
    my $loc = abs_path(dirname(shift)."/../Changes");
    my $ret;
    open(my $fh, '<', $loc) or die "Could not open Changes";
    while (<$fh>) {
        ($ret) = $_ =~ m/(^\S*)/;
        last if $ret;
    }
    close $fh;
    die 'Could not determine the latest version from Changes!' unless $ret;
    return $ret;
}

1;
