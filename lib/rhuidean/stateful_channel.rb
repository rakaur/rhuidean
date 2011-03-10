#
# rhuidean: a small, lightweight IRC client library
# lib/rhuidean/stateful_channel.rb: state-keeping IRC channel
#
# Copyright (c) 2003-2011 Eric Will <rakaur@malkier.net>
#

# Import required app modules
%w(stateful_client stateful_user).each { |m| require 'rhuidean/' + m }

module IRC

##
# Represents a channel on IRC.
#
class StatefulChannel

    ##
    # instance attributes
    attr_reader :modes, :name, :users

    ##
    # Creates a new +StatefulChannel+.
    # The channel has an +EventQueue+, but it really points to the EventQueue of
    # the +StatefulClient+ that created it. This kind of breaks OOP,
    # but it allows the Channel to post relevant events back to the client,
    # like mode changes.
    # ---
    # name:: the name of the channel
    # client:: the +IRC::Client+ that sees us
    # returns:: +self+
    #
    def initialize(name, client)
        # The Client we belong to
        @client = client

        # The channel's key
        @key = nil

        # The channel's user limit
        @limit = 0

        # The channel's modes
        @modes = []

        # The name of the channel, including the prefix
        @name = name

        # The list of StatefulUsers on the channel keyed by nickname
        @users = IRCHash.new(@client.casemapping)
    end

    ######
    public
    ######

    #
    # Represent ourselves in a string.
    # ---
    # returns:: our name
    #
    def to_s
        @name
    end

    #
    # Add a user to our userlist.
    # This also adds us to the user's channel list.
    # ---
    # user:: the +StatefulUser+ to add
    # returns:: +self+
    #
    def add_user(user)
        @users[user.nickname] = user
        user.join_channel(self)

        self
    end

    #
    # Remove a user from our userlist.
    # This also removes us from the user's channel list.
    # ---
    # user:: a +StatefulUser+ or the name of one
    # returns:: +self+ (nil on catastrophic failure)
    #
    def delete_user(user)
        if user.class == String
            @users[user].part_channel(self)
            @users.delete(user)

            self
        elsif user.class == StatefulUser
            user.part_channel(self)
            @users.delete(user.nickname)

            self
        else
            nil
        end
    end

    STATUS_MODES = { 'o' => :oper,
                     'v' => :voice }

    LIST_MODES   = { 'b' => :ban,
                     'e' => :except,
                     'I' => :invex }

    PARAM_MODES  = { 'l' => :limited,
                     'k' => :keyed }

    BOOL_MODES   = { 'i' => :invite_only,
                     'm' => :moderated,
                     'n' => :no_external,
                     'p' => :private,
                     's' => :secret,
                     't' => :topic_lock }

    #
    # Parse a mode string.
    # Update channel state for modes we know, and fire off events.
    # ---
    # m:: the IRC::Message object
    # modes:: the mode string
    # params:: an array of the params tokenized by space
    # returns:: nothing of consequence...
    #
    def parse_modes(m, modes, params)
        mode = nil # :add or :del

        modes.each_char do |c|
            flag, param = nil

            if c == '+'
                mode = :add
                next
            elsif c == '-'
                mode = :del
                next
            end

            # Status modes
            if STATUS_MODES.include?(c)
                flag  = STATUS_MODES[c]
                param = params.shift

            # Status modes from RPL_ISUPPORT
            elsif @client.status_modes.keys.include?(c)
                flag  = c.to_sym
                param = params.shift

            # List modes
            elsif LIST_MODES.include?(c)
                flag  = LIST_MODES[c]
                param = params.shift

            # List modes from RPL_ISUPPORT
            elsif @client.channel_modes[:list].include?(c)
                flag  = c.to_sym
                param = params.shift

            # Always has a param (some send the key, some send '*')
            elsif c == 'k'
                flag  = :keyed
                param = params.shift
                @key  = mode == :add ? param : nil

            # Has a param when +, doesn't when -
            elsif c == 'l'
                flag   = :limited
                param  = params.shift if mode == :add
                @limit = mode == :add ? param : 0

            # Always has a param from RPL_ISUPPORT
            elsif @client.channel_modes[:always].include?(c)
                flag  = c.to_sym
                param = params.shift

            # Has a parm when +, doesn't when - from RPL_ISUPPORT
            elsif @client.channel_modes[:set].include?(c)
                flag  = c.to_sym
                param = params.shift if mode == :add

            # The rest, no param
            elsif BOOL_MODES.include?(c)
                flag = BOOL_MODES[c]

            # The rest, no param from RPL_ISUPPORT
            elsif @client.channel_modes[:bool].include?(c)
                flag = c.to_sym
            end

            # Add non-status and non-list modes to the channel's modes
            unless junk_cmode?(c)
                if mode == :add
                    @modes << flag
                else
                    @modes.delete(flag)
                end
            end

            # Update status modes for users
            if status_mode?(c)
                if mode == :add
                    @users[param].add_status_mode(flag, self)
                elsif mode == :del
                    @users[param].delete_status_mode(flag, self)
                end
            end

            # And send out events for everything
            event = "mode_#{flag.to_s}".to_sym
            @client.eventq.post(event, m, mode, param)
        end
    end

    #######
    private
    #######

    def status_mode?(modechar)
        return true if STATUS_MODES.include?(modechar)
        return true if @client.status_modes.keys.include?(modechar)
        return false
    end

    def junk_cmode?(modechar)
        return true if STATUS_MODES.include?(modechar)
        return true if LIST_MODES.include?(modechar)
        return true if @client.channel_modes[:list].include?(modechar)
        return true if @client.status_modes.keys.include?(modechar)
        return false
    end
end

end # module IRC
