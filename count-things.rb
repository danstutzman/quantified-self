#!/usr/bin/ruby
require 'net/imap'

def safe(&block)
  begin
    block.call
  rescue Exception => e
    nil
  end
end

out = {}

out['count-of-files-on-desktop'] = safe {
  `ls ~/Desktop | wc -l`.to_i
}

imap = Net::IMAP.new('imap.gmail.com', 993, true, nil, false)
imap.login('dtstutz@gmail.com', File.read('gmail-password').strip)

out['count-of-gmail-inbox-messages'] = safe {
  count = imap.status('INBOX', ['MESSAGES'])["MESSAGES"]
}

out['count-of-gmail-sent-messages-today'] = safe {
  imap.select('[Gmail]/Sent Mail')
  today = Time.now.strftime('%d-%b-%Y')
  tomorrow = (Time.now + 60 * 60 * 24).strftime('%d-%b-%Y')
  count = imap.search(["BEFORE", tomorrow, "SINCE", today]).size
}

today = Time.now.strftime('%Y-%m-%d')
path = File.expand_path('../data/count-things.log', __FILE__)
File.open(path, 'a') { |file|
  out.each { |field, value|
    file.write "#{today},#{field},#{value}\n"
  }
}
