#
# rhuidean: malkier irc services
# lib/rhuidean.rb: contains the Rhuidean class
#
# Copyright (c) 2004-2009 Eric Will <rakaur@malkier.net>
# Copyright (c) 2003-2004 shrike development team
#

# Import required Ruby modules.
%w(logger optparse pp).each { |m| require m }

# Import required IRC modules.
require 'irc'

# The main application class.
class Rhuidean
    ##
    # constants

    # The project name.
    ME       = 'rhuidean'

    # The full version number.
    VERSION  = '0.1.1'

    # The codename for this major version.
    CODENAME = 'praxis'

    #
    # Creates a new Rhuidean object, which starts and runs the entire
    # application. Everything starts and ends here.
    # ---
    # returns:: +self+
    #
    def initialize
        puts "#{ME}: version #{CODENAME}-#{VERSION} [#{RUBY_PLATFORM}]"

        # Check to see if we're running on a decent version of ruby.
        if RUBY_VERSION < '1.8.6'
            puts "#{ME}: requires at least ruby 1.8.6"
            puts "#{ME}: you have #{RUBY_VERSION}"
            abort
        elsif RUBY_VERSION < '1.9.1'
            puts "#{ME}: supports ruby 1.9 (much faster)"
            puts "#{ME}: you have #{RUBY_VERSION}"
        end

        # Check to see if we're running in Windows.
        if RUBY_PLATFORM =~ /win32/i
            puts "#{ME}: requires the fork() system call to daemonize"
            puts "#{ME}: not available on windows"
        end

        # Check to see if we're running as root.
        if Process.euid == 0
            puts "#{ME}: refuses to run as root"
            abort
        end

        # The list of all our clients.
        @clients = []

        # Some defaults for state.
        logging  = true
        debug    = false
        willfork = RUBY_PLATFORM =~ /win32/i ? false : true
        wd       = Dir.getwd

        # Do command-line options.
        opts = OptionParser.new

        dd = 'Enable debug logging.'
        hd = 'Display usage information.'
        nd = 'Do not fork into the background.'
        qd = 'Disable regular logging.'
        vd = 'Display version information.'

        opts.on('-d', '--debug',   dd) { debug    = true  }
        opts.on('-h', '--help',    hd) { puts opts; abort }
        opts.on('-n', '--no-fork', nd) { willfork = false }
        opts.on('-q', '--quiet',   qd) { logging  = false }
        opts.on('-v', '--version', vd) { abort            }

        begin
            opts.parse(*ARGV)
        rescue OptionParser::ParseError => err
            puts err, opts
            abort
        end

        # Signal handlers.
        trap(:INT)   { rhu_exit }
        trap(:PIPE)  { :SIG_IGN }
        trap(:CHLD)  { :SIG_IGN }
        trap(:WINCH) { :SIG_IGN }
        trap(:TTIN)  { :SIG_IGN }
        trap(:TTOU)  { :SIG_IGN }
        trap(:TSTP)  { :SIG_IGN }

        # Should probably do config stuff here - XXX

        if debug
            puts "#{ME}: warning: debug mode enabled"
            puts "#{ME}: warning: everything will be logged in the clear!"
        end

        # Check to see if we're already running.
        if File.exists?('var/rhuidean.pid')
            curpid = nil

            File.open('var/rhuidean.pid', 'r') do |f|
                curpid = f.read.chomp.to_i
            end

            begin
                Process.kill(0, curpid)
            rescue Errno::ESRCH
                File.delete('var/rhuidean.pid')
            else
                puts "#{ME}: daemon is already running"
                abort
            end
        end

        # Fork into the background
        if willfork
            begin
                pid = fork
            rescue Exception => e
                puts "#{ME}: cannot fork into the background"
                abort
            end

            # This is the child process.
            unless pid
                Dir.chdir(wd)
                File.umask(0)
            else # This is the parent process.
                # Write the PID file.
                Dir.mkdir('var') unless File.exists?('var')
                File.open('var/rhuidean.pid', 'w') { |f| f.puts(pid) }

                puts "#{ME}: pid #{pid}"
                puts "#{ME}: running in background mode from #{Dir.getwd}"
                abort
            end

            $stdin.close
            $stdout.close
            $stderr.close
        else
            puts "#{ME}: pid #{Process.pid}"
            puts "#{ME}: running in foreground mode from #{Dir.getwd}"
        end

        # XXX - configuration file, eventually.
        servers = { 'irc.malkier.net' => 6667 }#,
                    #'66.225.223.45' => 6667 }

        # Get a new IRC::Client for each server.
        servers.each do |server, port|
            @clients << IRC::Client.new do |c|
                c.server   = server
                c.port     = port
                #c.password = 'boobs'
                c.nickname = 'rhuidean'
                c.username = 'rakaur'
                c.realname = "a facet of someone else's imagination"
                #c.bind_to  = ''

                # XXX - change output to actual files based on fork, etc.
                c.logger  = false unless logging
                c.debug   = debug

                c.on(IRC::Numeric::RPL_ENDOFMOTD) { c.join('#malkier') }

                c.on(:PRIVMSG) do |m|
                    next unless m.origin == 'rakaur!rakaur@malkier.net'

                    next unless m.params[0][0].chr == '.'

                    case m.params[0][1..-1]
                    when 'chans'
                        c.privmsg(m.target, c.channels.inspect)
                    when 'die'
                        c.quit("parting is such sweet sorrow")
                        c.exit("rakaur told me to :(")
                    when 'join'
                        c.join(m.params[1])
                    when 'part'
                        c.part(m.params[1])
                    when 'raw'
                        c.raw(m.params[1..-1].join(' '))
                    else
                        c.privmsg(m.target, 'what?')
                    end
                end
            end
        end

        Thread.abort_on_exception = true if @debug

        @clients.each { |c| Thread.new { c.io_loop } }

        Thread.list.each { |t| t.join unless t == Thread.main }

        # Exiting...
        rhu_exit

        self
    end

    #######
    private
    #######

    #
    # Called when we're exiting, cleans up stuff.
    # ---
    # returns:: returns to the OS
    #
    def rhu_exit
        exit
    end
end
