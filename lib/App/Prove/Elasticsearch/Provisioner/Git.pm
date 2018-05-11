package App::Prove::Elasticsearch::Provisioner::Git;

# PODNAME: App::Prove::Elasticsearch::Provisioner::Git;
# ABSTRACT: Provision new versions to test using git

use strict;
use warnings;

use App::perlbrew;
use Perl::Version;
use Capture::Tiny qw{capture_merged};

=head1 SUBROUTINES

=head2 get_available_provision_targets(current_value)

Returns a list of platforms it is possible to provision using this module.
In our case, this means the branches .

Filters out your current branch if passed.

=cut

sub get_available_provision_targets {
    my ($cv) = @_;
    my $branches = qx{git rev-parse --abbrev-ref --all};
    my @bs = split(/\n/,$branches);
    @bs = grep { $cv ne $_ } @bs if $cv;
    return @bs;
}

=head2 pick_platform(@platforms)

Pick out a platform from your list of platforms which can be provisioned.
Returns the relevant platform, and an arrayref of platforms less the relevant one used.

=cut

sub pick_platform {
    my (@plats) = @_;

    my $plat;
    foreach my $p (@plats) {
        my @cmd = (qw{git reflog show}, $p);
        my $rc = 0;
        capture_merged { $rc = system(@cmd) };
        if (!($rc >> 8)) {
            $plat = $p;
            @plats = grep { $_ ne $p } @plats;
            last;
        }
    }
    return $plat, \@plats;
}

=head2 can_switch_verison(versioner)

Returns whether the version can be changed via this provisioner given we use a compatible versioner.

=cut

sub can_switch_version {
    my $versioner = shift;
    return $versioner eq 'App::Prove::Elasticsearch::Versioner::Git';
}

=head2 switch_version_to(version)

Switch to the desired version.  Dies unless can_switch_version().

=cut

sub switch_version_to {
    my $version_to = shift;
    die unless can_switch_version();
    #TODO use git modules to 'do this right, check output etc'
    qx{git reset --hard $version_to};
}

=head2 provision(desired,existing)

Do all the necessary actions needed to provision the SUT into the passed platform.

Example:

    $provisioner::provision('Perl 5.006','Perl 5.004');

=cut

sub provision {
    my ($desired_platform,$existing_platform) = @_;
    #Move us into a detached HEAD at the desired remote/branch, or just the branch.
    #TODO do this right, verify remote/branch passed exists, etc.
    qx{git checkout $desired_platform};
}


1;

__END__
