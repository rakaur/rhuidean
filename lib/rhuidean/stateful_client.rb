#
# rhuidean: a small, lightweight IRC client library
# lib/rhuidean/stateful_client.rb: state-keeping IRC::Client
#
# Copyright (c) 2003-2010 Eric Will <rakaur@malkier.net>
#
 
# Import required app modules
%w(stateful_channel stateful_user).each { |m| require 'rhuidean/' + m }

module IRC

class StatefulClient < Client
    attr_reader :channels

    def initialize
        @channels = []

        super
    end

    #######
    private
    #######

    def find_channel(name)
        @channels.find { |c| c.name == name }
    end

    def set_default_handlers
        on(:JOIN) do |m|
            # Track channels
            if m.origin_nick == @nickname
                @channels << StatefulChannel.new(m.target, @eventq)
            else
                user = StatefulUser.new(m.origin_nick)
                find_channel(m.target).add_user(user)
                debug("join: #{user.inspect} -> #{m.target}")
            end
        end

        on(:PART) do |m|
            # Track channels
            if m.origin_nick == @nickname
                @channels.delete_if { |c| c.name == m.target }
            else
                find_channel(m.target).delete_user(m.origin_nick)
                debug("part: #{m.target} -> #{m.origin_nick}")
            end
        end

        on(:KICK) do |m|
            # Track channels
            if m.params[0] == @nickname
                @channels.delete_if { |c| c.name == m.target }
            else
                find_channel(m.target).delete_user(m.params[0])
                debug("kick: #{m.target} -> #{m.params[0]}")
            end
        end

        on(:MODE) do |m|
            chan = @channels.find { |c| c.name == m.target }
            chan.parse_modes(m.target, m.params[0], m.params[1..-1])
        end

        super
    end
end

end # module IRC

