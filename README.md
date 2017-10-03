# App-Prove-Plugin-Elasticsearch
A Plugin to upload test results to Elasticsearch in real time.

Has a pluggable archetechure, and a variety of built-in ways to gather information about the system under test.

Can be configured using an INI file in your home directory, "elastest.conf"

When run with no configuration it assumes you want to test things like they are a CPAN perl distribution.
One of the intentions here is to possibly be a next-gen storage backend for a CPANTesters type tool.

App::Prove::Elasticsearch::Indexer -
* Subclass to send results to other indexes via simply changing a variable
* Subclass to extend the information being indexed for use later
* Subclass to use other storage engines that aren't even elasticsearch
* And, if the subclasses is named like App::Prove::Elasticsearch::Indexer::MyClassName, you can load them with `prove -Pindexer=MyClassName`

App::Prove::Elasticsearch::Searcher::ByName - filters out tests with results already indexed on our SUT's platform & version.
* Subclass to filter out cases before they are sent to be run based on other criteria
* As with above, you can load App::Prove::Elasticsearch::Searcher::MyClassName with `prove -Psearcher=MyClassName`

App::Prove::Elasticsearch::Platformer:: - Multiple classes to determine the environment the SUT is installed on
* Default - Use Sys::Info::OS's info about your OS version, and your perl version as the operating environment
* Env     - Specify CSV describing your environment as $ENV{TESTSUITE_ENVIRONMENT}
* Subclass to integrate with your own automation stack, e.g. jenkins, travis, bamboo etc etc
* As usual, you can load App::Prove::Elasticsearch::Platformer::MyClassName with `prove -Pplatformer=MyClassName`

App::Prove::Elasticsearch::Versioner:: - Multiple classes to determine the version of the system under test (SUT).
* Default - check your distribution's CHANGES for the latest version of the system
* Git     - consider the latest SHA of your branch to be the latest version
* Env     - Specify a version string as $ENV{TESTSUITE_VERSION}
* As usual, subclass away and load custom classes via `prove -Pversioner=MyClassName`

App::Prove::Elasticsearch::Blamer:: - Multiple classes to determine who or what ran these tests
* Default - check your distribution's CHANGES file for an author of the latest version
* System  - user@hostname
* Git     - git's configured author.email on the system
* Env     - Specify a vversion string as $ENV{TESTSUITE_AUTHOR}
* As usual, subclass away and load custom classes via `prove -Pblamer=MyClassName

You can override test global statuses in the event of environmental failures, etc by printing a status like so:

% mark_status=SKIP

Inside the test.

If you use the status DISCARD, the test result will simply be omitted and not uploaded to the index.
