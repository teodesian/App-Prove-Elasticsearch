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

our $version = {};

sub get_version {
    my $loc = abs_path(dirname(shift)."/../Changes");

    return $version->{$loc} if $version->{$loc};
    my $ret;
    open(my $fh, '<', $loc) or die "Could not open Changes in $loc";
    while (<$fh>) {
        ($ret) = $_ =~ m/(^\S*)/;
        last if $ret;
    }
    close $fh;
    die 'Could not determine the latest version from Changes!' unless $ret;
    $version->{$loc} = $ret;
    return $ret;
}

=head2 get_file_version(file)

Gets the version of a particular file.  Used in versioners where that is possibly the case
such as Git.  In this case it will always be the same as the SUT version.

=cut

*get_file_version = \&get_version;

1;
