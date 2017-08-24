# PODNAME:  App::Prove::Elasticsearch::Parser
# ABSTRACT: Capture the output of prove, and upload the results of the test to elasticsearch

package App::Prove::Elasticsearch::Parser;

use strict;
use warnings;
use utf8;

use parent qw/TAP::Parser/;

use Clone qw{clone};
use File::Basename qw{basename dirname};

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
        'server.host'       => delete $opts->{'server.host'},
        'server.port'       => delete $opts->{'server.port'},
        'client.indexer'    => delete $opts->{'client.indexer'},
        'client.versioner'  => delete $opts->{'client.versioner'} // 'Default',
        'client.blamer'     => delete $opts->{'client.blamer'} // 'Default',
        'client.platformer' => delete $opts->{'client.platformer'} // 'Default',
    };

    my $self = $class->SUPER::new($opts);
    if ( defined( $self->{'_iterator'}->{'command'} )
        && ref( $self->{'_iterator'}->{'command'} ) eq 'ARRAY' )
    {
        $self->{'file'} = $self->{'_iterator'}->{'command'}->[-1];
        print "# PROCESSING RESULTS FROM TEST FILE: $self->{'file'}\n";
    }

    #XXX maybe this could be done in the plugin and passed down? probably more efficient
    my ($versioner,$blamer,$indexer,$platformer) = $self->_require_deps($esopts);
    $self->{executor} = &{\&{$blamer."::get_responsible_party"}}();
    $self->{sut_version}  = &{\&{$versioner."::get_version"}}();
    $self->{platform} = &{\&{$platformer."::get_platforms"}}();
    $self->{indexer}  = $indexer;

    $self->{steps}     = [];
    $self->{starttime} = time();
    $self->{es_opts}   = $esopts;
    return $self;
}

sub _require_deps {
    my ($self,$esopts) = @_;
    my $versioner  = "App::Prove::Elasticsearch::Versioner::".$esopts->{'client.versioner'};
    my $blamer     = "App::Prove::Elasticsearch::Blamer::".$esopts->{'client.blamer'};
    my $indexer    = $esopts->{'client.indexer'};
    my $platformer = "App::Prove::Elasticsearch::Platformer::".$esopts->{'client.platformer'};
    eval "require $versioner";
    die $@ if $@;
    eval "require $blamer";
    die $@ if $@;
    eval "require $platformer";
    die $@ if $@;
    eval "require $indexer";
    die $@ if $@;
    return ($versioner,$blamer,$indexer,$platformer);
}

# Look for file boundaries, etc.
sub unknownCallback {
    my ($test) = @_;
    my $self   = $test->{'parser'};
    my $line   = $test->as_string;
    $self->{'raw_output'} .= "$line\n";

    #Unofficial "Extensions" to TAP
    my ($status_override) = $line =~ m/^% mark_status=([a-z|_]*)/;
    $self->{global_status} = $status_override if $status_override;

    #Allow the parser to operate on TAP files
    my $file = _getFilenameFromTapLine($line);
    $self->{'file'} = $file if !$self->{'file'} && $file;

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
    $self->{lasttime} //= $tm;
    push(@{$self->{steps}},{
        elapsed => ($tm - $self->{'lasttime'}),
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
    $self->{'elapsed'} = (time() - $self->{'starttime'} );

    my $todo_failed = $self->todo() - $self->todo_passed();
    my $status = 'NOT OK' if $self->has_problems();

    $status = 'TODO PASSED' if $self->todo_passed() && !$self->failed() && $self->is_good_plan();    #If no fails, but a TODO pass, mark as TODOP

    $status = 'TODO FAILED' if $todo_failed && !$self->failed() && $self->is_good_plan();    #If no fails, but a TODO fail, prefer TODOF to TODOP

    $status = "SKIPPED" if $self->skip_all();    #Skip all, whee

    #Global status override
    $status = $self->{'global_status'} if $self->{'global_status'};

    #Notify user about bad plan a bit better, supposing we haven't bailed
    if ( !$self->is_good_plan() && !$self->{'is_bailout'} ) {
        $self->{'raw_output'} .=
            "\n# ERROR: Bad plan.  You ran "
          . $self->tests_run
          . " tests, but planned "
          . $self->tests_planned . ".";
    }

    &{\&{$self->{indexer}."::index_results"}}( $self->{es_opts}, {
        body         => $self->{raw_output},
        elapsed      => $self->{elapsed},
        occurred     => $self->{starttime},
        status       => $self->{global_status},
        platform     => $self->{platform},
        executor     => $self->{executor},
        sut_version  => $self->{sut_version},
        name         => basename($self->{file}),
        path         => dirname($self->{file}),
        steps        => $self->{steps},
    });

    return $self->{global_status};
}

sub planCallback {
    my ($plan) = @_;
    my $self = $plan->{'parser'};
    $self->{raw_output} .= $plan->as_string;
}

sub _getFilenameFromTapLine {
    my $orig = shift;

    $orig =~ s/ *$//g;    # Strip all trailing whitespace

    #Special case
    my ($is_skipall) = $orig =~ /(.*)\.+ skipped:/;
    return $is_skipall if $is_skipall;

    my @process_split = split( / /, $orig );
    return 0 unless scalar(@process_split);
    my $dotty =
      pop @process_split;    #remove the ........ (may repeat a number of times)
    return 0
      if $dotty =~
      /\d/;  #Apparently looking for literal dots returns numbers too. who knew?
    chomp $dotty;
    my $line = join( ' ', @process_split );

    #IF it ends in a bunch of dots
    #AND it isn't an ok/not ok
    #AND it isn't a comment
    #AND it isn't blank
    #THEN it's a test name

    return $line
      if ( $dotty =~ /^\.+$/
        && !( $line =~ /^ok|not ok/ )
        && !( $line =~ /^# / )
        && $line );
    return 0;
}

1;

__END__

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
