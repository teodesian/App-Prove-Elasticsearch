package App::ape;

use strict;
use warnings;

use App::ape::test;
use App::ape::plan;
#use App::ape::update;

sub new {
    my (undef,@args) = @_;
    my $command = shift @args;

    die "You must pass a valid command to ape: plan, test or update" unless grep {$_ eq $command} qw{plan test update};

    my $program = "App::ape::$command";
    my $program_perlized = "$program.pm";
    $program_perlized =~ s/::/\//g;
    $0 = $INC{$program_perlized};

    return $program->new(@args);
}

1;
