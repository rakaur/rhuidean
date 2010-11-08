#
# rhuidean: a small, lightweight IRC client library
# lib/rhuidean/stateful_user.rb: state-keeping IRC user
#
# Copyright (c) 2003-2010 Eric Will <rakaur@malkier.net>
#
 
# Import required app modules
%w(stateful_client stateful_channel).each { |m| require 'rhuidean/' + m }

module IRC

class StatefulUser
    attr_reader   :channels, :modes
    attr_accessor :nickname

    def initialize(nickname, client)
        # The Client we belong to
        @client = client

        # StatefulChannels we're on, keyed by name
        @channels = IRCHash.new(@client.casemapping)

        # Status modes on channels, keyed by channel name (:oper, :voice)
        @modes = {}

        # The user's nickname
        @nickname = nickname
    end

    ######
    public
    ######

    def to_s
        @nickname
    end

    def join_channel(channel)
        @channels[channel.name] = channel
    end

    def part_channel(channel)
        @modes.delete(channel.name)
        @channels.delete(channel.name)
    end

    def add_status_mode(flag, channel)
        if channel.class == StatefulChannel then channel = channel.name end
        (@modes[channel] ||= []) << flag
    end

    def delete_status_mode(flag, channel)
        if channel.class == StatefulChannel then channel = channel.name end
        return unless @modes[channel]
        @modes[channel].delete(flag)
    end
end

end # module IRC

