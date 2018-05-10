package App::Prove::Elasticsearch::Runner::Default;

# PODNAME: App::Prove::Elasticsearch::Runner::Default;
# ABSTRACT: Run your tests in testd with prove

use strict;
use warnings;

use App::Prove;

=head1 RATIONALE

Most days you will run tests using 'prove'.
However, there's no reason to restrict this to perl testing,
this framework should work with any kind of testing problem.

Therefore, you get a runner plugin framework, much like the other App::Prove::Elasticsearch* plugins.

=head2 SUBROUTINES

=head1 run($config,@tests)

Runs the provided tests.
It is up to the caller to put rules files and rc files in the right place;
one trick would be to subclass this and dope out $ENV{HOME} temporarily to find the shinies correctly.

Alternatively, you could pass secret information in the elastest configuration to control behavior.
For example, you can set the args= parameter like you would on the command line in the [runner] section.

    [runner]
    args=-j2 -wlvm -Ilib
=cut

sub run {
    my ($config,@tests) = @_;

    my @args = ('-PElasticsearch');
    push(@args,(split(/ /,$config->{'runner.args'}))) if $config->{'runner.args'};
    push(@args,@tests);
    my $p = App::Prove->new();
    $p->process_args(@args);
    use Data::Dumper;
    die Dumper(\@args);
    return $p->run();
}

1;

__END__
