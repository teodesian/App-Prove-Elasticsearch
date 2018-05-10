package App::Prove::Elasticsearch::Provisioner::Git;

# PODNAME: App::Prove::Elasticsearch::Provisioner::Git;
# ABSTRACT: Provision new versions to test using git

use strict;
use warnings;

use App::perlbrew;
use Perl::Version;

=head1 RATIONALE

=head1 SUBROUTINES

=head2 get_available_provision_targets(current_version)

Returns a list of platforms it is possible to provision using this module.
In our case, this means the branches .

Relies on perlbrew to work.

Filters out your current version if passed.

TODO Filter out perl versions inappropriate for your code automatically.

=cut

sub get_available_provision_targets {
    my ($cv) = @_;
    my $pb = App::perlbrew->new('list');
    my @perls = $pb->available_perls();
    no warnings 'numeric';
    @perls = grep {
        my $v_sanitized = $_;
        $v_sanitized =~ s/c?perl-?//g;
        $v_sanitized =~ s/\.0/\./g; #remove leading zero from ancient perls
        Perl::Version->new(sprintf("%.3f",$cv)) != Perl::Version->new(sprintf("%.2f",$v_sanitized))
    } @perls if $cv;
    use warnings;
    return @perls;
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
