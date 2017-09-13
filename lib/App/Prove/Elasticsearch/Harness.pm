# PODNAME:  App::Prove::Elasticsearch::Harness
# ABSTRACT: Harness for uploading test results to elasticsearch

package App::Prove::Elasticsearch::Harness;

use strict;
use warnings;
use utf8;

use parent qw/TAP::Harness/;

=head1 DESCRIPTION

Connective tissue between the elasticsearch prove plugin and the parser, which does all the real work.
You shouldn't need to modify, or even be aware of this module.

=head1 CONSTRUCTOR

=head2 new

Basically TAP::Harness, but that injects App::Prove::Elasticsearch::Parser as the parser.

=cut

# inject parser_class as Test::Rail::Parser.
sub new {
    my $class   = shift;
    my $arg_for = shift;
    $arg_for->{parser_class} = 'App::Prove::Elasticsearch::Parser';
    my $self = $class->SUPER::new($arg_for);
    return $self;
}

=head1 METHODS

=head2 make_parser

Like TAP::Parser::make_parser, but it also injects the ENV set by App::Prove::Elasticsearch into the parser args.

=cut

sub make_parser {
    my ($self, $job) = @_;

    my $args = $self->SUPER::_get_parser_args($job);

    my @relevant_keys = qw{SERVER_HOST SERVER_PORT CLIENT_INDEXER CLIENT_BLAMER CLIENT_VERSIONER CLIENT_PLATFORMER CLIENT_AUTODISCOVER};
    my @keys_filtered = grep { my $subj = $_; grep {$_ eq $subj} @relevant_keys } keys(%ENV);
    foreach my $key (@keys_filtered) {
        my $km = lc($key);
        $km =~ s/_/./g;
        $args->{$km} = $ENV{$key};
        $self->{$km} = $ENV{$key};
    }

    $self->SUPER::_make_callback( 'parser_args', $args, $job->as_array_ref );
    my $parser = $self->SUPER::_construct( $self->SUPER::parser_class, $args );

    $self->SUPER::_make_callback( 'made_parser', $parser, $job->as_array_ref );
    my $session = $self->SUPER::formatter->open_test( $job->description, $parser );

    return ( $parser, $session );
}

=head1 OVERRIDDEN METHODS

=head2 runtests

If the autodiscover option is passed, this will neglect to run the tests which already have results indexed.

=cut

sub runtests {
    my ($self, @tests) = @_;

    if ($self->{'client.autodiscover'}) {
        my $searcher = $self->_require_deps();
        @tests = $self->_filter_tests_with_results($searcher,@tests);
    }

    return $self->SUPER::runtests(@tests);
}

sub _filter_tests_with_results {
    my ($self,$searcher,@tests) = @_;
    my $indexer = $self->{'client.indexer'};
    my $s = $searcher->new($self->{'server.host'},$self->{'server.port'},$indexer::index);
    return $s->filter(@tests);
}

sub _require_deps {
    my ($self) = @_;

    eval "require $self->{'client.indexer'}";
    die $@ if $@;

    my $runner = "App::Prove::Elasticsearch::Searcher::$self->{'client.autodiscover'}";

    eval "require $runner";
    die $@ if $@;

    return $runner;
}


1;

__END__

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
