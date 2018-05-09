package App::Prove::Elasticsearch::Queue::Rabbit;

# PODNAME: App::Prove::Elasticsearch::Queue::Rabbit;
# ABSTRACT: Coordinate the running of test plans across multiple instances via RabbitMQ.

use strict;
use warnings;

use parent qw{App::Prove::Elasticsearch::Queue::Default};

use Net::RabbitMQ;
use JSON::MaybeXS;

=head1 SUMMARY

Subclass of App::Prove::Elasticsearch::Queue::Default, which overrides queue_jobs and get_jobs to use RabbitMQ.

Also provides helper subs to make coordination of effort more efficient.

=head1 CONFIGURATION

Accepts a server, port, user and password option in the [Queue] section of elastest.conf

Also accepts an exchange option, which I would recommend you set to durable & passive.

If you get the message "connection reset by peer" you probably have user permissions set wrong.  Do this:

    sudo rabbitmqctl set_permissions -p / $USER  ".*" ".*" ".*"

To resolve the problem.

=cut

sub new {
    my ($class,$input) = @_;
    my $self = $class->SUPER::new($input);

    #Connect to rabbit
    $self->{mq} = Net::RabbitMQ->new();
    $self->{config}->{'queue.exchange'} ||= 'testsuite';

    my $port = $self->{config}->{'queue.port'} ? ':'.$self->{config}->{'queue.port'} : '';
    die "server must be specified" unless $self->{config}->{'server.host'};
    my $serveraddress = "$self->{config}->{'queue.host'}$port";
use Carp::Always;

    $self->{mq}->connect($serveraddress, { user => $self->{config}->{'queue.user'}, password => $self->{config}->{'queue.password'} });
    return $self;
}

=head1 OVERRIDDEN METHODS

=head2 queue_jobs

Takes the jobs produced by get_work_for_plan() in the parent, and queues them in your configured rabbit server

Returns the number of jobs that failed to queue.

=cut

sub queue_jobs {
    my ($self,@jobs_to_queue) = @_;
    $self->{mq}->channel_open(1);

    my $errno = 0;
    my $options = $self->{config}->{'queue.exchange'} ? { exchange => $self->{config}->{'queue.exchange'}} : undef;
    foreach my $job (@jobs_to_queue) {
        $job->{queue_name} = "$job->{version}".join('',@{$job->{platforms}});
        #Publish each plan to it's own queue, and the name of this queue that needs work to the 'queues needing work' queue
        $self->{mq}->exchange_declare( 1, $self->{config}->{'queue.exchange'}, { auto_delete => 0, });
        $self->{mq}->queue_declare(1,$job->{queue_name}, { auto_delete => 0 });
        $self->{mq}->queue_bind(1, $job->{queue_name}, $self->{config}->{'queue.exchange'}, $job->{queue_name});
        #queue a test to a queue for the same version/platform/etc

        @{$job->{tests}} = &{ \&{$self->{planner} . "::find_test_paths"} }(@{$job->{tests}});

        #filter jobs by what is already done if this is a re-queue for optimization's sake
        if ($self->{requeue}) {
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
            @{$job->{tests}} = $self->{searcher}->filter(@{$job->{tests}});
        }

        foreach my $test (@{$job->{tests}}) {
            $self->{mq}->publish(1,$job->{queue_name}, $test, $options );
        }

        #Clients that wish to re-build to suit other jobs will have to query ES as to what other types of plans are available
        #This will result in the occasional situation where we rebuild, but work for the new queue has been exhausted by the time the worker gets there.
    }
    $self->{mq}->disconnect();
    return $errno;
}

=head2 get_jobs

Gets the runner a selection of jobs that the queue thinks appropriate to our current configuration (if possible),
and that should keep it busy for a reasonable amount of time.

The idea here is that clients will run get_jobs in a loop (likely using several workers) and run them until exhausted.
The queue will be considered exhausted if this returns undef.

=cut

sub get_jobs {
    my ($self,$jobspec) = @_;

    $self->{mq}->channel_open(2);

    #I don't think I will have to check that the platform is right & reject/requeue thanks to using multiple queues.
    my ($ctr,$job,@jobs);
    while ($job = $self->{mq}->get(2,$jobspec->{queue_name}, { exchange => $self->{config}->{'queue.exchange'} })) {
        $ctr++;
        last if $self->{config}->{'queue.granularity'} && $ctr >= $self->{config}->{'queue.granularity'};
        push(@jobs,$job->{body}) if $job->{body};
    }
    $self->{mq}->disconnect();

    return @jobs;
}

1;

__END__
