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

@imap.select 'INBOX'

message_ids = @imap.search(["NOT", "DELETED"])

messages = []
if message_ids.size > 0
  FLAGS = "FLAGS"
  INTERNALDATE = "INTERNALDATE"
  UID = "UID"
  FROM_PEEK = "BODY.PEEK[HEADER.FIELDS (From)]"
  FROM = "BODY[HEADER.FIELDS (From)]"
  for imap_message in @imap.fetch(message_ids, [FLAGS, FROM_PEEK, INTERNALDATE, UID])
    timestamp = imap_message.attr[INTERNALDATE]
    timestamp = DateTime.strptime(timestamp, '%d-%b-%Y %H:%M:%S %z').to_time.getlocal
    email_uid = imap_message.attr[UID]

    sender = imap_message.attr[FROM]
    if match = sender.match(/^From: (.*?)[\r\n]*$/)
      sender = match[1]
    end
    was_seen = imap_message.attr[FLAGS].include?(:Seen)

    message = {
      "sender"      => sender,
      "was_seen"    => was_seen,
      "email_uid"   => email_uid,
      "received_at" => timestamp.strftime('%Y-%m-%dT%H:%M:%S'),
    }
    messages.push message
  end
end

#curl -d '[{"from":"here","count":3, "seen":false}]' http://localhost:9292/button-pressed
request = Net::HTTP::Post.new("/unanswered_messages/update_emails",
  {'Content-Type' =>'application/json'})
request.body = messages.to_json
puts request.body
Net::HTTP.new("localhost", 4444).request(request)
