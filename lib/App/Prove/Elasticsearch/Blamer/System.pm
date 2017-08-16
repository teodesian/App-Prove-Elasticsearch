# ABSTRACT: Determine the responsible party for tests via system user & hostname for upload to elasticsearch
# PODNAME: App::Prove::Elasticsearch::Blamer::Env

package App::Prove::Elasticsearch::Blamer::System;

use strict;
use warnings;
use utf8;

sub get_responsible_party {
    return getpwuid($<).'@'.gethostname();
}

1;
