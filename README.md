# App-Prove-Elasticsearch (ape)

<img alt="TravisCI Build Status" src="https://travis-ci.org/teodesian/App-Prove-Elasticsearch.svg"></img>
<a href='https://coveralls.io/r/teodesian/App-Prove-Elasticsearch?branch=build%2Fmaster'><img src='https://coveralls.io/repos/teodesian/App-Prove-Elasticsearch/badge.svg?branch=build%2Fmaster' alt='Coverage Status' /></a>
<a href="https://cpants.cpanauthors.org/dist/App-Prove-Elasticsearch"><img alt="kwalitee" src="https://cpants.cpanauthors.org/dist/App-Prove-Elasticsearch.png"></img></a>


A Plugin to upload test results to Elasticsearch in real time, a program `ape` allowing command-line test management, and persistent testing daemon `testd`.

Has a pluggable archetechure, and a variety of built-in ways to gather information about the system under test.

Built-in Kibana dashboards to visualize the data are in /dashboards.

Can be configured using an INI file in your home directory, "elastest.conf"

When run with no configuration it assumes you want to test things like they are a CPAN perl distribution.
One of the intentions here is to possibly be a next-gen storage backend for a CPANTesters type tool.

Practical Use Case: End to end automatically scaling CI
========================================================

Suppose you have an orchestration service such as OpenStack Heat,
A rabbitmq server somewhere,
A continuous integration platform such as Jenkins linked to your repo, and
A CPAN module you want to test.

You would first build an appropriate elastest.conf based primarily on what system platforms you need supporting your system under test (SUT).
You would also configure it how to communicate with your rabbitmq server.

Next, you would put said configuration and this module on VM images, and ensure bin/testd was running on startup.
You would then configure heat to ensure you had adequate testing resources for all relevant platforms at all times.

Finally, setup your jenkins test plan for the repository to create test plans for all your relevant platforms using bin/testplan.
The jenkins plan would then simply wait until it observed the plan was complete with bin/testplan --show, or a 'NOT OK' result occurred in the output.

bin/testd is capable of splitting up testing jobs amongst many hosts via rabbit;  You could even improve Scaling and resource usage efficiency by using Heat's auto-scaling mechanisms via telemetry.

Practical Use Case: Replace usage of test management system
============================================================

One of the primary goals of this software was to allow usage of Git + App::Prove::Elasticsearch + ES & Kibana in lieu of a Test Management System.
I was drowning in data, and all existing test management systems (at the time of this writing) were database applications.
As such, I needed more flexibility if I was to discover higher order phenomenon in our test results such as:

* What systems were 'defect attractors' e.g. they regressed most frequently
* What tests need most improvement (high false positive rate)
* Trends in single and aggregate test runtime
* Searching for error messages which exist across multiple subsystems

The way this can be accomplished using our tools, but while still having the power of a full-fledged test management system is simple:

* Use Git as your test tracker and versioner.  This will allow full history of both manual and automated tests.
* Use bin/testplan to both plan test runs, and report the results.
* Run manual tests using bin/manualtest
* Associate test results with defects in trackers via bin/associate_test_result
* View and create dashboards in kibana (or use the built-ins with this module) to view interesting higher-order test phenomena.

This allows more flexibility than traditional test management software; your tests can be in any file format you want;
as long as you instruct prove how to use them (or run them with manualtest), ES will accept the results.
Any editor can be used, maximizing test author productivity.

Furthermore, as this is an entirely command line system, wrapping it with interfaces and additional automation should be straightforward.

See <a href="https://github.com/teodesian/App-Prove-Elasticsearch/blob/master/doc/Test_Management.md">doc/Test_Management.md</a> for more details.

Plugins
=========

App::Prove::Elasticsearch::Indexer -
* Subclass to send results to other indexes via simply changing a variable
* Subclass to extend the information being indexed for use later
* Subclass to use other storage engines that aren't even elasticsearch
* And, if the subclasses is named like App::Prove::Elasticsearch::Indexer::MyClassName, you can load them with `prove -Pindexer=MyClassName`

We also provide various alternative indexers:
* DzilDist: names your ES index after what your distribution is named in dist.ini
* MMDist: does the same, but picks the dist name out of Makefile.PL

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

Testd Plugins
=============
App::Prove::Elasticsearch::Provisioner - Used to setup system state before execution of tests.  Multiple can be used via elastest.conf
* Git - Checks out a branch which is assumed to be available in your $CWD where you execute tests.
* Perl - Use PerlBrew to execute the tests using different perls.

App::Prove::Elasticsearch::Binner - Sort the tests to run into "bins" which each have their own set of provisioners to run.
Multiple binners may be used to subdivide into many sub-bins; however be aware many bins necessarily imply more overhead to test execution.
* Isolation - Use Yath style HARNESS-CATEGORY-ISOLATION directive in tests to force these tests to run sequentially before all other tests.
* ExecutionTime - Examine ES data on duration to try to sort bins to minimize total run-time.
* RedMeat - Examine ES data to run tests that fail the most first.  Useful for smokers that stop immediately on failure.

Bins are subdivided in the order passed.  For example, Isolation,ExecutionTime,RedMeat would mean there is:
* An Isolate and Normal bin
* with ExecutionTime bins minimizing total runtime of all tests in each containing Isolate or Normal bin
* with RedMeat bins in front of Normal bins in each containing ExecutionTime bin.

