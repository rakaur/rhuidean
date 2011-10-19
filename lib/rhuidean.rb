#
# rhuidean: a small, powerful IRC client library
# lib/rhuidean.rb: pre-startup routines
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.md
#

# The main library class / namespace
class Rhuidean
  # For backwards-incompatible changes
  V_MAJOR = 1

  # For backwards-compatable changes
  V_MINOR = 9

  # For minor changes and hotfixes
  V_PATCH = 0

  # A String representation of the version number
  VERSION = "#{V_MAJOR}.#{V_MINOR}.#{V_PATCH}"
end
