package App::Prove::Elasticsearch::Queue::Rabbit;

# PODNAME: App::Prove::Elasticsearch::Queue::Rabbit;
# ABSTRACT: Coordinate the running of test plans across multiple instances via RabbitMQ.

use strict;
use warnings;

use parent App::Prove::Elasticsearch::Queue::Default;

use List::Util qw{shuffle};
use App::Prove::Elasticsearch::Utils;

=head1 SUMMARY

Grabs a random selection of tests from a provided test plan, and executes them.

=head1 CONFIGURATION

Accepts a granularity option in the [Queue] section of elastest.conf controlling how many tests you want to grab at a time.
If the value is not set, we default to running everything available for our configuration.
You can use this to (minimize) duplicate work done when using multiple workers of the same configuration.

=head1 CONSTRUCTOR

=head2 new(%config_options)

Thin wrapper around App::Prove::Elasticsearch::Utils::process_configuration.
Subclasses likely will do more with this, such as advertise their availablilty to a queue.

=cut

sub new {
    my ($class,$input) = @_;
    my $conf = process_configuration($input);

    my $planner = App::Prove::Elasticsearch::Utils::require_planner($conf);
    &{ \&{$planner . "::check_index"} }($conf);

    return bless( $class, { config => process_configuration($input), planner => $planner } );
}

=head1 METHODS

=head2 get_work_left_in_index

Returns an array of all tests in a test plan in random order, which the client then must filter as desired.

=cut

sub get_work_left_in_index {
    my ($self,$jobspec) = @_;
    my $plan = &{ \&{$self->{planner} . "::get_plan"} }(%$jobspec);
    return () unless $plan;
    my @tests = ref $plan->{tests} eq 'ARRAY' ? @{$plan->{tests}} : ($plan->{tests});
    return shuffle(@tests);
}

=head2 queue_jobs

Stub method.  Does nothing except in 'real' queue modules like Rabbit, etc.

Called in bin/testplan to add jobs to our queue at plan creation.
Should return the number of jobs that failed to queue.

=cut

sub queue_jobs {
    return 0;
}

=head2 get_jobs

Gets the runner a selection of jobs that the queue thinks appropriate to our current configuration (if possible),
and that should keep it busy for a reasonable amount of time (see the granularity option).

The idea here is that clients will run get_jobs in a loop (likely using several workers) and run them until exhausted.

=cut

sub get_jobs {
    my ($self,$jobspec) = @_;
    my @jobs = $self->get_work_in_index($jobspec);
    return @jobs unless $self->{conf}->{'queue.granularity'};
    return splice(@jobs,0,$self->{conf}->{'queue.granularity'});
}

1;

__END__
