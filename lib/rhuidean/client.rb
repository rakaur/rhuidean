#
# rhuidean: a small, lightweight IRC client library
# lib/rhuidean/client.rb: IRC::Client class
#
# Copyright (c) 2003-2010 Eric Will <rakaur@malkier.net>
#

# Import required Ruby modules.
%w(logger socket).each { |m| require m }

module IRC

# The IRC::Client class acts as an abstract interface to the IRC protocol.
class Client
    ##
    # constants
    VERSION = '0.2.4'

    ##
    # instance attributes
    attr_accessor :server,   :port,     :password, :debug, :thread,
                  :nickname, :username, :realname, :bind_to

    # Our TCPSocket.
    attr_reader   :socket, :channels

    # A simple Exeption class.
    class Error < Exception
    end

    #
    # Creates a new IRC::Client object. If there is a block given, passes
    # itself to the block for pretty attribute setting.
    # ---
    # <tt>client = IRC::Client.new do |c|
    #     c.server   = 'irc.malkier.net'
    #     c.port     = 6667
    #     c.password = 'partypants'
    #     c.nickname = 'rakaur'
    #     c.username = 'rakaur'
    #     c.realname = 'watching the weather change'
    #     c.bind_to  = '10.0.1.20'
    #
    #     c.logger    = Logger.new($stderr)
    #     c.debug     = false
    # end
    #
    # client.thread = Thread.new { client.io_loop }
    # clients.each { |client| client.thread.join }
    # [...]
    # client.quit("IRC quit message!")
    # client.exit
    # ---
    # returns:: +self+
    #
    def initialize
        # Is our socket dead?
        @dead      = false
        @connected = false

        # List of channels we're on
        @channels = []

        # Received data waiting to be parsed.
        @recvq = []

        # Data waiting to be sent.
        @sendq = []

        # Our event queue.
        @eventq = EventQueue.new

        # Our Logger object.
        @logger  = Logger.new($stderr)
        @debug   = false

        # If we have a block let it set up our instance attributes.
        yield(self) if block_given?

        # Core events which are needed to work at all.
        on(:read_ready)  { read  }
        on(:write_ready) { write }
        on(:recvq_ready) { parse }

        on(:dead) { self.dead = true }

        on(:exit) do |from|
            log("exiting via #{from}...")
            Thread.exit
        end

        on(:PING) { |m| raw("PONG :#{m.target}") }

        # Set up event handlers. These track some state and such, and can
        # be overridden for other functionality in any child classes.
        set_default_handlers

        # Special method for default CTCP replies
        # I use this so they don't get wiped out when someone overrides
        # the default handlers, but also so that they CAN be wiped out.
        set_ctcp_handlers

        self
    end

    #######
    private
    #######

    #
    # Sets up some default event handlers to track various states and such.
    # ---
    # returns:: +self+
    #
    def set_default_handlers
        # Consider ourselves connected on 001
        on(Numeric::RPL_WELCOME) { log("connected to #@server:#@port") }

        # Track our nickname...
        on(:NICK) { |m| @nickname = m.target if m.origin_nick == @nickname }

        # Track channels
        on(:JOIN) { |m| @channels << m.target if m.origin_nick == @nickname }

        on(:PART) do |m|
            @channels.delete(m.target) if m.origin_nick == @nickname
        end

        on(:KICK) { |m| @channels.delete(m.target) if m.params[0] == @nickname }

        self
    end

    #
    # Sets up some default CTCP replies.
    # ---
    # returns:: +self+
    #
    def set_ctcp_handlers
        on(:PRIVMSG) do |m|
            case m.ctcp
            when :ping
                notice(m.origin_nick, "\1PING #{m.params.join(' ')}\1")
            when :version
                v_str = "rhuidean-#{VERSION}"
                notice(m.origin_nick, "\1VERSION #{v_str}\1")
            when :clientinfo
                notice(m.origin_nick, "\1CLIENTINFO 114 97 107 97 117 114\1")
            else
                next
            end
        end
    end

    #
    # Verifies all required attributes are set.
    # ---
    # raises:: IRC::Client::Error if tests fail
    # returns:: +self+ if tests pass
    #
    def verify_attributes
        raise(Error, 'need a server to connect to')     unless server
        raise(Error, 'need a port to connect to')       unless port
        raise(Error, 'need a nickname to connect with') unless nickname
        raise(Error, 'need a username to connect with') unless username
        raise(Error, 'need a realname to connect with') unless realname

        self
    end

    #
    # Takes care of setting some stuff when we die.
    # ---
    # bool:: +true+ or +false+
    # returns:: +nil+
    #
    def dead=(bool)
        if bool == true
            log("lost connection to #@server:#@port")
            @dead      = Time.now.to_i
            @socket    = nil
            @connected = false
        end
    end

    #
    # Called when we're ready to read.
    # ---
    # returns:: +self+
    #
    def read
        begin
            ret = @socket.readpartial(8192)
        rescue Errno::EAGAIN
            retry
        rescue Errno::ETIMEDOUT, EOFError
            ret = nil # Dead
        end

        unless ret
            @eventq.post(:dead)
            return
        end

        # This passes every "line" to our block, including the "\n".
        ret.scan(/(.+\n?)/) do |line|
            line = line[0]

            # If the last line had no \n, add this one onto it.
            if @recvq[-1] and @recvq[-1][-1].chr != "\n"
                @recvq[-1] += line
            else
                @recvq << line
            end
        end

        if @recvq[-1] and @recvq[-1][-1].chr == "\n"
            @eventq.post(:recvq_ready)
        end

        self
    end

    #
    # Called when we're ready to write.
    # ---
    # returns:: +self+
    #
    def write
        begin
            # Use shift because we need it to fall off immediately.
            while line = @sendq.shift
                line += "\r\n"
                debug(line)
                @socket.write(line)
            end
        rescue Errno::EAGAIN
            retry
        end
    end

    # Note that this doesn't match *every* IRC message,
    # just the ones we care about. It also doesn't match
    # every IRC message in the way we want. We get what
    # we need. The rest is ignored.
    #
    # Here's a compact version if you need it:
    #     ^(?:\:([^\s]+)\s)?(\w+)\s(?:([^\s\:]+)\s)?(?:\:?(.*))?$

    IRC_RE = /
             ^              # beginning of string
             (?:            # non-capturing group
                 \:         # if we have a ':' then we have an origin
                 ([^\s]+)   # get the origin without the ':'
                 \s         # space after the origin
             )?             # close non-capturing group
             (\w+)          # must have a command
             \s             # and a space after it
             (?:            # non-capturing group
                 ([^\s\:]+) # a target for the command
                 \s         # and a space after it
             )?             # close non-capturing group
             (?:            # non-capturing group
                 \:?        # if we have a ':' then we have freeform text
                 (.*)       # get the rest as one string without the ':'
             )?             # close non-capturing group
             $              # end of string
             /x

    #
    # Parse any incoming data and generate IRC events.
    # ---
    # returns:: +self+
    #
    def parse
        @recvq.each do |line|
            line.chomp!

            debug(line)

            m = IRC_RE.match(line)

            origin  = m[1]
            command = m[2]
            target  = m[3]
            params  = m[4]

            if params and not target
                target = params
                params = nil
            end

            params &&= params.split

            msg = Message.new(self, line, origin, target, params)

            @eventq.post(command.upcase.to_sym, msg)
        end

        @recvq.clear

        self
    end

    ######
    public
    ######

    #
    # Registers Event handlers with our EventQueue.
    # ---
    # <tt>c.on(:PRIVMSG) do |m|
    #     next if m.params.empty?
    #     if m.params =~ /\.die/ and m.origin == my_master
    #         c.quit(params)
    #         c.exit
    #     end</tt>
    # ---
    # event:: name of the event as a Symbol
    # block:: block to call when Event is posted
    # returns:: self
    #
    def on(event, &block)
        @eventq.handle(event, &block)

        self
    end

    #
    # Schedules input/output and runs the EventQueue.
    # ---
    # returns:: never, thread dies on +:exit+
    #
    def io_loop
        loop do
            if dead?
                sleep(30)
                connect
                next
            end

            connect unless connected?

            # Run the event loop. These events will add IO, and possibly other
            # events, so we keep running until it's empty.
            @eventq.run while @eventq.needs_ran?

            next if dead?

            writefd = [@socket] unless @sendq.empty?

            ret = IO.select([@socket], writefd, [], 10)

            next unless ret

            @eventq.post(:read_ready)  unless ret[0].empty?
            @eventq.post(:write_ready) unless ret[1].empty?
        end
    end

    #
    # Is the socket dead?
    # ---
    # returns:: +true+ or +false+
    #
    def dead?
        @dead
    end

    #
    # Are we connected?
    # ---
    # returns:: +true+ or +false+
    #
    def connected?
        @connected
    end

    #
    # Creates and connects our socket.
    # ---
    # returns:: +self+
    #
    def connect
        verify_attributes

        log("connecting to #@server:#@port")

        begin
            @socket = TCPSocket.new(@server, @port, @bind_to)
        rescue Exception => err
            @eventq.post(:dead)
        end

        @dead      = false
        @connected = true

        pass(@password) if @password
        nick(@nickname)
        user(@username, @server, @server, @realname)
    end

    #
    # Logs a regular message.
    # ---
    # message:: the string to log
    # returns:: +self+
    #
    def log(message)
        @logger.info(caller[0].split('/')[-1]) { message } if @logger
    end

    #
    # Logs a debug message.
    # ---
    # message:: the string to log
    # returns:: +self+
    #
    def debug(message)
        return unless @logger

        @logger.debug(caller[0].split('/')[-1]) { message } if @debug
    end

    #
    # Sets the logging object to use.
    # If it quacks like a Logger object, it should work.
    # ---
    # logger:: the Logger to use
    # returns:: +self+
    #
    def logger=(logger)
        @logger = logger

        # Set to false/nil to disable logging...
        return unless @logger

        @logger.progname        = 'irc'
        @logger.datetime_format = '%b %d %H:%M:%S '

        # We only have 'logging' and 'debugging', so just set the
        # object to show all levels. I might change this someday.
        @logger.level = Logger::DEBUG
    end

    #
    # Forces the Client's Thread to die. If it's the main thread, the
    # application goes with it.
    # ---
    # returns:: nope!
    #
    def exit(from = 'exit')
        @eventq.post(:exit, from)
        @eventq.run
    end
end

# A simple data-holding class.
class Message
    ##
    # constants
    ORIGIN_RE = /^(.+)\!(.+)\@(.+)$/

    ##
    # instance attributes
    attr_reader :client, :ctcp, :origin, :params, :raw, :target
    attr_reader :origin_nick, :origin_user, :origin_host

    #
    # Creates a new Message. We use these to represent the old
    # style of (char *origin, char *target, char *parv[]) in C.
    #
    def initialize(client, raw, origin, target, params)
        @client, @ctcp, @origin = client, nil, origin
        @params, @raw,  @target = params, raw, target

        # Is the origin a user? Let's make this a little more simple...
        if m = ORIGIN_RE.match(@origin)
            @origin_nick, @origin_user, @origin_host = m[1..3]
        end

        # Reformat it a bit if it's a CTCP.
        if @params and not @params.empty? and @params[0][0] == "\1"
            @params[-1].chop!
            @ctcp = @params.shift[1 .. -1].downcase.to_sym
        end
    end

    ######
    public
    ######

    def to_channel?
        %w(# & !).include?(@target[0])
    end

    def is_ctcp?
        @ctcp
    end

    def is_action?
        @ctcp == :action
    end

    def is_dcc?
        @ctcp == :dcc
    end
end

end # module IRC

