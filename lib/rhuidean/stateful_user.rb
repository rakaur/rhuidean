#
# rhuidean: a small, lightweight IRC client library
# lib/rhuidean/stateful_user.rb: state-keeping IRC user
#
# Copyright (c) 2003-2010 Eric Will <rakaur@malkier.net>
#
 
# Import required app modules
%w(stateful_client stateful_channel).each { |m| require 'rhuidean/' + m }

module IRC

#
# Represents a user on IRC. Each nickname should only have one of
# these objects, no matter how many channels they're in. If we can't
# see them in any channels they disappear.
#
class StatefulUser

    ##
    # instance attributes
    attr_reader   :channels, :modes
    attr_accessor :nickname

    ##
    # Creates a new +StatefulUser+.
    # ---
    # nickname:: the user's nickname, as a string
    # client:: the +IRC::Client+ that sees us
    # returns::+ self+
    #
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

    #
    # Represent ourselves in a string.
    # ---
    # returns:: our nickname
    #
    def to_s
        @nickname
    end

    #
    # Add a channel to our joined-list.
    # ---
    # channel:: the +StatefulChannel+ to add
    # returns:: +self+
    #
    def join_channel(channel)
        @channels[channel.name] = channel

        self
    end

    #
    # Remove a channel from our joined-list.
    # Also clears our status modes for that channel.
    # ---
    # channel:: the +StatefulChannel+ to remove
    # returns:: +self+
    #
    def part_channel(channel)
        @modes.delete(channel.name)
        @channels.delete(channel.name)

        self
    end

    #
    # Give us a status mode on a channel.
    # ---
    # flag:: +Symbol+ representing a mode flag
    # channel:: either a +StatefulChannel+ or the name of one
    # returns:: +self+
    #
    def add_status_mode(flag, channel)
        if channel.class == StatefulChannel then channel = channel.name end
        (@modes[channel] ||= []) << flag

        self
    end

    #
    # Take away a status mode on a channel.
    # ---
    # flag:: +Symbol+ representing a mode flag
    # channel:: either a +StatefulChannel+ or the name of one
    # returns:: +self+
    #
    def delete_status_mode(flag, channel)
        if channel.class == StatefulChannel then channel = channel.name end
        return unless @modes[channel]

        @modes[channel].delete(flag)

        self
    end
end

end # module IRC

