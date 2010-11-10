rhuidean -- a small, lightweight IRC client library
===================================================

This program is free but copyrighted software; see the LICENSE file.

Information and repositories can be found on [GitHub][].

[github]: http://github.com/rakaur/rhuidean/

EXAMPLES
---------

I tried to design the interface to the library to be as simple as possible,
but at some turns there's always going to be the complexity from the
underlying IRC protocol. While I took care in designing the API, you must
keep in mind that this is targeting programmers in the first place.

The best way to explain how to use the library is through examples.

There are two fundamental classes available for you to use for your program.
The first, `IRC::Client` simply connects to the specified server and fires off
events for all data it receives. The events are named by the protocol command
or the name of the numeric. It maintains the connection and does little else.
It knows nothing about the server except for the server name and port (no
channels, etc). The second, `IRC::StatefulClient` is much more useful. It
keeps state by default. It keeps track of what channels it's in, what users
are in those channels, the modes in those channels, and more. The second offers
a lot more built-in functionality and more granularity with the events (it
offers a different event for each mode flag, as opposed to just an event for
MODE, since it has to parse the modes anyway).

We'll start with `IRC::Client`. Anything done here can also be done with
`IRC::StatefulClient`, though, as long as you `require rhuidean/stateful_client`

    client = IRC::Client.new do |c|
        c.server   = "irc.example.com"
        c.port     = 6667
        c.password = "optional_password"

        c.nickname = "rhuidean-bot"
        c.username = "rhuidean"
        c.realname = "built by the Jenn Aiel"

        # These provide basic logging. Debug shows all network traffic.
        # Debug is true or false, logger is false or a Logger object.
        c.logger   = Logger.new($stdout)
        c.debug    = false
    end

Now you have an `IRC::Client`. You can use the client to listen to events so
that you can do things. We explore events in depth below. After you're finished
setting up event handlers, you'll want to actually start the Client's loop so
that it can connect and process information and run your event handlers.

To do this, you need only to call the `IRC::Client#io_loop` method. The
library generally assumes it's going to be in a thread, so that you can have
more than one `Client` at a time. A good way to do this is:

    client.thread = Thread.new { client.io_loop }

You can do whatever you like with the thread(s). Generally you'll want to
join them all to the main thread so that the interpreter doesn't exit. So,
whenever you're done and ready for your program to sit and loop, do something
along the lines of:

    client.thread.join

Any code below this will not be ran until the `Client`'s thread exits.

Now let's take a closer look at events.

For example, if you'd like to join a channel when it connects to the server,
a good way is to wait for the MOTD and then join:

    client.on(IRC::Numeric::RPL_ENDOFMOTD) { c.join("#example") }

Aside from numerics having funny names, it's pretty easy. If you'd like to
parse all joints, you can do:

    client.on(:JOIN) { |m| # parse... }

You can make as many handlers for the same event as you like. Generally, they
will be executed in the order you define them. You can listen for any protocol
command or any numeric (see lib/rhuidean/numeric.rb for a ful list).

Since this is the basic non-state-keeping client, if you want to know about
channel modes you'd have to parse them yourself:

    client.on(:MODE) { |m| # check to see it's a channel mode, not a umode... }

All these events pass your block an IRC::Message object. This contains all the
information about the IRC data you could want, including the raw data from the
IRC server if you really need it. You'll want to be very family with this
object, and although it's better documented in the rdoc documentation, I'll go
over it here.

    m.client       => the IRC::Client or IRC::StatefulClient it came from
                      good for doing m.client.join() and such

    m.origin       => server name or nick!user@host that sent the message
    m.origin_nick  => if the origin was a user, that user's nickname
    m.origin_user  => if the origin was a user, that user's username
    m.origin_host  => if the origin was a user, that user's hostname

    m.target       => the target, tends to be a user or channel

    m.params       => an array of the parameters, tokenized by space.
                      as a side effect, whitespace is compressed...

    m.to_channel?  => was the message to a channel? boolean
                      true if the first character is '#' or '&' or '!'

    m.ctcp         => if the message was a CTCP, the type of CTCP as a Symbol
    m.ctcp?        => was it a CTCP? boolean

    m.action?      => was it an ACTION? boolean
    m.dcc?         => was the CTCP a DCC request? boolean

There might be more, and some might be new. This isn't exhaustive. Check rdoc.

If you want to auto-op someone that joins:

    client.on(:JOIN) do |m|
        # Check to see if you should do the op
        client.mode(m.target, "+o #{m.origin_nick}")
    end

Pretty simple stuff.

It's worth noting that `IRC::StatefulClient` offers more events, particularly
in terms of channel modes. It keeps track of channel modes, and so must parse
them. As it does so it also sends off mode-specific events, like:

    client.on(:mode_secret) do |m, mode, param|
        if mode == :add
             client.privmsg(m.target, "We're hidden!")
        elsif mode == :del
            client.privmsg(m.target, "We're not hidden :(")
       end
    end

As you can see, these special mode events don't send the standard `IRC::Message`
object. `m` is that object , `mode` is :add or :del depending on if the
mode is being added or removed, and `param` is the parameter, if there is one.
In this case, there is not, but if it were :limited the param would be the
number it's limited to.

The names of the modes are as follows:

    o => :oper
    v => :voice
    b => :ban
    e => :except
    I => :invex
    l => :limited
    k => :keyed
    i => :invite_only
    m => :moderated
    n => :no_external
    p => :private
    s => :secret
    t => :topic_lock

Any additional, non-standard modes offered by other IRCds will be read from
the RPL_ISUPPORT numeric and taken into account. In this case, the events are
simply named `:mode_h` for mode flag 'h' (halfop, for example). If the IRCd
supports modes that it doesn't let us know about in RPL_ISUPPORT they will be
ignored, and this can lead to broken behavior. In particular, inspircd allows
operators to add and remove support for various modes at runtime, after we've
been sent RPL_ISUPPORT, and this will lead to broken behavior.

The library will take default modes into account first, and then check for
modes from RPL_ISUPPORT. Status modes are also supported, so long as the IRCd
tells us about them in PREFIX in RPL_ISUPPORT. Again, defaults are noted first.
If the IRCd sends multiple mode prefixes in RPL_NAMESREPLY things will break,
but my testing failed to find any IRCds that are dumb enough to do this.

Here's a brief overview of the interface to state in `IRC::StatefulClient`.
Obviously I can only go over so much, and if you really want to dig in take a
look at `lib/rhuidean/stateful_client.rb`, `stateful_channel.rb`, and
`stateful_user.rb`. You can't lose, there.

The `IRC::StatefulClient` keeps track of the channels it's in. These are
available from `IRC::StatefulClient#channels`. Each `IRC::StatefulUser` keeps
track of the `IRC::StatefulChannels` it's in. The `StatefulUsers` are
per-connection, not per-channel. They also keep note of their status modes.

    client.on(:PRIVMSG) do |m|
        chan = client.channels[m.target] # This is an IRC::StatefulChannel
        user = chan.users[m.origin_nick] # This is an IRC::StatefulUser

        user.modes[chan.name] # => [:oper, :voice]
        user.modes            # => { "#malkier" => [:oper, :voice] }
        user.channels         # => { "#malkier" => <IRC::StatefulChannel> }

        chan.modes            # => [:secret, :topic_lock, :no_external]
        chan.users            # => { "rakaur" => <IRC::StatefulUser>, ... }
    end

At the moment, the state-keeping does not include user modes. You can do so
yourself by listening for the raw MODE command, of course.

===

For further information see the rdoc documentation. This should do a pretty
good (and up-to-date!) job of documenting the code itself.

If you want to use events outside of the library's classes, feel free to take
a peak at `event.rb`. It's pretty straightforward and well-documented. I've
also included a small class that will execute code after X seconds or every N
seconds. If you might find this useful check out `timer.rb`, which is also
very straightfoward.

