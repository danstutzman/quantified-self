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

seen_froms = []
unseen_froms = []
FLAGS = "FLAGS"
FROM_PEEK = "BODY.PEEK[HEADER.FIELDS (From)]"
FROM = "BODY[HEADER.FIELDS (From)]"
for message in @imap.fetch(message_ids, [FLAGS, FROM_PEEK])
  from = message.attr[FROM]
  match = from.match(/^From: \"?([^<]*?)\"? <([^@]*?)@([^>]*)?>/)
  from = [match[1], match[2], match[3]]

  if message.attr[FLAGS].include?(:Seen)
    seen_froms.push from
  else
    unseen_froms.push from
  end
end

simplify = lambda do |from|
  full_name, before_domain, domain = from
  if full_name == 'Thomas Frey'
    'Tom'
  elsif full_name
    full_name.split(" ")[0] # first name
  else
    domain
  end
end
seen_froms.map!(&simplify)
unseen_froms.map!(&simplify)

unseen_from_to_count = Hash.new(0)
unseen_froms.each do |from|
  unseen_from_to_count[from] += 1
end
#pp unseen_from_to_count

seen_from_to_count = Hash.new(0)
seen_froms.each do |from|
  seen_from_to_count[from] += 1
end
#pp seen_from_to_count

emails = []
unseen_from_to_count.each do |from, count|
  email = { :from => from, :count => count, :seen => false }
  emails.push email
end
seen_from_to_count.each do |from, count|
  email = { :from => from, :count => count, :seen => true }
  emails.push email
end

#curl -d '[{"from":"here","count":3, "seen":false}]' http://localhost:9292/button-pressed
request = Net::HTTP::Post.new("/emails-updated",
  {'Content-Type' =>'application/json'})
request.body = emails.to_json
Net::HTTP.new("localhost", 4567).request(request)
