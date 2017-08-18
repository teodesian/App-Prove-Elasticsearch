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

=cut

our $index = 'testsuite';

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
    my $indexer = $conf->{'client.indexer'} // 'App::Prove::Elasticsearch::Indexer';
    if (!$e->indices->exists( index => $indexer::index )) {
        $e->indices->create(
            index => $indexer::index,
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
                            elapsed => { type => "integer" },
                            occurred      => {
                                type   => "date",
                                format => "yyyy-MM-dd HH:mm:ss"
                            },
                            executor           => { type => "text" },
                            status             => { type => "text" },
                            VERSION            => { type => "text" },
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

sub index_results {
    my ($conf,$result) = @_;

    my $port = $conf->{'server.port'} ? ':'.$conf->{'server.port'} : '';
    my $serveraddress = "$conf->{'server.host'}$port";
    die("server and port must be specified") unless $serveraddress;
    my $e = Search::Elasticsearch->new(
        nodes           => $serveraddress,
    );
    my $indexer = $conf->{'client.indexer'} // 'App::Prove::Elasticsearch::Indexer';
    $e->index(
        index => $index,
        type  => 'result',
        body  => $result,
    );

    my $doc_exists = $e->exists(index => $index, type => 'result', name => $result->{'name'}, path => $result->{path} );
    if (!int($doc_exists)) {
        die "Failed to Index $result->{'name'}\n";
    } else {
        print "Successfully Indexed Ticket ID: $result->{'name'}\n";
    }
}

1;

__END__

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
