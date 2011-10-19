    rhuidean: a small, powerful IRC client library

    Copyright (c) 2011 Eric Will <rakaur@malkier.net>
    Rights to this code are documented in doc/license.md

rhuidean -- a small, powerful IRC client library
================================================

This library is free but copyrighted software; see `doc/license.md`.

An example client is included in `./bin/rhubot`. You may use this, or base your
own code off of it. 

More information and code repositories can be found on [GitHub][].

[github]: http://github.com/malkier/rhuidean/

--------------------------------------------------------------------------------

Rhuidean is a library for IRC clients. It is an event-based system that allows
you to construct an IRC bot in a few lines of code by hooking into IRC events.

Ruby Support
------------

Rhuidean has been extensively tested with multiple Ruby implementations.
Rhuidean runs on all MRI / CRuby implementations, and will also run on Rubinius
and JRuby.

    |----------------+-----------|
    | implementation |  version  |
    |----------------|-----------|
    | mri / cruby    | 1.8.7     |
    | mri / yarv     | 1.9.2     |
    | mri / yarv     | 1.9.3     |
    | rubinius       | 1.2, 2.0  |
    | jruby          | 1.6.5     |
    |----------------+-----------|

Runtime Requirements
--------------------

This library has the following requirements:

    |------------+---------|
    | dependency | version |
    |------------|---------|
    | rubygems   | 1.8.0   |
    |------------+---------|

This library requires the following RubyGems:

    |---------+---------|
    | rubygem | version |
    |---------|---------|
    | rake    | 0.9.2   |
    |---------+---------|

Rake is required for testing and other automated tasks. It's probably already
installed with your Ruby distribution.

If you want to run the unit tests you'll also need to install riot:

    $ gem install riot
    $ rake test

Operating System Support
------------------------

Rhuidean will probably run anywhere that Ruby will run. The library is written
primarily on Mac OS X 10.7.2, and frequently tested on FreeBSD 8.2 and
Linux 2.6.37.2. If you have any trouble running the library that you think is
operating system related, please file an [issue][] on [GitHub][].

Credits
-------

This library is completely original. I'm sure to receive patches from other
contributors from time to time, and this will be indicated in SCM commits.

    |----------------+----------+--------------------+-------------------------|
    |      role      | nickname |      realname      |      email address      |
    |----------------|----------|--------------------|-------------------------|
    | Lead Developer | rakaur   | Eric Will          | rakaur@malkier.net      |
    | Developer      | andrew   | Andrew Herbig      | goforit7arh@gmail.com   |
    |----------------+----------+--------------------+-------------------------|

Contact and Support
-------------------

We're not promising any hard and fast support, but we'll try to do our best.
This is a hobby and we've enjoyed it, but we have real lives with real jobs and
real families. We cannot devote major quantities of time to this.

With that said, our email addresses are listed above. If you prefer real-time
you can try IRC. We run an extremely small privateish network at
irc.malkier.net, #malkier.

If you have a bug feel free to drop by IRC or what have you, but we'll probably
just ask you to file an [issue][] on [GitHub][]. Please provide any output you
have, such as a backtrace. Please provide the steps we can take in order to
reproduce this problem, if possible. Feature requests are welcome and can be
filed in the same manner.

If you've read this far, congratulations. You are among the few elite people
that actually read documentation. Thank you.

[issue]: https://github.com/rakaur/rhuidean/issues
