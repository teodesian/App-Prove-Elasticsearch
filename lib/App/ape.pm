package App::ape;

use strict;
use warnings;

use Pod::Usage;

use App::ape::test;
use App::ape::plan;
use App::ape::update;

sub new {
    my (undef,@args) = @_;
    my $command = shift @args;

    #I am being sneaky here and using bin/ape's POD
    return pod2usage(0) unless grep {$_ eq $command} qw{plan test update};

    my $program = "App::ape::$command";
    my $program_perlized = "$program.pm";
    $program_perlized =~ s/::/\//g;
    $0 = $INC{$program_perlized};

    return $program->new(@args);
}

1;
