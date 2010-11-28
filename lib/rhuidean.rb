#
# rhuidean: a small, lightweight IRC client library
# lib/rhuidean.rb: IRC client library
#
# Copyright (c) 2003-2010 Eric Will <rakaur@malkier.net>
#

module Rhuidean
    # Version number
    V_MAJOR  = 1
    V_MINOR  = 1
    V_PATCH  = 2

    VERSION  = "#{V_MAJOR}.#{V_MINOR}.#{V_PATCH}"
end

# Import required app modules
%w(client event methods numeric timer).each do |m|
    require 'rhuidean/' + m
end

