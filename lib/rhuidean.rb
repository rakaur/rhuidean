#
# rhuidean: a small, lightweight IRC client library
# lib/rhuidean.rb: IRC client library
#
# Copyright (c) 2003-2010 Eric Will <rakaur@malkier.net>
#

# Import required rhuidean modules.
%w(client event methods numeric timer).each do |m|
    require 'rhuidean/' + m
end

