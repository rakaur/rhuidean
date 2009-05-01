#
# rhuidean: malkier irc services
# lib/irc.rb: IRC library
#
# Copyright (c) 2004-2009 Eric Will <rakaur@malkier.net>
# Copyright (c) 2003-2004 shrike development team
#

# Import required IRC modules.
%w(irc/client irc/event irc/methods irc/numeric).each { |m| require m }
