# ABSTRACT: Index, create and retrieve test plans for use later
# PODNAME: App::Prove::Elasticsearch::Planner::Default

package App::Prove::Elasticsearch::Planner::Default;

use strict;
use warnings;

use App::Prove::Elasticsearch::Utils();

use Search::Elasticsearch();
use File::Basename();
use Cwd();
use List::Util qw{uniq};

our $index = 'testplans';
our $e; # for caching
our $last_id;

=head1 CONSTRUCTOR

=head2 check_index($conf)

Constructs a new Search::Elasticsearch object using the provided configuration file data, and stores it for use by other functions.
It then checks the index, and returns false or the object depending on the index status.

Creates the index if it does not exist.

=cut

sub check_index {
    my ($conf) = @_;

    my $port = $conf->{'server.port'} ? ':'.$conf->{'server.port'} : '';
    die "server must be specified" unless $conf->{'server.host'};
    die("port must be specified") unless $port;
    my $serveraddress = "$conf->{'server.host'}$port";

    $e //= Search::Elasticsearch->new(
        nodes           => $serveraddress,
        request_timeout => 30
    );

    #XXX for debugging
    #$e->indices->delete( index => $index );

    if (!$e->indices->exists( index => $index )) {
        $e->indices->create(
            index => $index,
            body  => {
                index => {
                    number_of_shards   => "3",
                    number_of_replicas => "2",
                    similarity         => {
                        default => {
                            type => "classic"
                        }
                    }
                },
                analysis => {
                    analyzer => {
                        default => {
                            type      => "custom",
                            tokenizer => "whitespace",
                            filter =>
                              [ 'lowercase', 'std_english_stop', 'custom_stop' ]
                        }
                    },
                    filter => {
                        std_english_stop => {
                            type      => "stop",
                            stopwords => "_english_"
                        },
                        custom_stop => {
                            type      => "stop",
                            stopwords => [ "test", "ok", "not" ]
                        }
                    }
                },
                mappings => {
                    testplan => {
                        properties => {
                            id      => { type => "integer" },
                            created => {
                                type   => "date",
                                format => "yyyy-MM-dd HH:mm:ss"
                            },
                            creator   => { type => "text" },
                            version   => { type => "text" },
                            platforms => { type => "text" },
                            tests     => { type => "text" },
                            pairwise  => { type => "boolean" },
                            name => {
                                type        => "text",
                                analyzer    => "default",
                                fielddata   => "true",
                                term_vector => "yes",
                                similarity  => "classic",
                                fields      => {
                                    keyword => { type => "keyword" }
                                }
                            },
                        }
                    }
                }
            }
        );
        return 1;
    }
    return 0;
}

=head1 METHODS

All methods below die if the ES handle hasn't been defined by check_index.

=head2 get_plan

Get a plan matching the description from Elasticsearch.

=cut

sub get_plan {
    my (%options) = @_;

    die "A version must be passed." unless $options{version};

    my %q = (
        index => $index,
        body  => {
            query => {
                bool => {
                    must => [
                        {match => {
                            version => $options{version},
                        }},
                    ],
                },
            },
            size => 1
        },
    );

    push(@{$q{body}{query}{bool}{must}}, { match => { name => $options{name} } } ) if $options{name};

    foreach my $plat (@{$options{platforms}}) {
        push(@{$q{body}{query}{bool}{must}}, { match => { platforms => $plat } } );    }

    my $docs = $e->search(%q);

    return 0 unless ref $docs eq 'HASH' && ref $docs->{hits} eq 'HASH' && ref $docs->{hits}->{hits} eq 'ARRAY';
    return 0 unless scalar(@{$docs->{hits}->{hits}});
    my $match = $docs->{hits}->{hits}->[0]->{_source};

    my @plats_match = ((ref($match->{platforms}) eq 'ARRAY') ? @{$match->{platforms}}: ($match->{platforms}));

    my $name_correct    = !$options{name} || ($match->{name} // '') eq ($options{name} // '');
    my $version_correct = $match->{version} eq $options{version};
    my $plats_size_ok   = scalar(@plats_match) == scalar(@{$options{platforms}});
    my $plats_are_same  = scalar(@plats_match) == scalar(uniq((@plats_match,@{$options{platforms}})));
    my $plats_correct   = !scalar(@{$options{platforms}}) || ($plats_size_ok && $plats_are_same);

    $match->{id} = $docs->{hits}->{hits}->[0]->{_id};
    return $match if ($name_correct && $version_correct && $plats_correct);

    return 0;
}

=head2 add_plan_to_index($plan)

Add or update a test plan.
Dies if the plan cannot be added/updated.
Returns 1 in the event of failure.

=cut

sub add_plan_to_index {
    my ($plan) = @_;

    if ($plan->{noop}) {
        print "Nothing to do!\n";
        return 0;
    }
    return _update_plan($plan) if $plan->{update};

    die "check_index not run, ES object not defined!" unless $e;

    my $idx = App::Prove::Elasticsearch::Utils::get_last_index($e,$index);
    $idx++;

    $e->index(
        index => $index,
        id    => $idx,
        type  => 'testplan',
        body  => $plan,
    );

    my $doc_exists = $e->exists(index => $index, type => 'testplan', id => $idx );
    my $pn =  $plan->{'name'} // '';
    if (!defined($doc_exists) || !int($doc_exists)) {
        print "Failed to Index $pn, could find no record with ID $idx\n";
        return 1;
    }

    print "Successfully Indexed plan $pn with result ID $idx\n";
    return 0;

}

sub _update_plan {
    my ($plan) = @_;

    #handle adding new tests, then subtract
    my @tests_merged = (@{$plan->{tests}},@{$plan->{update}->{addition}->{tests}});
    @tests_merged = grep { my $subj = $_; !grep { $_ eq $subj } @{$plan->{update}->{subtraction}->{tests}} } @tests_merged;

    my $res = $e->update(
        index => $index,
        id => $plan->{id},
        type => 'testplan',
        body => {
            doc => {
                tests => \@tests_merged,
            },
        }
    );

    print "Updated tests in plan #$plan->{id}\n" if $res->{result} eq 'updated';
    if (!grep { $res->{result} eq $_ } qw{updated noop}) {
        print "Something went wrong associating cases to document $plan->{id}!\n$res->{result}\n";
        return 1;
    }
    print "Successfully Updated plan #$plan->{id}\n";
    return 0;
}

=head2 make_plan(%plan)

Build a test plan ready to be indexed, and return it.

Takes a hash describing the plan to be created and then mangles it to fit in openstack.

=cut

sub make_plan {
    my (%options) = @_;
    die "check_index not run, ES object not defined!" unless $e;

    my %out = %options;
    $out{pairwise} = $out{pairwise} ? "True" : "False";
    delete $out{show};
    delete $out{prompt};
    delete $out{allplatforms};
    delete $out{exts};
    delete $out{recurse};
    delete $out{name} unless $out{name};

    $out{noop} = 1 unless scalar(@{$out{tests}});

    return \%out;
}

=head2 make_plan_update($existing_plan,%plan)

Build an update statement to modify an indexed plan.  The existing plan and a hash describing the modifications to the plan are required.

=cut

sub make_plan_update {
    my ($existing,%out) = @_;
    die "check_index not run, ES object not defined!" unless $e;
    #TODO be sure to do the right thing w pairwise testing (dole out tests appropriately)

    delete $out{show};
    delete $out{prompt};
    delete $out{allplatforms};
    delete $out{exts};
    delete $out{recurse};
    delete $out{name} unless $out{name};

    # There are some things we don't want to update.
    $out{platforms} = $existing->{platforms};
    $out{pairwise}  = $existing->{pairwise};

    $out{pairwise} //= 'False';

    my $adds = {};
    my $subs = {};
    foreach my $okey ( @{$out{tests}} ) {
        push(@{$adds->{tests}},$okey) if !grep { $_ eq $okey } @{$existing->{tests}}
    }
    foreach my $ekey ( @{$existing->{tests}} ) {
        push(@{$subs->{tests}},$ekey) if !grep { $_ eq $ekey } @{$out{tests}}
    }

    if (!scalar(keys(%$adds)) && !scalar(keys(%$subs)) ) {
        $existing->{noop} = 1;
        return $existing;
    }
    $existing->{update} = { addition => $adds, subtraction => $subs };

    return $existing;
}

1;
