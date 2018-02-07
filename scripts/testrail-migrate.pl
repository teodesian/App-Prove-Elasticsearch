#!/usr/bin/env perl

=head1 testrail_migrate.pl [OPTIONS] pattern1...patternN

Migrates TestRail test results (and test plans, optionally) into the test results database.
Only migrates plans with names matching the provided pattern.  If no patterns are provided, all will be indexed.

Requires you have a functioning ~/.testrailrc (see L<App::Prove::Plugin::TestRail>), and ~/.elastest.conf (see L<App::Prove::Elasticsearch>).

=head2 OPTIONS

=over 4

=item B<--index-plan>: Index the plans (or runs) encountered much as done with [testplan].

=item B<--project>: Index plans only from the provided project(s).  May be passed multiple times.

=item B<--no-tests>: Don't index test results.  Only useful with --index-plan.

=back

=cut

package TestRail::Migrate2ES;

use strict;
use warnings;

use Getopt::Long qw{GetOptionsFromArray};
use TestRail::API();
use TestRail::Utils();
use File::HomeDir qw{my_home};
use List::Util qw{any reduce};

use App::Prove::Elasticsearch::Utils;
use App::Prove::Elasticsearch::Indexer;

main(@ARGV) unless caller();

sub main {
    my @args = @_;
    my $options;

    GetOptionsFromArray(\@args,
        'project=s@' => \$options->{projects},
        'index-plan' => \$options->{'index-plan'},
        'no-tests'   => \$options->{'no-tests'},
    );
    my @patterns = @args;

    my $trconf = TestRail::Utils::parseConfig(my_home());
    my $tr = TestRail::Utils::getHandle($trconf);
    $tr->{step_field} = $trconf->{step_results};

    my $esconf = App::Prove::Elasticsearch::Utils::process_configuration();
    my $indexer = App::Prove::Elasticsearch::Utils::require_indexer($esconf);
    &{ \&{$indexer . "::check_index"} }($esconf);

    my $projects = $tr->getProjects();
    @$projects = grep {my $subj = $_; any { $subj->{name} eq $_ } @{$options->{projects}} } @$projects if scalar(@{$options->{projects}});

    foreach my $project (@$projects) {

        $tr->{current_status_map} = [];
        @{$tr->{current_status_map}} = reduce {
            my $ret;
            $ret = $a;
            $ret->{$b->{id}} = $b->{name};
            $ret->{$a->{id}} = $a->{name};
            $ret
        } @{$tr->getConfigurations($project->{id})};

        my $runs  = $tr->getRuns($project->{id});
        @$runs = grep {my $subj = $_; any { $subj->{name} =~ m/$_/ } @patterns } @$runs;

        my $plans = $tr->getPlans($project->{id});
        @$plans = grep {my $subj = $_; any { $subj->{name} =~ m/$_/ } @patterns } @$plans;

        #TODO handle plan upload
        #TODO handle no test mode

        foreach my $plan (@$plans) {
            my $planRuns = $tr->getChildRuns($tr->getPlanByID($plan->{id}));
            push(@$runs,@$planRuns);
        }

        foreach my $run (@$runs) {
            my $tests = $tr->getTests($run->{id});
            foreach my $test (@$tests) {
                $test->{config} = $run->{config};
                index_test($tr,$indexer,$test);
            }
        }
    }
}

sub index_test {
    my ($tr,$indexer,$test) = @_;

    my $results = $tr->getTestResults($test->{id});

    foreach my $result (@$results) {
        use Data::Dumper;
        die Dumper($result);

        my $test_mangled = {
            body     => $result->{comment},
            elapsed  => translate_elapsed($result->{elapsed}),
            occurred => $result->{created_on},
            status   => translate_status($result->{status_id}),
            executor => translate_author($tr,$result->{created_by}),
            version  => $result->{version},
            name     => $result->{title},
            #path     => dirname($result->{file}), #TODO figure this out?
        };

        $test_mangled->{defect}   = $result->{defects} if $result->{defects}; #XXX this may need more work if we have multi-defects on a case
        $test_mangled->{platform} = $test->{config}    if $test->{config}; #XXX this will need more work if we use multi-config
        $test_mangled->{steps}    = translate_steps($result->{"custom_$tr->{step_field}"}) if $tr->{step_field} && $result->{"custom_$tr->{step_field}"};

        use Data::Dumper;
        die Dumper($test_mangled);

        &{ \&{$indexer . "::index_results"} }($test_mangled);
    }

}

sub translate_status {
    my $status = shift;


    return $status;
}

sub translate_steps {
    my $steps = shift;

    return $steps;
}

sub translate_elapsed {

}

sub translate_author {
    my ($tr,$user) = @_;
    my $u = $tr->getUserByID($user);
    return $u->{name};
}
