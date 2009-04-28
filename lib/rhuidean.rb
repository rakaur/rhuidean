#
# rhuidean: malkier irc services
# lib/rhuidean.rb: contains the +Rhuidean+ class
#
# Copyright (c) 2004-2009 Eric Will <rakaur@malkier.net>
# Copyright (c) 2003-2004 shrike development team
#

# The main application class.
class Rhuidean
    VERSION  = '1.0-alpha'
    CODENAME = 'praxis'

    #
    # Create a new +Rhuidean+ object, which starts and runs the entire
    # application. Everything starts and ends here.
    #
    # return:: self
    #
    def initialize
        # Check to see if we're running on ruby19.
        if RUBY_VERSION < '1.9.1'
            puts 'rhuidean: requires at least ruby 1.9.1'
            puts "rhuidean: you have #{RUBY_VERSION}"
            abort
        end

        # Check to see if we're running in Windows.
        if RUBY_PLATFORM =~ /win32/i
            puts 'rhuidean: requires the fork() system call'
            puts 'rhuidean: cannot run on windows'
            abort
        end

        # Check to see if we're running as root.
        if Process.euid == 0
            puts 'rhuidean: refuses to run as root'
            abort
        end

        puts "rhuidean: version #{CODENAME}-#{VERSION} [#{RUBY_PLATFORM}]"

        self
    end
end
