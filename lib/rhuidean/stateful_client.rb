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
    attr_reader :casemapping, :channels, :channel_modes, :eventq, :status_modes
    attr_reader :users

    def initialize
        # StatefulChannels keyed by channel name
        @channels = IRCHash.new(:rfc)

        # Known channel types, from RPL_ISUPPORT
        @channel_types = %w(# &)

        # Additional channel modes from RPL_ISUPPORT
        @channel_modes = {}

        # Additional status modes we get from RPL_ISUPPORT
        @status_modes = {}

        # StatefulUsers we know about, keyed by nickname
        @users = IRCHash.new(:rfc)

        super
    end

    ######
    public
    ######

    def add_user(user)
        @users[user.nickname] = user
    end

    def delete_user(user)
        if user.class == String
            @users.delete(user)
        elsif user.class == StatefulUser
            @users.delete(user.nickname)
        else
            nil
        end
    end

    #######
    private
    #######

    PREFIX_RE = /^\((\w+)\)(.*)$/

    def set_default_handlers
        on(:dead) do
            @channels.clear
            @users.clear
        end

        on(Numeric::RPL_ISUPPORT) { |m| do_rpl_isupport(m) }

        on(:JOIN) { |m| do_join(m) }
        on(:PART) { |m| do_part(m) }
        on(:NICK) { |m| do_nick(m) }
        on(:KICK) { |m| do_kick(m) }
        on(:QUIT) { |m| do_quit(m) }

        # Parse and sync channel modes
        on(:MODE) do |m|
            next unless @channel_types.include?(m.target[0])
            @channels[m.target].parse_modes(m.params[0], m.params[1..-1])
        end

        # Parse reply from MODE
        on(Numeric::RPL_CHANNELMODEIS) do |m|
            @channels[m.params[0]].parse_modes(m.params[1], m.params[2..-1])
        end

        # Sync current users in channel
        on(Numeric::RPL_NAMEREPLY) { |m| do_rpl_namereply(m) }

        super
    end

    def do_rpl_isupport(m)
        supported = []

        m.params.each { |param| supported << param.split('=') }

        supported.each do |name, value|
            case name

            # CASEMAPPING=rfc1459
            when 'CASEMAPPING'
                if value == "rfc1459"
                    @casemapping = :rfc
                    @channels    = IRCHash.new(:rfc)
                    @users       = IRCHash.new(:rfc)
                elsif value == "ascii"
                    @casemapping = :ascii
                    @channels    = IRCHash.new(:ascii)
                    @users       = IRCHash.new(:ascii)
                end

            # CHANMODES=eIb,k,l,imnpst
            # Fields are: list param, always param, param when +, no param
            when 'CHANMODES'
                listp, alwaysp, setp, nop = value.split(',')

                @channel_modes[:list]   = listp.split('')
                @channel_modes[:always] = alwaysp.split('')
                @channel_modes[:set]    = setp.split('')
                @channel_modes[:bool]   = nop.split('')

            # CHANTYPES=&#
            when 'CHANTYPES'
                @channel_types = value.split('')

            # PREFIX=(ov)@+
            when 'PREFIX'
                m = PREFIX_RE.match(value)
                modes, prefixes = m[1], m[2]

                modes    = modes.split('')
                prefixes = prefixes.split('')

                modes.each_with_index do |m, i|
                    @status_modes[m] = prefixes[i]
                end
            end
        end
    end

    def do_join(m)
        # Track channels
        if m.origin_nick == @nickname
            @channels[m.target] = StatefulChannel.new(m.target, self)
            mode(m.target) # Get the channel modes
        else
            nick = m.origin_nick
            user = @users[nick] || StatefulUser.new(nick, self)
            @users[user.nickname] ||= user

            @channels[m.target].add_user(user)
            debug("join: #{user} -> #{m.target}")
        end
    end

    def do_part(m)
        # Track channels
        if m.origin_nick == @nickname
            chan = @channels[m.target]

            # We can't see if they're in the channel we parted
            chan.users.each { |n, user| user.part_channel(chan) }

            # If we have users in no channels they must die
            @users.delete_if { |n, user| user.channels.empty? }

            @channels.delete(chan.name)

            debug("parted: #{chan.name}")
        else
            user = @users[m.origin_nick]

            @channels[m.target].delete_user(user)
            debug("part: #{user.nickname} -> #{m.origin_nick}")

            delete_user(user) if user.channels.empty?
        end
    end

    def do_nick(m)
        user = @users[m.origin_nick]
        user.nickname = m.target
        @users[m.target] = user
        @users.delete(m.origin_nick)
    end

    def do_kick(m)
        # Track channels
        if m.params[0] == @nickname
            chan = @channels[m.target]

            # We can't see if they're in the channel we got kicked from
            chan.users.each { |n, user| user.part_channel(chan) }

            # If we have users in no channels they must die
            @users.delete_if { |n, user| user.channels.empty? }

            @channels.delete(chan.name)

            debug("kicked: #{chan.name}")
        else
            user = @users[m.params[0]]

            @channels[m.target].delete_user(user)
            debug("kick: #{user.nickname} -> #{m.origin_nick}")

            delete_user(user) if user.channels.empty?
        end
    end

    def do_quit(m)
        if m.origin_nick == @nickname
            @eventq.post(:dead)
        else
            user = @users[m.origin_nick]

            user.channels.each { |chan| chan.delete_user(user) }

            delete_user(user)
            debug("quit: #{user.nickname}")
        end
    end

    #
    # In the case of multiple status modes, we assume the ircd sends only
    # the uppermost (i.e.: @ when @+). My testing, even with stupid ircds
    # with a thousand modes, seems to support this.
    #
    def do_rpl_namereply(m)
        chan     = @channels[m.params[1]]
        names    = m.params[2..-1]
        names[0] = names[0][1..-1] # Get rid of leading ':'
        modes    = @status_modes.keys
        prefixes = @status_modes.values
        name_re  = /^([#{prefixes}])*(.+)/

        names.each do |name|
            m      = name_re.match(name)
            user   = @users[m[2]] || StatefulUser.new(m[2], self)
            prefix = m[1]

            @users[user.nickname] ||= user

            if prefix == '@'
                user.add_status_mode(:oper, chan)

            elsif prefix == '+'
                user.add_status_mode(:voice, chan)

            elsif prefixes.include?(prefix)
                smode = modes[prefixes.find_index(prefix)]
                user.add_status_mode(smode.to_sym, chan)
            end

            chan.add_user(user)
            debug("names: #{user} -> #{chan}")
        end
    end
end

end # module IRC

#
# So we don't have to do @channels[irc_downcase(name)] constantly
#
# This is technically broken.
# There's no easy way to keep casemapping state per-Client, and this
# makes it pick one casemapping for ALL Clients. No one class knows
# enough about anything to always know the state, so unless I add
# another layer of abstraction it'll have to stay this way...
#
class IRCHash < Hash
    def initialize(casemapping)
        @casemapping = casemapping

        super()
    end

    def [](key)
        key = irc_downcase(key)
        super(key)
    end

    def []=(key, value)
        key = irc_downcase(key)
        super(key, value)
    end

    def irc_downcase(string)
        if @casemapping == :rfc
            string.downcase.tr('{}|^', '[]\\~')
        else
            string
        end
    end
end

