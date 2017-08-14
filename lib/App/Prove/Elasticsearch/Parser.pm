# PODNAME:  App::Prove::Elasticsearch::Parser
# ABSTRACT: Capture the output of prove, and upload the results of the test to elasticsearch

package App::Prove::Elasticsearch::Parser;

use strict;
use warnings;
use utf8;

use parent qw/TAP::Parser/;

use Clone qw{clone};

=head1 SYNOPSIS

    App::Prove::Elasticsearch::Parser->new();

=head1 CONSTRUCTOR

=head2 new

=cut

sub new {
    my ( $class, $opts ) = @_;
    $opts = clone $opts;  #Convenience, if we are passing over and over again...

    #Load our callbacks
    $opts->{'callbacks'} = {
        'test'    => \&testCallback,
        'comment' => \&commentCallback,
        'unknown' => \&unknownCallback,
        'bailout' => \&bailoutCallback,
        'EOF'     => \&EOFCallback,
        'plan'    => \&planCallback,
    };

    my $esopts = {
        'server.host'      => delete $opts->{'server.host'},
        'server.port'      => delete $opts->{'server.host'},
        'client.indexer'   => delete $opts->{'client.indexer'},
        'client.versioner' => delete $opts->{'client.versioner'},
        'client.blamer'    => delete $opts->{'client.blamer'},
    };

    #XXX maybe this could be done in the plugin and passed down? probably more efficient
    my $versioner = $esopts->{'client.versioner'};
    my $blamer    = $esopts->{'client.blamer'};
    require $versioner;
    require $blamer;
    $self->{executor}  = $blamer::get_responsible_party();
    $self->{version}   = $versioner::get_version();

    $self->{steps}     = [];
    $self->{starttime} = time();
    $self->{es_opts}   = $esopts;
    return $self;
}

# Look for file boundaries, etc.
sub unknownCallback {
    my ($test) = @_;
    my $self   = $test->{'parser'};
    my $line   = $test->as_string;
    $self->{'raw_output'} .= "$line\n";

    #Unofficial "Extensions" to TAP
    my ($status_override) = $line =~ m/^% mark_status=([a-z|_]*)/;
    if ($status_override) {
        cluck "Unknown status override"
          unless defined $self->{'tr_opts'}->{$status_override}->{'id'};
        $self->{'global_status'} =
          $self->{'tr_opts'}->{$status_override}->{'id'}
          if $self->{'tr_opts'}->{$status_override};
        print "# Overriding status to $status_override ("
          . $self->{'global_status'}
          . ")...\n"
          if $self->{'global_status'};
    }

    return;
}

# Register the current suite or test desc for use by test callback, if the line begins with the special magic words
sub commentCallback {
    my ($test) = @_;
    my $self   = $test->{'parser'};
    my $line   = $test->as_string;
    $self->{'raw_output'} .= "$line\n";

    return;
}

sub testCallback {
    my ($test) = @_;
    my $self = $test->{'parser'};

    my $line  = $test->as_string;
    $self->{'raw_output'} .= "$line\n";

    $line =~ s/^(ok|not ok)\s[0-9]*\s-\s//g;
    my $test_name = $line;

    #Setup args to pass to function
    my $status_name = 'NOT OK';
    if ( $test->is_actual_ok() ) {
        $status_name = 'OK';
        if ( $test->has_skip() ) {
            $status_name = 'SKIP';
            $test_name =~ s/^(ok|not ok)\s[0-9]*\s//g;
            $test_name =~ s/^# skip //gi;
        }
        if ( $test->has_todo() ) {
            $status_name = 'TODO PASS';
            $test_name =~ s/^(ok|not ok)\s[0-9]*\s//g;
            $test_name =~ s/^# todo & skip //gi;    #handle todo_skip
            $test_name =~ s/# todo\s(.*)$//gi;
        }
    }
    else {
        if ( $test->has_todo() ) {
            $status_name = 'TODO FAIL';
            $test_name =~ s/^(ok|not ok)\s[0-9]*\s//g;
            $test_name =~ s/^# todo & skip //gi;    #handle todo_skip
            $test_name =~ s/# todo\s(.*)$//gi;
        }
    }

    #XXX much of the above code would be unneeded if $test->description wasn't garbage
    $test_name =~ s/\s+$//g;

     #Test done.  Record elapsed time.
    my $tm = time();
    push(@{$self->{steps}},{
        elapsed => _compute_elapsed( $self->{'lasttime'}, $tm ),
        step    => $test->number, #XXX TODO maybe this isn't right
        name    => $test_name,
        status  => $status_name,
    });
    $self->{lasttime} = $tm;

    return 1;
}

sub bailoutCallback {
    my ($test) = @_;
    my $self   = $test->{'parser'};
    my $line   = $test->as_string;
    $self->{'raw_output'} .= "$line\n";
    $self->{'is_bailout'} = 1;
    return;
}

sub EOFCallback {
    my ($self) = @_;

    #Test done.  Record elapsed time.
    $self->{'elapsed'} = _compute_elapsed( $self->{'starttime'}, time() );

    #TODO actually do the upload to ES

    return $cres;
}

sub planCallback {
    my ($plan) = @_;
    my $self = $plan->{'parser'};
    $self->{raw_output} .= $plan->as_string;
}

#Compute the expected testrail date interval from 2 unix timestamps.
sub _compute_elapsed {
    my ( $begin, $end ) = @_;
    my $secs_elapsed  = $end - $begin;
    my $mins_elapsed  = floor( $secs_elapsed / 60 );
    my $secs_remain   = $secs_elapsed % 60;
    my $hours_elapsed = floor( $mins_elapsed / 60 );
    my $mins_remain   = $mins_elapsed % 60;

    my $datestr = "";

    #You have bigger problems if your test takes days
    if ($hours_elapsed) {
        $datestr .= "$hours_elapsed" . "h $mins_remain" . "m";
    }
    else {
        $datestr .= "$mins_elapsed" . "m";
    }
    if ($mins_elapsed) {
        $datestr .= " $secs_remain" . "s";
    }
    else {
        $datestr .= " $secs_elapsed" . "s";
    }
    undef $datestr if $datestr eq "0m 0s";
    return $datestr;
}

1;

__END__

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
