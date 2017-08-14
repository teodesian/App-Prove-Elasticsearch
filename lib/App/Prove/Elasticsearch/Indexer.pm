# ABSTRACT: Define what data is to be uploaded to elasticsearch, and handle it's uploading
# PODNAME: App::Prove::Elasticsearch::Indexer

package App::Prove::Elasticsearch::Indexer;

use strict;
use warnings;
use utf8;

=head1 SYNOPSIS

    App::Prove::Elasticsearch::Indexer::check_index({ 'server.host' => 'zippy.test', 'server.port' => 9600 });

=head1 SUBROUTINES

=head2 check_index

Returns 1 if the index needed to be created, 0 if it's already OK.
Dies if the server cannot be reached, or the index creation fails.

=cut

sub check_index {
    my $conf = shift;

    my $port = $cfg->{'server:port'} ? ':'.$cfg->{'server:port'} : '';
    my $serveraddress = "$config->{'server:host'}$port";
    die("server and port must be specified") unless ;
    my $e = Search::Elasticsearch->new(
        nodes           => $serveraddress,
    );
    if (!$e->indices->exists( index => 'testsuite' )) {
        $e->indices->create(
            index => 'testsuite',
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

1;

__END__

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
