#!/usr/bin/env ruby

SERVER = 'imap.gmail.com'
USERNAME = 'dtstutz@gmail.com'
PW = `cat gmail-password`.chomp

require 'net/imap'
require 'rubygems'
require 'tmail'
require 'time'
require 'date'
require 'pp'
require 'net/http'
require 'json'

#Net::IMAP.debug = true
@imap = Net::IMAP.new(SERVER, :ssl => true)

@imap.login USERNAME, PW

@imap.select 'Records/Facebook'

message_ids = @imap.search(["UNSEEN", "NOT", "DELETED"])

messages = []
SUBJECT = "BODY[HEADER.FIELDS (Subject)]"
INTERNALDATE = "INTERNALDATE"
if message_ids.size > 0
  for message in @imap.fetch(message_ids, [SUBJECT, INTERNALDATE])
    subject = message.attr[SUBJECT]
    timestamp = message.attr[INTERNALDATE]
    if match = subject.match(/^Subject: New message(s)? from (.*?)[\r\n]*$/)
      messages.push({ "from" => match[2], "timestamp" => timestamp })
    end
  end
  
  request = Net::HTTP::Post.new("/facebook-messages-updated",
    {'Content-Type' => 'application/json'})
  request.body = messages.to_json
  Net::HTTP.new("localhost", 4567).request(request)
  p messages
else
  puts "No unseen messages in Records/Facebook."
end
