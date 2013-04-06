#!/usr/bin/env ruby

# adapted from http://paste.ly/5wrj

SERVER = 'imap.gmail.com'
USERNAME = 'dtstutz@gmail.com'
PW = `cat gmail-password`.chomp
FOLDER = ARGV[0] or raise "Specify name of folder as first arg (e.g. INBOX)"

require 'net/imap'
require 'rubygems'
require 'tmail'
require 'time'
require 'date'
require 'certified'

# Extend support for idle command. See online.
# http://www.ruby-forum.com/topic/50828
# but that was wrong. see /opt/ruby-1.9.1-p243/lib/net/imap.rb.
class Net::IMAP
  def idle
    cmd = "IDLE"
    synchronize do
      @idle_tag = generate_tag
      put_string(@idle_tag + " " + cmd)
      put_string(CRLF)
    end
  end

  def say_done
    cmd = "DONE"
    synchronize do
      put_string(cmd)
      put_string(CRLF)
    end
  end

  def await_done_confirmation
    synchronize do
      get_tagged_response(@idle_tag, nil)
    end
  end
end

#Net::IMAP.debug = true
@imap = Net::IMAP.new(SERVER, :ssl => true)

@imap.login USERNAME, PW

non_done_handler = Proc.new { |resp|
  if resp.kind_of?(Net::IMAP::UntaggedResponse) && resp.name == 'EXISTS'
    puts "Okay, #{resp.data} messages to start with."
    $num_messages = resp.data
  end
}

# Add handler (before select, so we can catch EXISTS)
@imap.add_response_handler(non_done_handler)
begin
  @imap.select FOLDER
rescue Net::IMAP::NoResponseError => e
  p e
  exit 0
end
@imap.remove_response_handler(non_done_handler)

done_handler = Proc.new { |resp|
  if resp.kind_of?(Net::IMAP::UntaggedResponse) && resp.name == 'EXISTS'
    #puts "Mailbox now has #{resp.data} messages"
    @imap.say_done
    if resp.data == $num_messages
      #puts "(no new messages...)"
      $num_messages == resp.data
      Thread.new do
        @imap.await_done_confirmation
        @imap.idle
      end
    else
      puts "(received some messages...)"
      Thread.new do
        @imap.await_done_confirmation
        @imap.disconnect
        exit 2
      end
    end
  end
}
@imap.add_response_handler(done_handler)

@imap.idle # called by EXISTS handler
sleep 29 * 60 # sleep only 29 minutes according to IMAP spec
exit 0
