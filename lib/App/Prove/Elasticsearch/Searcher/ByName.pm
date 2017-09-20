# ABSTRACT: Find out whether results exist for cases
# PODNAME: App::Prove::Elasticsearch::Searcher::ByName

package App::Prove::Elasticsearch::Searcher::ByName;

use strict;
use warnings;

use Search::Elasticsearch();
use File::Basename();
use Cwd();
use List::Util qw{uniq};

=head1 CONSTRUCTOR

=head2 new($server,$port,$index,[$versioner,$platformer])

Connect to the ES instance at $server:$port and check the provided index.
That should be defined by your indexer.

filter() requires knowledge of the versioner and platformer, so those must be passed as well.
They default to 'Default'.

=cut

sub new {
    my ($class,$server,$port,$index,$versioner,$platformer) = @_;
    $versioner //= 'Default';
    $platformer //= 'Default';
    my ($v, $p) = _require_deps($versioner,$platformer);

    return bless({
        handle => Search::Elasticsearch->new(
            nodes           => "$server:$port",
            request_timeout => 30
        ),
        index      => $index,
        versioner  => $v,
        platformer => $p,
    },$class);

}

=head1 METHODS

=head2 filter(@tests)

Filter out tests in your elasticsearch index matching the filename, platform and SUT version of the test result.
Designed to work with L<App::Prove::Elasticsearch::Indexer>.

=cut

sub filter {
    my ($self,@tests) = @_;

    my $platz = &{\&{$self->{platformer}."::get_platforms"}}();

    my @tests_filtered;
    foreach my $test (@tests) {
        $test = Cwd::abs_path($test);
        my $tname = File::Basename::basename($test);
        my $tversion = &{\&{$self->{versioner}."::get_version"}}($test); 
        my %q = (
            index => $self->{index},
            body  => {
                query => {
                    bool => {
                        must => [
                            {match => {
                                name => $tname,
                            }},
                            {match => {
                                version => $tversion,
                            }},
                        ],
                    },
                },
                size => 1
            },
        );

        foreach my $plat (@$platz) {
            push(@{$q{body}{query}{bool}{must}}, { match => { platform => $plat } } );
        }

        my $docs = $self->{handle}->search(%q);

        #OK, check if this document we got back *actually* matched
        next unless scalar(@{$docs->{hits}->{hits}});
        my $match = $docs->{hits}->{hits}->[0]->{_source};

        my @plats_match = ((ref($match->{platform}) eq 'ARRAY') ? @{$match->{platform}}: ($match->{platform}));

        my $name_correct    = $match->{name}    eq $tname;
        my $version_correct = $match->{version} eq $tversion;
        my $plats_size_ok   = scalar(@plats_match) == scalar(@$platz);
        my $plats_are_same  = scalar(@plats_match) == scalar(uniq((@plats_match,@$platz))); #XXX THIS IS WRONG, WHAT IF WE HAVE NO PLATZ
        my $plats_correct   = $plats_size_ok && $plats_are_same;

        if ($name_correct && $version_correct && $plats_correct) {
            print "# Not going to execute $test, it already has results in elasticsearch for this version and platform\n";
            next;
        }

        push(@tests_filtered,$test);
    }
    return @tests_filtered;
}

sub _require_deps {
    my ($versioner,$platformer) = @_;
    $versioner  = "App::Prove::Elasticsearch::Versioner::".$versioner;
    $platformer = "App::Prove::Elasticsearch::Platformer::".$platformer;
    eval "require $versioner";
    die $@ if $@;
    eval "require $platformer";
    die $@ if $@;
    return ($versioner,$platformer);
}

1;
