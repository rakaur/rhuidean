#
# rhuidean: a small, lightweight IRC client library
# lib/rhuidean/event.rb: IRC events
#
# Copyright (c) 2003-2011 Eric Will <rakaur@malkier.net>
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
    end

    ######
    public
    ######

    #
    # Post a new event to the queue to be handled.
    # Events can be posted more than once per loop,
    # so the callers need to make sure calling the
    # same handlers twice for the same run isn't going
    # to bork something serious like make an otherwise
    # good call become blocking (like read).
    # ---
    # event:: event name as a Symbol
    # args:: list of arguments to pass to handler
    # returns:: +self+
    #
    def post(event, *args)
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
        needs_exit = false

        while e = @queue.shift
            next unless @handlers[e.event]

            # If there's an :exit event in the queue wait until we're
            # all the way done before we handle it.
            if e.event == :exit
                needs_exit = e
                next
            end

            @handlers[e.event].each { |block| block.call(*e.args) }
        end

        # Now we can exit... any events that got added by handling routines
        # just don't happen. This is arguably a bug.
        @handlers[:exit].each { |b| b.call(*needs_exit.args) } if needs_exit

        self
    end
end

end # module IRC

