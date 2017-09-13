# ABSTRACT: Find out whether results exist for cases
# PODNAME: App::Prove::Elasticsearch::Searcher::ByName

package App::Prove::Elasticsearch::Searcher::ByName;

use strict;
use warnings;

use Search::Elasticsearch();
use File::Basename();
use Cwd();

=head1 CONSTRUCTOR

=head2 new($server,$port,$index)

Connect to the ES instance at $server:$port and check the provided index.
That should be defined by your indexer.

=cut

sub new {
    my ($class,$server,$port,$index) = @_;
    return bless({
        handle => Search::Elasticsearch->new(
            nodes           => "$server:$port",
            request_timeout => 30
        ),
        index => $index,
    },$class);
}

=head1 METHODS

=head2 filter(@tests)

Filter out tests in your elasticsearch index matching the filename and path of the test.
Designed to work with L<App::Prove::Elasticsearch::Indexer>.

=cut

sub filter {
    my ($self,@tests) = @_;
    my @tests_filtered;
    foreach my $test (@tests) {
        $test = Cwd::abs_path($test);
        my $docs = $self->{handle}->search(
            index => $self->{index},
            body  => {
                query => {
                    match => {
                        name => File::Basename::basename($test),
                        path => File::Basename::dirname($test),
                    },
                },
            },
        );
        push(@tests_filtered,$test) if scalar(@$docs);
    }
    return @tests_filtered;
}

1;
