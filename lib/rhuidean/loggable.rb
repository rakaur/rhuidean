#
# rhuidean: a small, lightweight IRC client library
# lib/rhuidean/loggable.rb: a mixin for easy logging
#
# Copyright (c) 2003-2010 Eric Will <rakaur@malkier.net>
#
# encoding: utf-8

module Loggable
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
        logger.level = @logger.level if @logger

        @logger = logger

        # Set to false/nil to disable logging...
        return unless @logger

        @logger.datetime_format = '%m/%d %H:%M:%S '
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

