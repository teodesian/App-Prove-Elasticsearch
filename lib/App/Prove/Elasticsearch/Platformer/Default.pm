# ABSTRACT: Determine the platform of the system under test via Sys::Info::OS for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Platformer::Default

package App::Prove::Elasticsearch::Platformer::Default;

use strict;
use warnings;
use utf8;

use Sys::Info::OS;

sub get_platforms {
    return [ Sys::Info::OS::get_os(), $^V ]
}
