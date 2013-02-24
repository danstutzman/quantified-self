#!/usr/bin/env ruby
require 'pp'

SERVER = 'imap.gmail.com'
USERNAME = 'dtstutz@gmail.com'
PW = `cat gmail-password`.chomp

require 'net/imap'
require 'rubygems'
require 'tmail'
require 'time'
require 'date'

#Net::IMAP.debug = true
@imap = Net::IMAP.new(SERVER, :ssl => true)

@imap.login USERNAME, PW

@imap.select 'INBOX'

message_ids = @imap.search(["NOT", "DELETED"])
for message in @imap.fetch(message_ids, "ENVELOPE")
  raise "Too many/little froms" if message.attr["ENVELOPE"].from.size != 1
  from = message.attr["ENVELOPE"].from[0]
  if from.name
    first_name, last_name = from.name.split(" ")
    puts first_name
  else
    puts from.host
    #puts "#{from.mailbox}@#{from.host}"
  end
end
