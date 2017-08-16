# ABSTRACT: Determine the version of a system under test via the module's CHANGES file for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Versioner::Default

package App::Prove::Elasticsearch::Versioner::Default;

use strict;
use warnings;
use utf8;


sub get_version {
    my $loc = dirname($0);
    my $ret;
    open(my $fh, '<', "$loc/../CHANGES") or die "Could not open CHANGES";
    while (<$fh>) {
        ($ret) = $_ =~ m/(^\w)/;
        last if $ret;
    }
    close $fh;
    die 'Could not determine the latest version from CHANGES!' unless $ret;
    return $ret;
}

1;
