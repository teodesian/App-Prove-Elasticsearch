# ABSTRACT: Names your elasticsearch index after your distribution as defined in dist.ini
# PODNAME: App::Prove::Elasticsearch::Indexer::DzilDist

package App::Prove::Elasticsearch::Indexer::DzilDist;

use strict;
use warnings;

use parent qw{App::Prove::Elasticsearch::Indexer};

#Basically, do this:
#our $index = `awk '/^name/ {print \$NF}' dist.ini`;

our $index;
our $dfile //= 'dist.ini';

open(my $dh, '<', $dfile) or die "Could not open $dfile";
while (<$dh>) {
    ($index) = $_ =~ /^name\s*?=\s*?(.*)/;
    if ($index) {
        $index =~ s/^\s+//;
        last;
    }
}
close $dh;

