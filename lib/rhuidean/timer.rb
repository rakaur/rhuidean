#
# rhuidean: a small, lightweight IRC client library
# lib/rhuidean/timer.rb: timed code execution
#
# Copyright (c) 2003-2010 Eric Will <rakaur@malkier.net>
#

module IRC

# Allows for code to be executed on a timed basis.
class Timer
    ##
    # class attributes
    @@timers = []

    ##
    # instance attributes
    attr_reader :time, :timeout, :repeat

    #
    # Creates a new timer to be executed within +10 seconds of +time+.
    # ---
    # time:: time in seconds
    # repeat:: +true+ or +false+, keep executing +block+ every +time+?
    # block:: execute the given block
    # returns:: +self+
    #
    def initialize(time, repeat = false, &block)
        @time    = time.to_i
        @timeout = Time.now.to_f + @time
        @repeat  = repeat
        @block   = block

        @@timers << self

        @thread = Thread.new { start }

        self
    end

    ######
    public
    ######

    #
    # A wrapper for initialize. Sets up the block to repeat.
    # --
    # time:: repeat how often, in seconds?
    # returns:: +self+
    #
    def Timer.every(time, &block)
        new(time, true, &block)
    end

    #
    # A wrapper for initialize. Sets up so the block doesn't repeat.
    # ---
    # time:: execute block after how long, in seconds?
    # returns:: self
    #
    def Timer.after(time, &block)
        new(time, false, &block)
    end

    #
    # Returns the Unix timestamp of the next time a timer should run
    # ---
    # returns:: minimum timer interval, see above
    #
    def Timer.next_time
        return 0 if @@timers.empty?
        @@timers.collect { |t| t.timeout }.min
    end

    #
    # Stops all timers.
    # ---
    # returns:: nothing
    #
    def Timer.stop
        @@timers.each { |t| t.stop }
    end

    #
    # Kills the thread we're in.
    # ---
    # returns:: nothing
    #
    def stop
        @@timers.delete(self)
        @thread.exit
    end

    #######
    private
    #######

    #
    # Starts the loop, always in a thread.
    # ---
    # returns:: nothing
    #
    def start
        loop do
            sleep(@time)
            @block.call
            @timeout = Time.now.to_f + @time if @repeat
            break unless @repeat
        end

        @@timers.delete(self)
    end
end

end # module IRC

