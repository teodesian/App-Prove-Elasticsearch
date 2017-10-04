# ABSTRACT: Names your elasticsearch index after your distribution as defined in Makefile.PL
# PODNAME: App::Prove::Elasticsearch::Indexer::MMDist

package App::Prove::Elasticsearch::Indexer::MMDist;

use strict;
use warnings;

use parent qw{App::Prove::Elasticsearch::Indexer};

our $index;
our $dfile //= 'Makefile.PL';

open(my $dh, '<', $dfile) or die "Could not open $dfile";
while (<$dh>) {
    ($index) = $_ =~ /DISTNAME.*\s*?=>\s*?["|'](.*)["|'],?/;
    if ($index) {
        $index =~ s/^\s+//;
        last;
    }
}
close $dh;
