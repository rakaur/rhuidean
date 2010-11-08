#
# rhuidean: a small, lightweight IRC client library
# lib/rhuidean/client.rb: IRC::Client class
#
# Copyright (c) 2003-2010 Eric Will <rakaur@malkier.net>
#

module IRC

#
# These methods are shortcuts for sending data to the IRC
# server. You can use `raw` to do any of them, or even add
# a string directly to `@sendq` if you really want. I'm sure
# I haven't thought of everything here.
#
class Client
    ######
    public
    ######

    # Sends text directly to the server.
    def raw(message)
        @sendq << message
    end

    # Sends an IRC NICK command.
    def nick(nick)
        @sendq << "NICK #{nick}"
    end

    # Sends an IRC USER command.
    def user(username, server, host, realname)
        @sendq << "USER #{username} #{server} #{host} :#{realname}"
    end

    # Sends an IRC PASS command.
    def pass(password)
        @sendq << "PASS #{password}"
    end

    # Sends an IRC PRIVMSG command.
    def privmsg(to, message)
        @sendq << "PRIVMSG #{to} :#{message}"
    end

    # Sends an IRC NOTICE command.
    def notice(to, message)
        @sendq << "NOTICE #{to} :#{message}"
    end

    # Sends an IRC JOIN command.
    def join(channel, key = '')
        @sendq << "JOIN #{channel} #{key}"
    end

    # Sends an IRC PART command.
    def part(channel, message = '')
        @sendq << "PART #{channel} :#{message}"
    end

    # Sends an IRC KICK command.
    def kick(channel, target, reason = '')
        @sendq << "KICK #{channel} #{target} :#{reason}"
    end

    # Sends an IRC TOPIC command.
    def topic(target, new = '')
        @sendq << "TOPIC #{target} :#{new}"
    end

    # Sends an IRC MODE command.
    def umode(mode)
        @sendq << "MODE #@nickname #{mode}"
    end

    # Sends an IRC MODE command.
    def mode(target, mode = '')
        @sendq << "MODE #{target} #{mode}"
    end

    # Sends an IRC INVITE command.
    def invite(target, channel)
        @senq << "INVITE #{target} #{channel}"
    end

    # Send an IRC QUIT command.
    def quit(message = '')
        @sendq << "QUIT :#{message}"
    end
end

end # module IRC

