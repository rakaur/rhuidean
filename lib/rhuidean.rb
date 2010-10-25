#
# rhuidean: a small, lightweight IRC client library
# lib/rhuidean.rb: IRC client library
#
# Copyright (c) 2003-2010 Eric Will <rakaur@malkier.net>
#

module Rhuidean
    # Version number
    V_MAJOR  = 0
    V_MINOR  = 3
    V_PATCH  = 0

    VERSION  = "#{V_MAJOR}.#{V_MINOR}.#{V_PATCH}"
end

# Import required rhuidean modules.
%w(client event methods numeric timer).each do |m|
    require 'rhuidean/' + m
end

