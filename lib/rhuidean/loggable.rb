#
# rhuidean: a small, lightweight IRC client library
# lib/rhuidean/loggable.rb: a mixin for easy logging
#
# Copyright (c) 2003-2010 Eric Will <rakaur@malkier.net>
#
# encoding: utf-8

module Loggable

    #
    # I use this to override the log formatting.
    # There's no documented way to do this; I had to figure it out.
    # That means this could break, and it's not "right."
    #
    class Formatter
        FORMAT = "%s, [%s] %s: %s\n"
        PN_RE  = /\:in \`.+\'/

        ######
        public
        ######

        #
        # Called by Logger to format the message.
        # ---
        # severity:: String
        # time:: Time
        # progname:: String
        # msg:: strictly anything, for us String
        #
        def call(severity, time, progname, msg)
            datetime = time.strftime('%m/%d %H:%M:%S')

            # Include filename, line number, and method name in debug
            if severity == "DEBUG"
                progname.gsub!(PN_RE, '')
                progname.gsub!('block in ', '')
                "[%s] %s: %s\n" % [datetime, progname, msg]
            else
                "[%s] %s\n" % [datetime, msg]
            end
        end
    end

    ##
    # Logs a regular message.
    # ---
    # message:: the string to log
    # returns:: +self+
    #
    def log(level, message)
        return unless level.to_s =~ /(fatal|error|warning|info|debug)/

        @logger.send(level, caller[0].split('/')[-1]) { message } if @logger
    end

    ##
    # Sets the logging object to use.
    # If it quacks like a Logger object, it should work.
    # ---
    # logger:: the Logger to use
    # returns:: +self+
    #
    def logger=(logger)
        logger.level = @logger.level if @logger and logger

        @logger = logger

        # Set to false/nil to disable logging...
        return unless @logger

        @logger.formatter = Formatter.new
    end

    def log_level=(level)
        case level
        when :none
            @logger = nil
        when :fatal
            @logger.level = Logger::FATAL
        when :error
            @logger.level = Logger::ERROR
        when :warning
            @logger.level = Logger::WARN
        when :info
            @logger.level = Logger::INFO
        when :debug
            @logger.level = Logger::DEBUG
        else
            @logger.level = Logger::WARN
        end
    end
end # module Loggable

