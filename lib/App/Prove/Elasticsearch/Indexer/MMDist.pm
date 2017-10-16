# ABSTRACT: Names your elasticsearch index after your distribution as defined in Makefile.PL
# PODNAME: App::Prove::Elasticsearch::Indexer::MMDist

package App::Prove::Elasticsearch::Indexer::MMDist;

use strict;
use warnings;

use parent qw{App::Prove::Elasticsearch::Indexer};

our $index = __CLASS__->SUPER::index;
our $dfile //= 'Makefile.PL';

if (open(my $dh, '<', $dfile)) {;
    while (<$dh>) {
        ($index) = $_ =~ /DISTNAME.*\s*?=>\s*?["|'](.*)["|'],?/;
        if ($index) {
            $index =~ s/^\s+//;
            last;
        }
    }
    close $dh;
} else {
    print "# WARNING: Could not open $dfile, falling back to index name '$index'\n";
}

1;

__END__

=head2 GOTCHAS

If dist.ini cannot be found, the index name will fall back to the default indexer's name.
