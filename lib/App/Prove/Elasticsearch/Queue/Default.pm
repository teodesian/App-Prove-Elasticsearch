package App::Prove::Elasticsearch::Queue::Default;

# PODNAME: App::Prove::Elasticsearch::Queue::Default;
# ABSTRACT: Coordinate the running of test plans across multiple forks.

use strict;
use warnings;

use List::Util qw{shuffle uniq};
use App::Prove::Elasticsearch::Utils;

=head1 SUMMARY

Grabs a random selection of tests from a provided test plan, and executes them.

=head1 CONFIGURATION

Accepts a granularity option in the [Queue] section of elastest.conf controlling how many tests you want to grab at a time.
If the value is not set, we default to running everything available for our configuration.
You can use this to (minimize) duplicate work done when using multiple workers of the same configuration.

Using queu

=head1 CONSTRUCTOR

=head2 new(%config_options)

Thin wrapper around App::Prove::Elasticsearch::Utils::process_configuration.
Subclasses likely will do more with this, such as advertise their availablilty to a queue.

=cut

sub new {
    my ($class,$input) = @_;
    my $conf = App::Prove::Elasticsearch::Utils::process_configuration($input);

    my $planner = App::Prove::Elasticsearch::Utils::require_planner($conf);
    &{ \&{$planner . "::check_index"} }($conf);

    return bless( { config => $conf, planner => $planner }, $class );
}

=head1 METHODS

=head2 get_jobs

Gets the runner a selection of jobs that the queue thinks appropriate to our current configuration (if possible),
and that should keep it busy for a reasonable amount of time (see the granularity option).

The idea here is that clients will run get_jobs in a loop (likely using several workers) and run them until exhausted.

=cut

sub get_jobs {
    my ($self,$jobspec) = @_;

	$self->{indexer} //= App::Prove::Elasticsearch::Utils::require_indexer($self->{config});

    my $searcher = App::Prove::Elasticsearch::Utils::require_searcher($self->{config});
    $self->{searcher} = &{ \&{$searcher . "::new"} }(
        $searcher,
		$self->{config}->{'server.host'},
		$self->{config}->{'server.port'},
		$self->{indexer}->index,
		$self->{config}->{'client.versioner'},
		$self->{config}->{'client.platformer'},
	);

    $jobspec->{searcher} = $self->{searcher};
    my $plans = &{ \&{$self->{planner} . "::get_plans_needing_work"} }(%$jobspec);
    return () unless scalar(@$plans);

	my @tests;
	foreach my $plan (@$plans) {
        my @tmp_tests = ref $plan->{tests} eq 'ARRAY' ? @{$plan->{tests}} : ($plan->{tests});
        push(@tests,@tmp_tests);
	}
	@tests = shuffle($self->{searcher}->filter(uniq @tests));
    return @tests unless $self->{config}->{'queue.granularity'};
	@tests = splice(@tests,0,$self->{config}->{'queue.granularity'});
	return @tests;
}

=head2 queue_jobs

Stub method.  Does nothing except in 'real' queue modules like Rabbit, etc.

Called in bin/testplan to add jobs to our queue at plan creation.
Should return the number of jobs that failed to queue.

=cut

sub queue_jobs {
    print "Queued local job.\n";
    return 0;
}

=head2 build_queue_name

Builds a queue_name inside a passed jobspec containing version and platforms information.

Here mostly in case you need to override this for your queueing solution.

=cut

sub build_queue_name {
	my ($self,$jobspec) = @_;
	my $name = $jobspec->{version};
	$name .= join('',@{$jobspec->{platforms}});
	return $name;
}

1;

__END__
