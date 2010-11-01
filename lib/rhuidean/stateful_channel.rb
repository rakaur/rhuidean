#
# rhuidean: a small, lightweight IRC client library
# lib/rhuidean/stateful_channel.rb: state-keeping IRC channel
#
# Copyright (c) 2003-2010 Eric Will <rakaur@malkier.net>
#

# Import required app modules
%w(stateful_client stateful_user).each { |m| require 'rhuidean/' + m }

module IRC

class StatefulChannel
    attr_reader :modes, :name

    #
    # Makes a new Channel that keeps track of itself.
    # The channel has an EventQueue, but it really points to the EventQueue of
    # the IRC::StatefulClient that created it. This kind of breaks OOP,
    # but it allows the Channel to post relevant events back to the client,
    # like mode changes.
    #
    def initialize(name, eventq)
        # Our EventQueue
        @eventq = eventq

        # The channel's key
        @key = nil

        # The channel's user limit
        @limit = 0

        # The channel's modes
        @modes = []

        # The name of the channel, including the prefix
        @name = name

        # The list of StatefulUsers on the channel
        @users = []
    end

    ######
    public
    ######

    def add_user(user)
        @users << user
    end

    def delete_user(user)
        if user.class == String
            user = find_user(user)
        end

        return nil if not user

        @users.delete(user)
    end

    def find_user(nickname)
        @users.find { |u| u.nickname == nick }
    end

    def to_s
        @name
    end

    STATUS_MODES = { 'b' => :ban,
                     'e' => :except,
                     'I' => :invex,
                     'o' => :oper,
                     'v' => :voice }

    PARAM_MODES  = { 'l' => :limited,
                     'k' => :keyed }

    BOOL_MODES   = { 'i' => :invite_only,
                     'm' => :moderated,
                     'n' => :no_external,
                     'p' => :private,
                     's' => :secret,
                     't' => :topic_lock }

    def parse_modes(chan, modes, params)
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
            end

            # Always has a param (some send the key, some send '*')
            if c == 'k'
                flag  = :keyed
                param = params.shift
                @key  = mode == :add ? param : nil
            end

            # Has a param when +, doesn't when -
            if c == 'l'
                flag   = :limited
                param  = params.shift if mode == :add
                @limit = mode == :add ? param : 0
            end

            # And the rest
            if BOOL_MODES.include?(c)
                flag = BOOL_MODES[c]
            end

            # Okay, now add non-status modes to the channel's modes
            if BOOL_MODES.include?(c) or PARAM_MODES.include?(c)
                if mode == :add
                    @modes << flag
                else
                    @modes.delete(flag)
                end
            end

            # And send out events for everything else
            event = "mode_#{flag.to_s}".to_sym
            @eventq.post(event, chan, mode, param)
        end
    end
end

end # module IRC
