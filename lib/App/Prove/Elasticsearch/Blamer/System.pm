# ABSTRACT: Determine the responsible party for tests via system user & hostname for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Blamer::Env

package App::Prove::Elasticsearch::Blamer::System;

use strict;
use warnings;
use utf8;

use Sys::Info::OS;

sub get_responsible_party {
    my $info = Sys::Info::OS->new();
    return $info->login_name().'@'.$info->host_name();
}

1;
