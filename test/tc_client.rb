#
# rhuidean: a small, lightweight IRC client library
# test/tc_client.rb: unit testing
#
# Copyright (c) 2003-2010 Eric Will <rakaur@malkier.net>
#

warn <<-end
    WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!

    You have 15 seconds to cancel (CTRL+C).

    These tests connect to irc.malkier.net:6667 and join #malkier for a brief
    period of time (a few seconds), and posts the client version and platform.
    If you do not want your machine to do this, do not run these tests!

    You have 15 seconds to cancel (CTRL+C).

    WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!
end

$stdout.sync = true
print "."*16
15.downto(0) do
    print "\b \b"
    sleep(1)
end
puts
$stdout.sync = false

class TestClient < Test::Unit::TestCase
    def test_001_connect
        c = nil

        assert_nothing_raised do
            c = IRC::Client.new do |c|
                c.server   = 'irc.malkier.net'
                c.port     = 6667

                c.nickname = "rhuidean#{rand(9999)}"
                c.username = 'rhuidean'
                c.realname = 'rhuidean unit tester'

                c.logger   = nil
            end
        end

        assert_equal(6667,              c.port)
        assert_equal('irc.malkier.net', c.server)
        assert_match(/^rhuidean\d+$/,   c.nickname)
        assert_equal('rhuidean',        c.username)

        worked  = false
        str     = "rhuidean-#{Rhuidean::VERSION} [#{RUBY_PLATFORM}]"

        assert_nothing_raised do
            c.on(IRC::Numeric::RPL_ENDOFMOTD) do
                c.join('#malkier')
                c.privmsg('#malkier', str)
                worked = true
            end
        end

        c.thread = Thread.new { c.io_loop }

        sleep(1) until worked

        assert(worked)
    end
end

