# ABSTRACT: Determine the version of a system under test via the module's CHANGES file for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Versioner::Default

package App::Prove::Elasticsearch::Versioner::Default;

use strict;
use warnings;
use utf8;

use File::Basename qw{dirname};
use Cwd qw{abs_path};

sub get_version {
    my $loc = abs_path(dirname(shift)."/../CHANGES");
    my $ret;
    open(my $fh, '<', $loc) or die "Could not open CHANGES";
    while (<$fh>) {
        ($ret) = $_ =~ m/(^\S*)/;
        last if $ret;
    }
    close $fh;
    die 'Could not determine the latest version from CHANGES!' unless $ret;
    return $ret;
}

1;
