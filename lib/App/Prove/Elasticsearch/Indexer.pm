# ABSTRACT: Define what data is to be uploaded to elasticsearch, and handle it's uploading
# PODNAME: App::Prove::Elasticsearch::Indexer

package App::Prove::Elasticsearch::Indexer;

use strict;
use warnings;
use utf8;

use Search::Elasticsearch();

=head1 SYNOPSIS

    App::Prove::Elasticsearch::Indexer::check_index({ 'server.host' => 'zippy.test', 'server.port' => 9600 });

=head1 VARIABLES

=head2 index (STRING)

The name of the elasticsearch index used.
If you are subclassing this, be aware that the Searcher plugin will rely on this.

=cut

our $index = 'testsuite';

sub index {
    return $index;
}

=head1 SUBROUTINES

=head2 check_index

Returns 1 if the index needed to be created, 0 if it's already OK.
Dies if the server cannot be reached, or the index creation fails.

=cut

sub check_index {
    my $conf = shift;

    my $port = $conf->{'server.port'} ? ':'.$conf->{'server.port'} : '';
    die "server must be specified" unless $conf->{'server.host'};
    die("port must be specified") unless $port;
    my $serveraddress = "$conf->{'server.host'}$port";
    my $e = Search::Elasticsearch->new(
        nodes           => $serveraddress,
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
                    testsuite => {
                        properties => {
                            id      => { type => "integer" },
                            elapsed => { type => "integer" },
                            occurred      => {
                                type   => "date",
                                format => "yyyy-MM-dd HH:mm:ss"
                            },
                            executor           => { type => "text" },
                            status             => { type => "text" },
                            version            => { type => "text" },
                            platform           => { type => "text" },
                            path               => { type => "text" },
                            body               => {
                                type        => "text",
                                analyzer    => "default",
                                fielddata   => "true",
                                term_vector => "yes",
                                similarity  => "classic",
                                fields      => {
                                    keyword => { type => "keyword" }
                                }
                            },
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
                            steps => {
                                properties  => {
                                    number  => { type => "integer" },
                                    text    => { type => "text" },
                                    status  => { type => "text" },
                                    elapsed => { type => "integer" },
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

=head2 index_results

Index a test result (see L<App::Prove::Elasticsearch::Parser> for the input).

=cut

sub index_results {
    my ($conf,$result) = @_;

    my $port = $conf->{'server.port'} ? ':'.$conf->{'server.port'} : '';
    my $serveraddress = "$conf->{'server.host'}$port";
    die("server and port must be specified") unless $serveraddress;
    my $e = Search::Elasticsearch->new(
        nodes           => $serveraddress,
    );

    my $idx = _get_last_index($e);
    $idx++;

    $e->index(
        index => $index,
        id    => $idx,
        type  => 'result',
        body  => $result,
    );

    my $doc_exists = $e->exists(index => $index, type => 'result', id => $idx );
    if (!defined($doc_exists) || !int($doc_exists)) {
        die "Failed to Index $result->{'name'}, could find no record with ID $idx\n";
    } else {
        print "Successfully Indexed test: $result->{'name'} with result ID $idx\n";
    }
}

sub _get_last_index {
    my ($e) = @_;

    my $res = $e->search(
        index => $index,
        body  => {
            query => {
                match_all => { }
            },
            sort => {
                id => {
                  order => "desc"
                }
            },
            size => 1
        }
    );

    my $hits = $res->{hits}->{hits};
    return 0 unless scalar(@$hits);

    return $res->{hits}->{total};
}

1;

__END__

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
