package App::Prove::Elasticsearch::Provisioner::Perl;

# PODNAME: App::Prove::Elasticsearch::Provisioner::Perl;
# ABSTRACT: Provision perl on your SUT

use strict;
use warnings;

use App::perlbrew;
use Perl::Version;

=head1 SUMMARY

The 'default' model for this whole framework is to test CPAN style modules.
As such, provisioning here means using a different perl version to test the module in a CPANTesters style.

=head1 SUBROUTINES

=head2 get_available_provision_targets(current_version)

Returns a list of platforms it is possible to provision using this module.
In our case, this means the available installed versions of perl.

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

=head2 pick_platform(@platforms)

Pick out a platform from your list of platforms which can be provisioned.
Returns the relevant platform, and an arrayref of platforms less the relevant one used.

=cut

sub pick_platform {
    my (@plats) = @_;

    my $plat;
    foreach my $p (@plats) {
        if ($p =~ m/^perl/i) {
            $plat = $p;
            @plats = grep { $_ ne $p } @plats;
            last;
        }
    }
    return $plat, \@plats;
}

=head2 can_switch_version(versioner)

Returns whether the version can be changed via this provisioner given we use a compatible versioner.

=cut

sub can_switch_version {
    return 0;
}

=head2 switch_version_to(version)

Switch to the desired version.  Dies unless we can switch the SUT version, which is always in this case.

=cut

sub switch_version_to {
    die "Can't switch version via changing perl interpreter.";
}


=head2 provision(desired,existing)

Do all the necessary actions needed to provision the SUT into the passed perl version.

Example:

    $provisioner::provision('Perl 5.006','Perl 5.004');

=cut

sub provision {
    my ($desired_platform) = @_;
    my $pb = App::perlbrew->new('install');
    $pb->run_command_install($desired_platform);
    #This *should*? be enough magic to 'do the deed'
    %ENV = $pb->perlbrew_env($desired_platform);
    return $desired_platform;
}

1;

__END__
