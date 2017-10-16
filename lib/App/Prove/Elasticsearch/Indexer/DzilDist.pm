# ABSTRACT: Names your elasticsearch index after your distribution as defined in dist.ini
# PODNAME: App::Prove::Elasticsearch::Indexer::DzilDist

package App::Prove::Elasticsearch::Indexer::DzilDist;

use strict;
use warnings;

use parent qw{App::Prove::Elasticsearch::Indexer};

#Basically, do this:
#our $index = `awk '/^name/ {print \$NF}' dist.ini`;

our $index = __CLASS__->SUPER::index;
our $dfile //= 'dist.ini';

if ( open(my $dh, '<', $dfile) ) {
    while (<$dh>) {
        ($index) = $_ =~ /^name\s*?=\s*?(.*)/;
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
