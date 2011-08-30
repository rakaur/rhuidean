rhuidean -- a small, lightweight IRC client library
===================================================

This program is free but copyrighted software; see the LICENSE file.

Information and repositories can be found on [GitHub][].

[github]: http://github.com/rakaur/rhuidean/

TABLE OF CONTENTS
-----------------
  1. Credits
  2. Installation
  3. Contact and support

1\. CREDITS
-----------

Rhuidean is not based on any other code. I wrote the majority of it in a
single day as a way to try out a Ruby-based event system and as an exercise
writing in The Ruby Way. As such, rhuidean's code is very clean and concise,
and it also offers clever ways of accomplishing basic and advanced tasks.

Reference implementations can be found in [rhubot][] and [rhuhub][].

[rhubot]: http://github.com/rakaur/rhubot/
[rhuhub]: http://github.com/rakaur/rhuhub/

The current active development/maintenance is done by:

- rakaur, Eric Will <rakaur@malkier.net>

Almost all of the testing was also done by me, with help from:

- sycobuny, Stephen Belcher <sycobuny@malkier.net>
- dKingston, Michael Rodriguez <dkingston@malkier.net>

And others on irc.malkier.net.

2\. INSTALLATION
----------------

This should be as simple as:

    $ gem install rhuidean

If you're installing from the development repository, you may build a gem
based on the current code and install it by doing:

    $ rake gem
    $ gem install pkg/rhuidean-*.gem

There's just not much else to it.

3\. CONTACT AND SUPPORT
-----------------------

For bug or feature reports, please use GitHub's [issue tracking][1].

[1]: http://github.com/rakaur/rhuidean/issues/

If you're reporting a bug, please include information on how to reproduce the
problem. If you can't reproduce it there's probably nothing we can do. If the
library crashed, be sure to include Ruby's backtrace information.

If your problem requires extensive debugging in a real-time situation, you
can usually find us on irc.malkier.net in #malkier.

If you've read this far, congratulations. You are among the few elite people
that actually read documentation. Thank you.

