#
# rhuidean: malkier irc services
# lib/irc/event.rb: IRC events
#
# Copyright (c) 2004-2009 Eric Will <rakaur@malkier.net>
# Copyright (c) 2003-2004 shrike development team
#

module IRC

# Contains information about a posted event.
class Event
    attr_reader :event, :args

    #
    # Creates a new Event.
    # ---
    # event:: event name as a Symbol
    # args:: list of arguments to pass to handler
    # returns:: +self+
    #
    def initialize(event, *args)
        @event = event
        @args  = args
    end
end

# A queue of events, with handlers. One per object.
class EventQueue
    attr_reader :queue, :handlers

    #
    # Create a new EventQueue.
    # ---
    # returns:: +self+
    #
    def initialize
        @queue    = []
        @handlers = {}

        Rhuidean.debug('new EventQueue')
    end

    ######
    public
    ######

    #
    # Post a new event to the queue to be handled.
    # ---
    # event:: event name as a Symbol
    # args:: list of arguments to pass to handler
    # returns:: +self+
    #
    def post(event, *args)
        # Only one post per event per loop, otherwise we end up trying
        # to read from a socket that has no data, or stuff like that.
        return if m = @queue.find { |q| q.event == event }

        #Rhuidean.debug("new :#{event} event posted")

        @queue << Event.new(event, *args)

        self
    end

    #
    # Register a handler for an event.
    # ---
    # event:: event name as a Symbol
    # block:: block to call to handle event
    # returns:: +self+
    #
    def handle(event, &block)
        Rhuidean.debug("new handler for :#{event}")
        (@handlers[event] ||= []) << block

        self
    end

    #
    # Does the event queue have anything in it?
    # ---
    # returns:: +true+ or +false+
    #
    def needs_ran?
        @queue.empty? ? false : true
    end

    #
    # Goes through the event queue and runs the handlers.
    # ---
    # returns:: +self+
    #
    def run
        while e = @queue.shift
            next unless @handlers[e.event]

            if e.event == :exit and not @queue.empty?
                @queue << e
                return
            end

            #Rhuidean.debug("executing handlers for :#{e.event}")

            @handlers[e.event].each { |block| block.call(*e.args) }
        end

        self
    end
end

end # module IRC
