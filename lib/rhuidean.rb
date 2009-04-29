#
# rhuidean: malkier irc services
# lib/rhuidean.rb: contains the Rhuidean class
#
# Copyright (c) 2004-2009 Eric Will <rakaur@malkier.net>
# Copyright (c) 2003-2004 shrike development team
#

# Import required Ruby modules.
%w(logger).each { |m| require m }

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

    #
    # Create a new Rhuidean object, which starts and runs the entire
    # application. Everything starts and ends here.
    # ---
    # returns:: +self+
    #
    def initialize
        # Check to see if we're running on ruby19.
        if RUBY_VERSION < '1.9.1'
            puts "#{ME}: requires at least ruby 1.9.1"
            puts "#{ME}: you have #{RUBY_VERSION}"
            abort
        end

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

        # Turn on debug logging.
        # XXX - change this to an option later
        Rhuidean.logger = Logger.new($stderr)

        puts "#{ME}: version #{CODENAME}-#{VERSION} [#{RUBY_PLATFORM}]"

        # XXX - do stuff.

        # Exiting...

        Rhuidean.log('exiting...')
        @@logger.close if @@logger

        self
    end

    ######
    public
    ######

    #
    # Logs a message using <tt>@@logger</tt>.
    # ---
    # returns:: +self+
    #
    def Rhuidean.log(message)
        @@logger.debug(caller[0].split('/')[-1]) { message }
    end

    #
    # Writer for <tt>@@logger</tt>.
    # ---
    # returns:: +self+
    #
    def Rhuidean.logger=(logger)
        @@logger = logger

        @@logger.progname        = 'rhuidean'
        @@logger.datetime_format = '%b %d %H:%M:%S '
        @@logger.level           = Logger::DEBUG
    end
end
