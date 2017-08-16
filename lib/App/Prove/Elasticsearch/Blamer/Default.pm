# ABSTRACT: Determine the responsible for tests via CHANGES file for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Blamer::Default

package App::Prove::Elasticsearch::Blamer::Default;

use strict;
use warnings;
use utf8;

sub get_responsible_party {
    my $loc = dirname($0);
    my $ret;
    open(my $fh, '<', "$loc/../CHANGES") or die "Could not open CHANGES";
    while (<$fh>) {
        ($ret) = $_ =~ m/^\w\s*\w\s*(\w)/;
        last if $ret;
    }
    close $fh;
    die 'Could not determine the latest version from CHANGES!' unless $ret;
    return $ret;
}
