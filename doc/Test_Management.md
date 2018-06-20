# Using `ape` and git to replace your test management system

Assumptions:
=============

* You plan & execute test runs with both automated and manual tests in your TMS
* You store manual test cases in your TMS
* You store automated tests in a source control system, such as Git
* You update test results after the fact to associate tracked defects
* You use a continuous integration system to execute your automated testing
* Your system under test (SUT) is tracked in your source control system (Git will be used as our example)
* Your SUT is deployed on multiple target environments, and must be tested on said environments.
* You use a web interface to view & review test plans and individual test results

Goals:
======

* Plan & execute test runs with both automated and manual tests using `ape test` and `prove -Pelasticsearch`
* Store all your manual tests alongside your automated tests in your source control system
    Added benefit of this is you can persistently link testing explanations used in your defect tracker to files in your source control.
* Update test results after the fact using `ape update`
* Distribute testing to split up the work currently done by your CI system, but still have results fed in there
* Do pairwise testing to reduce the testing load over your target environments

How To
=======

1. Import all your existing test results into ES.
    scripts/ has an importer for TestRail, but you should be able to modify to suit for your TMS.
    If you do so, feel free to submit your script as a pull request to help others.

2. Import all your manual test cases into Git.
    No script yet exists for this, but will soon for TestRail, see Issue #46.
    Again, feel free to contribute importers of your own.

3. Set up Elasticsearch and Kibana on a machine accessible to your testers.

4. Set up rabbitmq-server on a host, and create a user for use with testing.

5. Ensure that your testers and CI platform have an elastest.conf configured with something like the following in their $HOME:

`[server]`
`host=$ES_HOST`
`port=$ES_PORT`
`[client]`
`autodiscover=ByName`
`queue=Rabbit`
`provisioners=Git`
`versioner=Git`
`[queue]`
`host=$rabbit_host`
`user=$rabbit_user`
`password=$rabbit_pw`
`[testd]`
`max_workers=5`
`[runner]`
`args=-vm`
`[PlatformGroups]`
`Operating Systems = CentOS 7 64-bit,CentOS 6 32-bit`
`Browsers = Firefox,Chrome`

6. have `testd` running on some or all of your testers' machines.

You can now straightforwardly use `ape plan` to plan and run multi-platform test runs like so:

`ape plan --prompt --version origin/master --platform 'CentOS 7 64-bit' --platform 'CentOS 6 64-bit' --platform 'Firefox' --platform 'Chrome' --pairwise t/automated/* t/manual/*`

This will queue work something like this:

* Half the tests from t/automated/* t/manual/* (sorted randomly) executed with SUT version origin/master (whatever's latest in git), and installed on CentOS 6 64-bit on Firefox
* Half the tests from t/automated/* t/manual/* (sorted randomly) executed with SUT version origin/master (whatever's latest in git), and installed on CentOS 7 64-bit on Chrome

To integrate this with your continuous integration framework is as simple as calling the above plan method, and then waiting on the plan like so:

`ape plan --show --version origin/master --platform 'CentOS 7 64-bit' --platform 'CentOS 6 64-bit' --platform 'Firefox' --platform 'Chrome' --pairwise`

Your CI script would then do the following:
* Poll until No results printed remain 'UNTESTED'
* Poll until No results printed are 'NOT OK' (fail immediately)
* Otherwise the run passes.

The machines configured as testsers above with `testd` will then pick up the test jobs and execute them as quickly as is possible after re-configuring to the relevant SUT version.
For platforms such as operating systems which necessarily cannot be changed, the assumption is you use a service such as openstack heat to ensure your bases are covered RE testing environments.

To then finish executing the manual tests so that the plan will be complete, you would have a tester execute:

`ape test --status OK t/manual/test_that_passed.md`
`ape test --status 'NOT OK' t/manual/test_that_failed.txt`

Until you run out of manual tests to run.

Your build will then complete in your CI platform, and you can begin the process all over again.

7. Now that your testing is actually done, let's get down to the reason we're using elasticsearch at all: Kibana.

Import the built-in dashboards in /dashboards to get an idea of the sort of data you can see using this tool that are incredibly difficult to discern using a database TMS.

Here are some things you can do in the discover interface that are super useful:

* Search the full-text of test results for keywords trivially
* Easily see the version of the test when executed (in Git, this is a SHA you can check out directly)
* Drill down and only see results of a particular status easily
* Show tests only executed by particular executors (say, QA analysts, or a particular test host)
* Display test plan results much the same way as done in `ape plan` above using Lucene Queries via the 'discover interface:

(example using the results from testing this very module using this plugin):
`platform: "Ubuntu Linux 16.04 (kernel: 4.4.0-127-generic)"  AND "Perl 5.022001" AND version: "bf562d9feb3911a15c6533d696ce6afdf04687f3"`

<img src="https://github.com/teodesian/App-Prove-Elasticsearch/blob/master/doc/img/kibana_example.png" alt="example image" />

Executing automated tests directly
===================================

Using the above setup, it's as easy as:

`prove -PElasticsearch [switches] files`

That's it.

No perl, No Problem
====================
The perl `prove` utility is highly flexible in that it really only cares that what you execute emits TAP, so long as you tell it how to execute non perl tests using the --exec flag:
https://metacpan.org/pod/prove#-exec

Extending
==========
The framework for doing all this testing automatically has a lot of moving parts.
Examine the documentation here: https://metacpan.org/release/App-Prove-Plugin-Elasticsearch
for more details.
