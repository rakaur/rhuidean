#
# rhuidean: a small, lightweight IRC client library
# lib/rhuidean/stateful_user.rb: state-keeping IRC user
#
# Copyright (c) 2003-2010 Eric Will <rakaur@malkier.net>
#
 
# Import required app modules
%w(stateful_client stateful_channel).each { |m| require 'rhuidean/' + m }

module IRC

class StatefulUser
    attr_reader :nickname

    def initialize(nickname)
        # The user's nickname
        @nickname = nickname
    end

    ######
    public
    ######

    def to_s
        @nickname
    end
end

end # module IRC

