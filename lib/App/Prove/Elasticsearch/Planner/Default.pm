# ABSTRACT: Index, create and retrieve test plans for use later
# PODNAME: App::Prove::Elasticsearch::Planner::Default

package App::Prove::Elasticsearch::Planner::Default;

use strict;
use warnings;

use Search::Elasticsearch();
use File::Basename();
use Cwd();
use List::Util qw{uniq};

our $index = 'testplans';

=head1 CONSTRUCTOR

=head2 new($server,$port)

Connect to the ES instance at $server:$port and check the index.
That should be defined as $index.

=cut

sub new {
    my ($class,$server,$port,$index) = @_;
    return bless({
        handle => Search::Elasticsearch->new(
            nodes           => "$server:$port",
            request_timeout => 30
        ),
        index      => $index,
    },$class);

}

=head1 METHODS

=head2 check_index

=cut

sub check_index {

}

=head2 add_plan_to_index

=cut

sub add_plan_to_index {

}

1;
