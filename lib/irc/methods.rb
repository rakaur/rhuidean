#
# rhuidean: malkier irc services
# lib/irc/client.rb: IRC::Client class
#
# Copyright (c) 2004-2009 Eric Will <rakaur@malkier.net>
# Copyright (c) 2003-2004 shrike development team
#

module IRC

class Client
    ######
    public
    ######

    # Sends text directly to the server.
    def raw(message)
        @sendq << message
    end

    # IRC NICK command.
    def nick(nick)
        @sendq << "NICK #{nick}"
    end

    # IRC USER command.
    def user(username, server, host, realname)
        @sendq << "USER #{username} #{server} #{host} :#{realname}"
    end

    # IRC PASS command.
    def pass(password)
        @sendq << "PASS #{password}"
    end

    # IRC PRIVMSG command.
    def privmsg(to, message)
        @sendq << "PRIVMSG #{to} :#{message}"
    end

    # IRC NOTICE command.
    def notice(to, message)
        @sendq << "NOTICE #{to} :#{message}"
    end

    # IRC JOIN command.
    def join(channel)
        @sendq << "JOIN #{channel}"
    end

    # IRC PART command.
    def part(channel)
        @sendq << "PART #{channel}"
    end
end

end # module IRC
