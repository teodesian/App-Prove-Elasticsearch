# ABSTRACT: Determine the responsible for tests via Changes file for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Blamer::Default

package App::Prove::Elasticsearch::Blamer::Default;

use strict;
use warnings;
use utf8;

use File::Basename qw{dirname};
use Cwd qw{abs_path};

=head1 SUBROUTINES

=head2 get_responsible_party

Get the responsible party from Changes

=cut

our $party = {};

sub get_responsible_party {
    my $loc = abs_path(dirname(shift)."/../Changes");

    return $party->{$loc} if $party->{$loc};
    my $ret;
    open(my $fh, '<', $loc) or die "Could not open $loc";
    while (<$fh>) {
        ($ret) = $_ =~ m/\s*\w*\s*(\w*)$/;
        last if $ret;
    }
    close $fh;
    die 'Could not determine the latest version from Changes!' unless $ret;
    $party->{$loc} = $ret;
    return $ret;
}

1;
