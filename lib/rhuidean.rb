#
# rhuidean: malkier irc services
# lib/rhuidean.rb: contains the Rhuidean class
#
# Copyright (c) 2004-2009 Eric Will <rakaur@malkier.net>
# Copyright (c) 2003-2004 shrike development team
#

# Import required Ruby modules.
%w(logger optparse pp).each { |m| require m }

# Import required IRC modules.
require 'irc'

# The main application class.
class Rhuidean
    ##
    # constants

    # The project name.
    ME       = 'rhuidean'

    # The full version number.
    VERSION  = '1.0-alpha'

    # The codename for this major version.
    CODENAME = 'praxis'

    ##
    # class attributes

    # The logging object.
    @@logger = nil

    # Booleans for logging options.
    @@logging = true
    @@debug   = false

    # The list of all our clients.
    @@clients = []

    #
    # Creates a new Rhuidean object, which starts and runs the entire
    # application. Everything starts and ends here.
    # ---
    # returns:: +self+
    #
    def initialize
        # Check to see if we're running on ruby19.
        #if RUBY_VERSION < '1.9.1'
        #    puts "#{ME}: requires at least ruby 1.9.1"
        #    puts "#{ME}: you have #{RUBY_VERSION}"
        #    abort
        #end

        # Check to see if we're running in Windows.
        # XXX - change this to an option later.
        if RUBY_PLATFORM =~ /win32/i
            puts "#{ME}: requires the fork() system call"
            puts "#{ME}: cannot run on windows"
            abort
        end

        # Check to see if we're running as root.
        if Process.euid == 0
            puts "#{ME}: refuses to run as root"
            abort
        end

        # Do command-line options.
        opts = OptionParser.new

        dd = 'Enable debug logging.'
        dq = 'Disable regular logging.'

        opts.on('-d', '--debug', dd) { @@debug   = true  }
        opts.on('-q', '--quiet', dq) { @@logging = false }

        begin
            opts.parse(*ARGV)
        rescue OptionParser::ParseError => err
            puts err, opts
            abort
        end

        # XXX - elaborate
        Signal.trap(:INT) { rhu_exit }

        # Set up the logging object.
        # XXX - change output to actual files based on fork, etc.
        Rhuidean.logger = Logger.new($stderr)

        puts "#{ME}: version #{CODENAME}-#{VERSION} [#{RUBY_PLATFORM}]"

        # XXX - configuration file, eventually.
        servers = { 'irc.malkier.net' => 6667}#,
                    #'66.225.223.45' => 6667 }

        # Get a new IRC::Client for each server.
        servers.each do |server, port|
            Rhuidean.debug("processing #{server}:#{port}")

            @@clients << IRC::Client.new do |c|
                c.server   = server
                c.port     = port
                #c.password = 'boobs'
                c.nickname = "rhuidean#{rand(999).to_s}"
                c.username = 'rakaur'
                c.realname = "a facet of someone else's imagination"
                #c.bind_to  = ''

                c.connect
            end
        end

        Thread.abort_on_exception = true if @debug

        @@clients.each { |c| Thread.new { c.io_loop } }

        Thread.list.each { |t| t.join unless t == Thread.main }


        # Exiting...
        rhu_exit

        self
    end

    #######
    private
    #######

    #
    # Called when we're exiting, cleans up stuff.
    # ---
    # returns:: returns to the OS
    #
    def rhu_exit
        Rhuidean.log('exiting...')
        @@logger.close

        exit
    end

    ######
    public
    ######

    #
    # Logs a regular message.
    # ---
    # message:: the string to log
    # returns:: +self+
    #
    def Rhuidean.log(message)
        @@logger.info(caller[0].split('/')[-1]) { message } if @@logging
    end

    #
    # Logs a debug message.
    # ---
    # message:: the string to log
    # returns:: +self+
    #
    def Rhuidean.debug(message)
        @@logger.debug(caller[0].split('/')[-1]) { message } if @@debug
    end

    #
    # Sets the logging object to use.
    # If it quacks like a Logger object, it should work.
    # ---
    # logger:: the Logger to use
    # returns:: +self+
    #
    def Rhuidean.logger=(logger)
        @@logger = logger

        @@logger.progname        = 'rhuidean'
        @@logger.datetime_format = '%b %d %H:%M:%S '

        # We only have 'logging' and 'debugging', so just set the
        # object to show all levels. I might change this someday.
        @@logger.level = Logger::DEBUG
    end

    #
    # Reader for the list of clients.
    # ---
    # returns:: Array of IRC::Client objects.
    #
    def Rhuidean.clients
        @@clients
    end
end
